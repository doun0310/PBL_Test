#!/usr/bin/env python3
"""
EasyOCR REST API Server
Advanced Korean OCR service for nutrition labels with preprocessing and error correction

Features:
- Enhanced image preprocessing for better Korean text recognition
- Advanced OCR error correction with Korean-specific patterns
- Multiple OCR attempts with different parameters
- Confidence-based result filtering
- Comprehensive nutrition value extraction

Usage:
    python easyocr_server.py --port 5000 --host 0.0.0.0
"""

import os
import sys
import re
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import logging

from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.utils import secure_filename
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter
import io
import cv2

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Configuration
UPLOAD_FOLDER = '/tmp/ocr_uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp'}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

# Create upload folder
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Global EasyOCR reader
reader = None


def allowed_file(filename: str) -> bool:
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def preprocess_image_for_korean_ocr(image: np.ndarray) -> List[np.ndarray]:
    """
    Advanced image preprocessing specifically optimized for Korean text recognition
    Returns multiple preprocessed versions for better OCR accuracy
    
    Args:
        image: Input image as numpy array
    
    Returns:
        List of preprocessed images to try OCR on
    """
    preprocessed_images = []
    
    # Convert to grayscale if needed
    if len(image.shape) == 3:
        gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
    else:
        gray = image.copy()
    
    # Original grayscale
    preprocessed_images.append(gray)
    
    # 1. Adaptive threshold (good for varying lighting)
    adaptive = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
        cv2.THRESH_BINARY, 11, 2
    )
    preprocessed_images.append(adaptive)
    
    # 2. Otsu's thresholding (good for consistent lighting)
    _, otsu = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    preprocessed_images.append(otsu)
    
    # 3. Contrast enhancement + denoising
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    enhanced = clahe.apply(gray)
    denoised = cv2.fastNlMeansDenoising(enhanced, h=10)
    preprocessed_images.append(denoised)
    
    # 4. Sharpen for better edge detection of Korean characters
    kernel_sharpen = np.array([[-1,-1,-1], 
                                [-1, 9,-1], 
                                [-1,-1,-1]])
    sharpened = cv2.filter2D(gray, -1, kernel_sharpen)
    preprocessed_images.append(sharpened)
    
    # 5. Morphological operations to enhance text
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
    morph = cv2.morphologyEx(gray, cv2.MORPH_CLOSE, kernel)
    preprocessed_images.append(morph)
    
    return preprocessed_images


def load_easyocr_reader(gpu: bool = True, languages: List[str] = None):
    """
    Load EasyOCR reader optimized for Korean text with error handling
    
    Args:
        gpu: Use GPU if available
        languages: List of language codes (default: ['ko', 'en'])
    
    Returns:
        EasyOCR Reader instance
    """
    global reader
    
    if reader is not None:
        return reader
    
    try:
        import easyocr
        
        if languages is None:
            # Prioritize Korean, then English
            languages = ['ko', 'en']
        
        logger.info(f"Loading EasyOCR with languages: {languages}, GPU: {gpu}")
        
        # Load reader with optimized parameters for Korean
        reader = easyocr.Reader(
            languages, 
            gpu=gpu,
            model_storage_directory=None,  # Use default
            download_enabled=True,
            detector=True,
            recognizer=True,
            verbose=False
        )
        
        logger.info("EasyOCR reader loaded successfully with Korean optimization")
        return reader
        
    except ImportError:
        logger.error("EasyOCR not installed. Install with: pip install easyocr")
        raise RuntimeError("EasyOCR not installed")
    except Exception as e:
        logger.error(f"Error loading EasyOCR: {e}")
        if gpu:
            logger.warning("GPU failed, trying CPU...")
            return load_easyocr_reader(gpu=False, languages=languages)
        raise


