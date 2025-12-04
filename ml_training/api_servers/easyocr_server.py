#!/usr/bin/env python3
"""
EasyOCR REST API Server
Nutrition Label OCR service with error correction

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
from PIL import Image
import io

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


def load_easyocr_reader(gpu: bool = True, languages: List[str] = None):
    """Load EasyOCR reader with error handling"""
    global reader
    
    if reader is not None:
        return reader
    
    try:
        import easyocr
        
        if languages is None:
            languages = ['ko', 'en']  # Korean and English
        
        logger.info(f"Loading EasyOCR with languages: {languages}, GPU: {gpu}")
        reader = easyocr.Reader(languages, gpu=gpu)
        logger.info("EasyOCR reader loaded successfully")
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
    Apply OCR error correction patterns
    Based on common misrecognitions in nutrition labels
    """
    corrections = {
        # Common Korean OCR errors
        '브랜스': '트랜스',
        '탄백질': '단백질',
        '포확지방': '포화지방',
        '볼포확지방': '불포화지방',
        '나트륨': '나트륨',  # Ensure consistency
        '당류': '당류',
        '탄수화봉': '탄수화물',
        '칼로리': '칼로리',
        
        # Number corrections
        'O': '0',  # Letter O to zero
        'l': '1',  # Letter l to one (in numbers)
        
        # Unit corrections
        'g': 'g',
        'mg': 'mg',
        'kcal': 'kcal',
    }
    
    corrected = text
    for wrong, right in corrections.items():
        corrected = corrected.replace(wrong, right)
    
    return corrected


def extract_nutrition_values(ocr_results: List[Tuple]) -> Dict[str, Optional[float]]:
    """
    Extract nutrition values from OCR results
    
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
    }
    
    # Combine all text
    full_text = ' '.join([apply_ocr_corrections(text) for _, text, _ in ocr_results])
    
    # Patterns for extraction
    patterns = {
        'calories': r'(?:열량|칼로리)[:\s]*(\d+(?:\.\d+)?)\s*(?:kcal|킬로칼로리)?',
        'carbohydrates': r'(?:탄수화물)[:\s]*(\d+(?:\.\d+)?)\s*(?:g|그램)?',
        'protein': r'(?:단백질)[:\s]*(\d+(?:\.\d+)?)\s*(?:g|그램)?',
        'fat': r'(?:지방)[:\s]*(\d+(?:\.\d+)?)\s*(?:g|그램)?',
        'saturated_fat': r'(?:포화지방)[:\s]*(\d+(?:\.\d+)?)\s*(?:g|그램)?',
        'trans_fat': r'(?:트랜스지방)[:\s]*(\d+(?:\.\d+)?)\s*(?:g|그램)?',
        'sodium': r'(?:나트륨)[:\s]*(\d+(?:\.\d+)?)\s*(?:mg|밀리그램)?',
        'sugar': r'(?:당류)[:\s]*(\d+(?:\.\d+)?)\s*(?:g|그램)?',
    }
    
    for key, pattern in patterns.items():
        match = re.search(pattern, full_text, re.IGNORECASE)
        if match:
            try:
                nutrition[key] = float(match.group(1))
            except ValueError:
                logger.warning(f"Could not convert {key} value: {match.group(1)}")
    
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
    OCR endpoint for nutrition label recognition
    
    Request:
        - image: Image file (multipart/form-data)
        - extract_nutrition: Boolean (optional, default=True)
    
    Response:
        - success: Boolean
        - ocr_results: List of detected text with bounding boxes
        - nutrition: Extracted nutrition values (if extract_nutrition=True)
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
        
        # Read image
        image_bytes = file.read()
        image = Image.open(io.BytesIO(image_bytes))
        
        # Convert to numpy array
        image_np = np.array(image)
        
        # Perform OCR
        logger.info(f"Processing image: {file.filename}")
        results = reader.readtext(image_np)
        
        # Format results
        ocr_results = []
        for bbox, text, confidence in results:
            ocr_results.append({
                'bbox': bbox,
                'text': text,
                'confidence': float(confidence)
            })
        
        # Extract nutrition values if requested
        extract_nutrition = request.form.get('extract_nutrition', 'true').lower() == 'true'
        nutrition = None
        
        if extract_nutrition:
            nutrition = extract_nutrition_values(results)
        
        return jsonify({
            'success': True,
            'ocr_results': ocr_results,
            'nutrition': nutrition,
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
    Simplified endpoint that only returns nutrition values
    
    Request:
        - image: Image file
    
    Response:
        - success: Boolean
        - nutrition: Extracted nutrition values
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
        
        # Read and process image
        image_bytes = file.read()
        image = Image.open(io.BytesIO(image_bytes))
        image_np = np.array(image)
        
        # Perform OCR
        logger.info(f"Extracting nutrition from: {file.filename}")
        results = reader.readtext(image_np)
        
        # Extract nutrition values
        nutrition = extract_nutrition_values(results)
        
        return jsonify({
            'success': True,
            'nutrition': nutrition
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
    """Main function"""
    parser = argparse.ArgumentParser(description='EasyOCR REST API Server')
    parser.add_argument('--host', type=str, default='0.0.0.0',
                        help='Host to bind to (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=5000,
                        help='Port to bind to (default: 5000)')
    parser.add_argument('--gpu', action='store_true', default=True,
                        help='Use GPU if available (default: True)')
    parser.add_argument('--debug', action='store_true',
                        help='Run in debug mode')
    
    args = parser.parse_args()
    
    # Load EasyOCR reader at startup
    try:
        load_easyocr_reader(gpu=args.gpu)
    except Exception as e:
        logger.error(f"Failed to load EasyOCR: {e}")
        logger.warning("Server will start but OCR will not work until reader is loaded")
    
    # Run server
    logger.info(f"Starting EasyOCR server on {args.host}:{args.port}")
    app.run(host=args.host, port=args.port, debug=args.debug)


if __name__ == '__main__':
    main()