def apply_ocr_corrections(text: str) -> str:
    """
    Apply comprehensive OCR error correction patterns
    Optimized for Korean nutrition labels with common misrecognitions
    
    Args:
        text: Raw OCR text output
    
    Returns:
        Corrected text
    """
    corrections = {
        # Common Korean OCR errors - nutrition terms
        '브랜스': '트랜스',
        '트렌스': '트랜스',
        '탄백질': '단백질',
        '단백절': '단백질',
        '담백질': '단백질',
        '포확지방': '포화지방',
        '보화지방': '포화지방',
        '볼포확지방': '불포화지방',
        '불포확지방': '불포화지방',
        '나트륨': '나트륨',
        '나트듬': '나트륨',
        '당류': '당류',
        '당뉴': '당류',
        '탄수화봉': '탄수화물',
        '탄수확물': '탄수화물',
        '탄소화물': '탄수화물',
        '칼로리': '칼로리',
        '컬로리': '칼로리',
        '열냥': '열량',
        '옐량': '열량',
        '지봉': '지방',
        '지방산': '지방산',
        
        # Unit corrections
        'g':'g',
        'G':'g',
        'ㅎ':'g',  # Common OCR error
        'mg':'mg',
        'MG':'mg',
        'mG':'mg',
        'kcal':'kcal',
        'Kcal':'kcal',
        'KCAL':'kcal',
        '킬로칼로리':'kcal',
        '그램':'g',
        '밀리그램':'mg',
        
        # Number corrections - common OCR confusions
        'O':'0',  # Letter O to zero
        'o':'0',
        'l':'1',  # Letter l to one
        'I':'1',  # Capital I to one
        'Z':'2',  # Sometimes Z is confused with 2
        'S':'5',  # In numbers context
        'B':'8',  # In numbers context
        
        # Korean number words to digits (if present)
        '영':'0',
        '일':'1',
        '이':'2',
        '삼':'3',
        '사':'4',
        '오':'5',
        '육':'6',
        '칠':'7',
        '팔':'8',
        '구':'9',
        
        # Common spacing/format errors
        ' g ':' g ',
        ' mg ':' mg ',
        ' kcal ':' kcal ',
        ':':':',  # Normalize colons
        '：':':',  # Full-width to half-width
    }
    
    corrected = text
    for wrong, right in corrections.items():
        corrected = corrected.replace(wrong, right)
    
    # Remove excessive spaces
    corrected = re.sub(r'\s+', ' ', corrected)
    
    return corrected.strip()


def perform_advanced_ocr(image_np: np.ndarray, min_confidence: float = 0.3) -> List[Tuple]:
    """
    Perform OCR with multiple preprocessing attempts and merge results
    
    Args:
        image_np: Input image as numpy array
        min_confidence: Minimum confidence threshold for results
    
    Returns:
        List of (bbox, text, confidence) tuples with best results
    """
    all_results = []
    
    # Get multiple preprocessed versions
    preprocessed_images = preprocess_image_for_korean_ocr(image_np)
    
    logger.info(f"Trying OCR with {len(preprocessed_images)} preprocessing methods")
    
    # Try OCR on each preprocessed image
    for idx, img in enumerate(preprocessed_images):
        try:
            # Perform OCR with optimized parameters for Korean
            results = reader.readtext(
                img,
                detail=1,  # Include bounding box
                paragraph=False,  # Don't group into paragraphs
                min_size=10,  # Minimum text size
                text_threshold=0.7,  # Text detection threshold
                low_text=0.4,  # Low confidence text threshold
                link_threshold=0.4,  # Link threshold
                canvas_size=2560,  # Maximum image dimension
                mag_ratio=1.5,  # Image magnification ratio
                slope_ths=0.1,  # Slope threshold
                ycenter_ths=0.5,  # Y-center threshold
                height_ths=0.5,  # Height threshold
                width_ths=0.5,  # Width threshold
                add_margin=0.1,  # Margin around detected text
                contrast_ths=0.1  # Contrast threshold
            )
            
            # Filter by confidence and add to results
            for bbox, text, confidence in results:
                if confidence >= min_confidence:
                    all_results.append((bbox, text, confidence, idx))
                    
        except Exception as e:
            logger.warning(f"OCR failed on preprocessing method {idx}: {e}")
            continue
    
    if not all_results:
        logger.warning("No OCR results found with any preprocessing method")
        return []
    
    # Merge and deduplicate results
    # Keep highest confidence result for similar text
    merged_results = {}
    for bbox, text, confidence, method_idx in all_results:
        # Normalize text for comparison
        normalized = apply_ocr_corrections(text).strip().lower()
        
        if normalized not in merged_results or confidence > merged_results[normalized][2]:
            merged_results[normalized] = (bbox, text, confidence)
    
    # Sort by confidence
    final_results = sorted(merged_results.values(), key=lambda x: x[2], reverse=True)
    
    logger.info(f"Found {len(final_results)} unique OCR results after merging")
    
    return final_results


def extract_nutrition_values(ocr_results: List[Tuple]) -> Dict[str, Optional[float]]:
    """
    Extract nutrition values from OCR results with enhanced Korean text handling
    
    Args:
        ocr_results: List of (bbox, text, confidence) tuples from EasyOCR
    
    Returns:
        Dictionary with nutrition information
    """
    nutrition = {
        'calories': None,
        'carbohydrates': None,
        'protein': None,
        'fat': None,
        'saturated_fat': None,
        'trans_fat': None,
        'sodium': None,
        'sugar': None,
        'cholesterol': None,
        'dietary_fiber': None,
    }
    
    # Combine all text with corrections
    full_text = ' '.join([apply_ocr_corrections(text) for _, text, _ in ocr_results])
    
    logger.info(f"Corrected OCR text: {full_text}")
    
    # Enhanced patterns for extraction with multiple variations
    patterns = {
        'calories': [
            r'(?:열량|칼로리)[:\s]*(\d+(?:\.\d+)?)\s*(?:kcal|킬로칼로리)?',
            r'(?:열량|칼로리).*?(\d+(?:\.\d+)?)',
            r'(\d+(?:\.\d+)?)\s*(?:kcal|킬로칼로리)',
        ],
        'carbohydrates': [
            r'(?:탄수화물)[:\s]*(\d+(?:\.\d+)?)\s*(?:g|그램)?',
            r'(?:탄수화물).*?(\d+(?:\.\d+)?)',
        ],
        'protein': [
            r'(?:단백질)[:\s]*(\d+(?:\.\d+)?)\s*(?:g|그램)?',
            r'(?:단백질).*?(\d+(?:\.\d+)?)',
        ],
        'fat': [
            r'(?:지방)(?!산)[:\s]*(\d+(?:\.\d+)?)\s*(?:g|그램)?',
            r'(?:지방)(?!산).*?(\d+(?:\.\d+)?)',
        ],
        'saturated_fat': [
            r'(?:포화지방|포화지방산)[:\s]*(\d+(?:\.\d+)?)\s*(?:g|그램)?',
            r'(?:포화).*?(\d+(?:\.\d+)?)',
        ],
        'trans_fat': [
            r'(?:트랜스지방|트랜스지방산)[:\s]*(\d+(?:\.\d+)?)\s*(?:g|그램)?',
            r'(?:트랜스).*?(\d+(?:\.\d+)?)',
        ],
        'sodium': [
            r'(?:나트륨)[:\s]*(\d+(?:\.\d+)?)\s*(?:mg|밀리그램)?',
            r'(?:나트륨).*?(\d+(?:\.\d+)?)',
        ],
        'sugar': [
            r'(?:당류|당분)[:\s]*(\d+(?:\.\d+)?)\s*(?:g|그램)?',
            r'(?:당류|당분).*?(\d+(?:\.\d+)?)',
        ],
        'cholesterol': [
            r'(?:콜레스테롤)[:\s]*(\d+(?:\.\d+)?)\s*(?:mg|밀리그램)?',
            r'(?:콜레스테롤).*?(\d+(?:\.\d+)?)',
        ],
        'dietary_fiber': [
            r'(?:식이섬유)[:\s]*(\d+(?:\.\d+)?)\s*(?:g|그램)?',
            r'(?:식이섬유).*?(\d+(?:\.\d+)?)',
        ],
    }
    
    for key, pattern_list in patterns.items():
        for pattern in pattern_list:
            match = re.search(pattern, full_text, re.IGNORECASE)
            if match:
                try:
                    value = float(match.group(1))
                    nutrition[key] = value
                    logger.info(f"Extracted {key}: {value}")
                    break  # Stop after first successful match
                except (ValueError, IndexError):
                    logger.warning(f"Could not convert {key} value: {match.group(1)}")
                    continue
    
    return nutrition


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'EasyOCR Nutrition Label API',
        'model_loaded': reader is not None
    })


@app.route('/ocr', methods=['POST'])
def ocr_endpoint():
    """
    Advanced OCR endpoint for nutrition label recognition with Korean optimization
    
    Request:
        - image: Image file (multipart/form-data)
        - extract_nutrition: Boolean (optional, default=True)
        - min_confidence: Float (optional, default=0.3) - Minimum confidence threshold
    
    Response:
        - success: Boolean
        - ocr_results: List of detected text with bounding boxes and confidence
        - nutrition: Extracted nutrition values (if extract_nutrition=True)
        - full_text: Complete OCR text (corrected)
        - error: Error message (if failed)
    """
    try:
        # Check if image file is present
        if 'image' not in request.files:
            return jsonify({
                'success': False,
                'error': 'No image file provided'
            }), 400
        
        file = request.files['image']
        
        if file.filename == '':
            return jsonify({
                'success': False,
                'error': 'Empty filename'
            }), 400
        
        if not allowed_file(file.filename):
            return jsonify({
                'success': False,
                'error': f'Invalid file type. Allowed: {ALLOWED_EXTENSIONS}'
            }), 400
        
        # Load EasyOCR reader if not loaded
        if reader is None:
            load_easyocr_reader()
        
        # Get optional parameters
        min_confidence = float(request.form.get('min_confidence', '0.3'))
        
        # Read image
        image_bytes = file.read()
        image = Image.open(io.BytesIO(image_bytes))
        
        # Convert to numpy array (RGB)
        if image.mode != 'RGB':
            image = image.convert('RGB')
        image_np = np.array(image)
        
        # Perform advanced OCR with preprocessing
        logger.info(f"Processing image: {file.filename} with advanced Korean OCR")
        results = perform_advanced_ocr(image_np, min_confidence=min_confidence)
        
        # Format results
        ocr_results = []
        full_text_parts = []
        for bbox, text, confidence in results:
            corrected_text = apply_ocr_corrections(text)
            ocr_results.append({
                'bbox': bbox,
                'text': corrected_text,
                'original_text': text,
                'confidence': float(confidence)
            })
            full_text_parts.append(corrected_text)
        
        full_text = ' '.join(full_text_parts)
        
        # Extract nutrition values if requested
        extract_nutrition = request.form.get('extract_nutrition', 'true').lower() == 'true'
        nutrition = None
        
        if extract_nutrition:
            nutrition = extract_nutrition_values(results)
        
        return jsonify({
            'success': True,
            'ocr_results': ocr_results,
            'nutrition': nutrition,
            'full_text': full_text,
            'num_results': len(ocr_results),
            'image_filename': secure_filename(file.filename)
        })
        
    except Exception as e:
        logger.error(f"Error processing OCR request: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.route('/extract_nutrition', methods=['POST'])
def extract_nutrition_endpoint():
    """
    Simplified endpoint optimized for nutrition value extraction with advanced Korean OCR
    
    Request:
        - image: Image file
        - min_confidence: Float (optional, default=0.3)
    
    Response:
        - success: Boolean
        - nutrition: Extracted nutrition values
        - full_text: Complete corrected OCR text
        - confidence_avg: Average confidence of OCR results
        - error: Error message (if failed)
    """
    try:
        if 'image' not in request.files:
            return jsonify({
                'success': False,
                'error': 'No image file provided'
            }), 400
        
        file = request.files['image']
        
        if not allowed_file(file.filename):
            return jsonify({
                'success': False,
                'error': f'Invalid file type. Allowed: {ALLOWED_EXTENSIONS}'
            }), 400
        
        # Load EasyOCR reader if not loaded
        if reader is None:
            load_easyocr_reader()
        
        # Get min confidence parameter
        min_confidence = float(request.form.get('min_confidence', '0.3'))
        
        # Read and process image
        image_bytes = file.read()
        image = Image.open(io.BytesIO(image_bytes))
        
        # Convert to RGB if needed
        if image.mode != 'RGB':
            image = image.convert('RGB')
        image_np = np.array(image)
        
        # Perform advanced OCR
        logger.info(f"Extracting nutrition from: {file.filename} with Korean optimization")
        results = perform_advanced_ocr(image_np, min_confidence=min_confidence)
        
        # Calculate average confidence
        avg_confidence = 0.0
        if results:
            avg_confidence = sum(conf for _, _, conf in results) / len(results)
        
        # Get corrected full text
        full_text = ' '.join([apply_ocr_corrections(text) for _, text, _ in results])
        
        # Extract nutrition values
        nutrition = extract_nutrition_values(results)
        
        return jsonify({
            'success': True,
            'nutrition': nutrition,
            'full_text': full_text,
            'confidence_avg': float(avg_confidence),
            'num_detections': len(results)
        })
        
    except Exception as e:
        logger.error(f"Error extracting nutrition: {e}", exc_info=True)
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@app.errorhandler(413)
def request_entity_too_large(error):
    """Handle file too large error"""
    return jsonify({
        'success': False,
        'error': f'File too large. Maximum size is {MAX_FILE_SIZE / 1024 / 1024}MB'
    }), 413


def main():
    """Main function to start the EasyOCR server"""
    parser = argparse.ArgumentParser(
        description='Advanced EasyOCR REST API Server optimized for Korean text'
    )
    parser.add_argument('--host', type=str, default='0.0.0.0',
                        help='Host to bind to (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=5000,
                        help='Port to bind to (default: 5000)')
    parser.add_argument('--gpu', action='store_true', default=True,
                        help='Use GPU if available (default: True)')
    parser.add_argument('--no-gpu', dest='gpu', action='store_false',
                        help='Force CPU usage')
    parser.add_argument('--debug', action='store_true',
                        help='Run in debug mode')
    
    args = parser.parse_args()
    
    # Load EasyOCR reader at startup
    try:
        logger.info("=" * 60)
        logger.info("Starting Advanced Korean OCR Server")
        logger.info("=" * 60)
        logger.info("Features:")
        logger.info("  - Multiple preprocessing methods for better recognition")
        logger.info("  - Advanced Korean-specific error correction")
        logger.info("  - Optimized OCR parameters for Korean text")
        logger.info("  - Confidence-based result filtering and merging")
        logger.info("=" * 60)
        
        load_easyocr_reader(gpu=args.gpu)
        
        logger.info("✓ EasyOCR reader loaded successfully")
        logger.info(f"✓ GPU enabled: {args.gpu}")
        
    except Exception as e:
        logger.error(f"✗ Failed to load EasyOCR: {e}")
        logger.warning("Server will start but OCR will not work until reader is loaded")
    
    # Run server
    logger.info("=" * 60)
    logger.info(f"Server starting on {args.host}:{args.port}")
    logger.info("Endpoints:")
    logger.info(f"  - GET  /health - Health check")
    logger.info(f"  - POST /ocr - Full OCR with bounding boxes")
    logger.info(f"  - POST /extract_nutrition - Extract nutrition values only")
    logger.info("=" * 60)
    
    app.run(host=args.host, port=args.port, debug=args.debug)


if __name__ == '__main__':
    main()
