"""
EasyOCR Training/Fine-tuning Script for Nutrition Label Recognition

This script provides utilities for training EasyOCR to recognize Korean nutrition
labels (성분표) from food product packaging.

Training Strategy:
==================
The fine-tuning process uses a multi-stage approach:

1. Stage 1: Korean Character Recognition (1,000 samples)
   - Generated using TextRecognitionDataGenerator
   - Teaches the model to recognize Korean characters (Hangul)

2. Stage 2: Product Label OCR (50,000 samples)
   - AI Hub '의약품, 화장품 패키징 OCR 데이터'
   - Similar text patterns to nutrition labels

3. Stage 3: Nutrition Label Fine-tuning (800 samples)
   - Custom captured and labeled nutrition label data
   - Specific terms: '탄수화물', '포화지방', '단백질', etc.

Training Configuration:
- Train/Validation split: 80:20
- Epochs: 3155

Post-processing:
Due to OCR errors (e.g., '트랜스 지방' → '브랜스 지방', '단백질' → '탄백질'),
regex patterns are used to correct common misrecognitions.

Usage:
    # Generate Korean training data
    python easyocr_trainer.py --generate-korean-data 1000
    
    # Prepare training data from annotations
    python easyocr_trainer.py --prepare-data path/to/images path/to/labels
    
    # Run inference with post-processing
    python easyocr_trainer.py --infer path/to/nutrition_label.jpg

Requirements:
    - easyocr >= 1.7.0
    - TextRecognitionDataGenerator
    - torch >= 2.0.0
    - See requirements.txt for full list
"""

import argparse
import json
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

try:
    import easyocr
except ImportError:
    easyocr = None
    print("Warning: easyocr not installed. Install with: pip install easyocr")

try:
    import cv2
    import numpy as np
    from PIL import Image
except ImportError:
    cv2 = None
    np = None
    Image = None
    print("Warning: OpenCV/NumPy/Pillow not installed.")


@dataclass
class NutritionInfo:
    """Data class for extracted nutrition information."""
    calories: Optional[float] = None
    carbohydrates: Optional[float] = None
    protein: Optional[float] = None
    fat: Optional[float] = None
    sodium: Optional[float] = None
    sugar: Optional[float] = None
    serving_size: Optional[str] = None
    raw_text: str = ""
    confidence: float = 0.0


class EasyOCRNutritionExtractor:
    """
    A class for extracting nutrition information from food labels using EasyOCR.
    
    This class wraps EasyOCR functionality and provides nutrition-specific
    text extraction and parsing capabilities for Korean and English labels.
    """
    
    def __init__(
        self,
        languages: list = None,
        gpu: bool = True,
        model_storage_directory: str = None,
        user_network_directory: str = None
    ):
        """
        Initialize the EasyOCR extractor.
        
        Args:
            languages: List of language codes (default: ['ko', 'en'])
            gpu: Use GPU for inference if available
            model_storage_directory: Directory to store EasyOCR models
            user_network_directory: Directory for custom trained models
        """
        if easyocr is None:
            raise ImportError("easyocr not installed. Run: pip install easyocr")
        
        self.languages = languages or ['ko', 'en']
        self.gpu = gpu
        self.model_storage_directory = model_storage_directory
        self.user_network_directory = user_network_directory
        self.reader: Optional[easyocr.Reader] = None
        
        # OCR Error Correction Patterns
        # These patterns fix common misrecognitions found during testing
        # e.g., '트랜스 지방' → '브랜스 지방', '단백질' → '탄백질'
        self.ocr_corrections = {
            # Common Korean OCR errors in nutrition labels
            '브랜스': '트랜스',
            '탄백질': '단백질',
            '탄수하물': '탄수화물',
            '탄수회물': '탄수화물',
            '포화지밤': '포화지방',
            '포화지망': '포화지방',
            '나트류': '나트륨',
            '나트룸': '나트륨',
            '당규': '당류',
            '당뉴': '당류',
            '열랑': '열량',
            '열링': '열량',
            '콜레스테률': '콜레스테롤',
            '콜래스테롤': '콜레스테롤',
            '식이섭유': '식이섬유',  # Common confusion
            '칼숨': '칼슘',
            '철붐': '철분',
            '비타밍': '비타민',
            '비타맨': '비타민',
        }
        
        # Regex patterns for nutrition extraction (Korean and English)
        self.patterns = {
            'calories': [
                r'열량[:\s]*(\d+(?:\.\d+)?)\s*(?:kcal|칼로리)?',
                r'칼로리[:\s]*(\d+(?:\.\d+)?)',
                r'calories?[:\s]*(\d+(?:\.\d+)?)\s*(?:kcal)?',
                r'energy[:\s]*(\d+(?:\.\d+)?)\s*(?:kcal)?',
                r'(\d+(?:\.\d+)?)\s*kcal',
            ],
            'carbohydrates': [
                r'탄수화물[:\s]*(\d+(?:\.\d+)?)\s*g?',
                r'carbohydrate[s]?[:\s]*(\d+(?:\.\d+)?)\s*g?',
                r'total\s*carb[s]?[:\s]*(\d+(?:\.\d+)?)\s*g?',
            ],
            'protein': [
                r'단백질[:\s]*(\d+(?:\.\d+)?)\s*g?',
                r'protein[:\s]*(\d+(?:\.\d+)?)\s*g?',
            ],
            'fat': [
                r'지방[:\s]*(\d+(?:\.\d+)?)\s*g?',
                r'(?:total\s*)?fat[:\s]*(\d+(?:\.\d+)?)\s*g?',
            ],
            'sodium': [
                r'나트륨[:\s]*(\d+(?:\.\d+)?)\s*(?:mg)?',
                r'sodium[:\s]*(\d+(?:\.\d+)?)\s*(?:mg)?',
            ],
            'sugar': [
                r'당류[:\s]*(\d+(?:\.\d+)?)\s*g?',
                r'sugar[s]?[:\s]*(\d+(?:\.\d+)?)\s*g?',
            ],
            'serving_size': [
                r'1회\s*제공량[:\s]*([0-9]+(?:\.[0-9]+)?\s*(?:g|ml|개|조각|컵)?)',
                r'serving\s*size[:\s]*([0-9]+(?:\.[0-9]+)?\s*(?:g|ml|piece|cup)?)',
            ]
        }
    
    def load_reader(self):
        """Load the EasyOCR reader with specified configuration."""
        print(f"Loading EasyOCR reader for languages: {self.languages}")
        
        kwargs = {
            'lang_list': self.languages,
            'gpu': self.gpu
        }
        
        if self.model_storage_directory:
            kwargs['model_storage_directory'] = self.model_storage_directory
        if self.user_network_directory:
            kwargs['user_network_directory'] = self.user_network_directory
            kwargs['recog_network'] = 'custom'  # Use custom model if provided
        
        self.reader = easyocr.Reader(**kwargs)
        print("EasyOCR reader loaded successfully")
        return self.reader
    
    def extract_text(
        self,
        image_path: str,
        detail: int = 1,
        paragraph: bool = False
    ) -> list:
        """
        Extract text from an image.
        
        Args:
            image_path: Path to the image file
            detail: 0 for simple output, 1 for detailed output with bounding boxes
            paragraph: Merge text into paragraphs
            
        Returns:
            List of extracted text with bounding boxes and confidence scores
        """
        if self.reader is None:
            self.load_reader()
        
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"Image not found: {image_path}")
        
        results = self.reader.readtext(
            image_path,
            detail=detail,
            paragraph=paragraph
        )
        
        return results
    
    def correct_ocr_errors(self, text: str) -> str:
        """
        Apply post-processing to correct common OCR misrecognitions.
        
        This method addresses errors found during testing where the model
        misreads certain Korean characters in nutrition labels.
        
        Args:
            text: Raw OCR text output
            
        Returns:
            Corrected text with common errors fixed
        """
        corrected = text
        for wrong, correct in self.ocr_corrections.items():
            corrected = corrected.replace(wrong, correct)
        return corrected
    
    def parse_nutrition(self, ocr_results: list) -> NutritionInfo:
        """
        Parse OCR results to extract nutrition information.
        
        Applies OCR error correction before extracting nutrition values.
        
        Args:
            ocr_results: List of OCR results from extract_text()
            
        Returns:
            NutritionInfo dataclass with extracted values
        """
        # Combine all text
        if not ocr_results:
            return NutritionInfo()
        
        # Handle both detailed and simple output formats
        if isinstance(ocr_results[0], tuple) and len(ocr_results[0]) >= 2:
            # Detailed format: [(bbox, text, confidence), ...]
            full_text = " ".join([r[1] for r in ocr_results])
            avg_confidence = sum([r[2] for r in ocr_results]) / len(ocr_results)
        else:
            # Simple format: [text, ...]
            full_text = " ".join(ocr_results)
            avg_confidence = 0.0
        
        # Apply OCR error correction
        full_text = self.correct_ocr_errors(full_text)
        full_text_lower = full_text.lower()
        
        nutrition = NutritionInfo(
            raw_text=full_text,
            confidence=avg_confidence
        )
        
        # Extract each nutrition value
        for field, patterns in self.patterns.items():
            for pattern in patterns:
                match = re.search(pattern, full_text_lower, re.IGNORECASE)
                if match:
                    value = match.group(1)
                    if field == 'serving_size':
                        setattr(nutrition, field, value)
                    else:
                        try:
                            setattr(nutrition, field, float(value))
                        except ValueError:
                            pass
                    break
        
        return nutrition
    
    def process_image(self, image_path: str) -> NutritionInfo:
        """
        Process a single image and extract nutrition information.
        
        Args:
            image_path: Path to the nutrition label image
            
        Returns:
            NutritionInfo with extracted data
        """
        ocr_results = self.extract_text(image_path, detail=1)
        nutrition = self.parse_nutrition(ocr_results)
        return nutrition


class EasyOCRDataPreparer:
    """
    Utility class for preparing training data for EasyOCR fine-tuning.
    
    Training Data Sources:
    1. TextRecognitionDataGenerator: 1,000 Korean text samples
    2. AI Hub pharmaceutical/cosmetic OCR: 50,000 labeled samples
    3. Custom nutrition label data: 800 hand-labeled samples
    
    The training process uses 80:20 train/val split with 3155 epochs.
    """
    
    # Nutrition-specific vocabulary for data generation
    NUTRITION_VOCABULARY = [
        # Basic nutrition terms
        '열량', '칼로리', 'kcal', '탄수화물', '당류', '식이섬유',
        '단백질', '지방', '포화지방', '트랜스지방', '불포화지방',
        '콜레스테롤', '나트륨', '칼슘', '철분', '칼륨',
        # Vitamins
        '비타민A', '비타민B', '비타민C', '비타민D', '비타민E',
        # Units
        'g', 'mg', 'μg', 'ml', '%',
        # Common phrases
        '1회 제공량', '총 내용량', '영양성분', '영양정보',
        '1일 영양성분 기준치', '% 영양성분 기준치',
        # Numbers (common in nutrition labels)
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '10', '15', '20', '25', '30', '50', '100', '150', '200', '250',
        '300', '400', '500', '1000',
    ]
    
    def __init__(self, output_dir: str = "./easyocr_training_data"):
        """
        Initialize the data preparer.
        
        Args:
            output_dir: Directory to store prepared training data
        """
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def generate_korean_training_data(
        self,
        num_samples: int = 1000,
        output_subdir: str = "korean_generated"
    ):
        """
        Generate Korean text training data using TextRecognitionDataGenerator.
        
        This implements Stage 1 of the training pipeline:
        - 1,000 Korean text samples for basic character recognition
        
        Args:
            num_samples: Number of samples to generate (default: 1000)
            output_subdir: Subdirectory for generated data
            
        Note: Requires trdg package: pip install trdg
        """
        try:
            from trdg.generators import GeneratorFromStrings
        except ImportError:
            print("TextRecognitionDataGenerator not installed.")
            print("Install with: pip install trdg")
            print("\nCreating placeholder structure instead...")
            self._create_generation_placeholder(output_subdir, num_samples)
            return
        
        output_path = self.output_dir / output_subdir
        output_path.mkdir(exist_ok=True)
        
        # Generate nutrition-specific Korean text samples
        generator = GeneratorFromStrings(
            strings=self.NUTRITION_VOCABULARY * (num_samples // len(self.NUTRITION_VOCABULARY) + 1),
            language='ko',
            size=32,  # Font size
            skewing_angle=5,
            random_skew=True,
            blur=1,
            random_blur=True,
            background_type=0,  # Gaussian noise
        )
        
        labels = []
        for i, (img, text) in enumerate(generator):
            if i >= num_samples:
                break
            
            img_filename = f"korean_{i:05d}.jpg"
            img.save(str(output_path / img_filename))
            labels.append(f"{img_filename}\t{text}")
        
        # Save labels
        with open(output_path / "labels.txt", 'w', encoding='utf-8') as f:
            f.write('\n'.join(labels))
        
        print(f"Generated {len(labels)} Korean text samples")
        print(f"Output: {output_path}")
    
    def _create_generation_placeholder(self, output_subdir: str, num_samples: int):
        """Create placeholder structure when trdg is not available."""
        output_path = self.output_dir / output_subdir
        output_path.mkdir(exist_ok=True)
        
        readme = f"""
# Korean Text Generation Data

To generate Korean training data, install TextRecognitionDataGenerator:
```bash
pip install trdg
```

Then run:
```bash
python easyocr_trainer.py --generate-korean-data {num_samples}
```

This will generate {num_samples} Korean text images for training.

Alternatively, manually add your Korean text images here with labels.txt file.
"""
        with open(output_path / "README.md", 'w', encoding='utf-8') as f:
            f.write(readme)
        
        print(f"Created placeholder at: {output_path}")
    
    def prepare_from_annotations(
        self,
        images_dir: str,
        annotations_file: str,
        split_ratio: float = 0.8  # Changed to 80:20 as per actual training
    ):
        """
        Prepare training data from annotated images.
        
        Expected annotation format (JSON):
        {
            "image_name.jpg": [
                {"bbox": [x1, y1, x2, y2], "text": "칼로리 250kcal"},
                ...
            ],
            ...
        }
        
        Args:
            images_dir: Directory containing source images
            annotations_file: JSON file with text annotations
            split_ratio: Train/val split ratio (default: 0.8 = 80% train, 20% val)
        """
        images_dir = Path(images_dir)
        
        # Load annotations
        with open(annotations_file, 'r', encoding='utf-8') as f:
            annotations = json.load(f)
        
        # Create output directories
        train_dir = self.output_dir / "train"
        val_dir = self.output_dir / "val"
        train_dir.mkdir(exist_ok=True)
        val_dir.mkdir(exist_ok=True)
        
        train_labels = []
        val_labels = []
        
        all_items = list(annotations.items())
        split_idx = int(len(all_items) * split_ratio)
        
        for idx, (image_name, regions) in enumerate(all_items):
            image_path = images_dir / image_name
            
            if not image_path.exists():
                print(f"Warning: Image not found: {image_path}")
                continue
            
            # Determine split
            is_train = idx < split_idx
            current_dir = train_dir if is_train else val_dir
            current_labels = train_labels if is_train else val_labels
            
            # Load image
            if cv2 is not None:
                img = cv2.imread(str(image_path))
                if img is None:
                    print(f"Warning: Could not read image: {image_path}")
                    continue
                
                # Crop each text region
                for region_idx, region in enumerate(regions):
                    bbox = region['bbox']
                    text = region['text']
                    
                    # Crop region
                    x1, y1, x2, y2 = map(int, bbox)
                    cropped = img[y1:y2, x1:x2]
                    
                    if cropped.size == 0:
                        continue
                    
                    # Save cropped image
                    crop_name = f"{Path(image_name).stem}_{region_idx}.jpg"
                    crop_path = current_dir / crop_name
                    cv2.imwrite(str(crop_path), cropped)
                    
                    # Add to labels
                    current_labels.append(f"{crop_name}\t{text}")
        
        # Save label files
        with open(train_dir / "labels.txt", 'w', encoding='utf-8') as f:
            f.write('\n'.join(train_labels))
        
        with open(val_dir / "labels.txt", 'w', encoding='utf-8') as f:
            f.write('\n'.join(val_labels))
        
        print(f"Data preparation complete!")
        print(f"Training samples: {len(train_labels)}")
        print(f"Validation samples: {len(val_labels)}")
        print(f"Output directory: {self.output_dir}")
    
    def create_sample_structure(self):
        """Create a sample directory structure with placeholder files."""
        # Create directories
        train_dir = self.output_dir / "train"
        val_dir = self.output_dir / "val"
        train_dir.mkdir(exist_ok=True)
        val_dir.mkdir(exist_ok=True)
        
        # Create sample label files
        sample_labels = [
            "# Format: filename<TAB>text",
            "# Each line is one training sample",
            "sample_001.jpg\t열량 250kcal",
            "sample_002.jpg\t탄수화물 30g",
            "sample_003.jpg\t단백질 15g",
        ]
        
        with open(train_dir / "labels.txt", 'w', encoding='utf-8') as f:
            f.write('\n'.join(sample_labels))
        
        with open(val_dir / "labels.txt", 'w', encoding='utf-8') as f:
            f.write('\n'.join(sample_labels[:3]))
        
        # Create README
        readme_content = """
# EasyOCR Training Data

## Directory Structure
```
easyocr_training_data/
├── train/
│   ├── labels.txt      # Training labels (filename<TAB>text)
│   ├── image_001.jpg   # Cropped text images
│   └── ...
└── val/
    ├── labels.txt      # Validation labels
    └── ...
```

## Label Format
Each line in labels.txt:
```
image_filename.jpg<TAB>ground_truth_text
```

## Fine-tuning EasyOCR

To fine-tune EasyOCR, you'll need to:

1. Install the trainer:
```bash
pip install easyocr-trainer  # If available
# Or clone the EasyOCR repo and use their training scripts
```

2. Prepare character set:
Create a file listing all characters in your dataset.

3. Configure training:
Modify the configuration files for your language and dataset.

4. Run training:
```bash
python train.py --config config.yaml
```

For detailed instructions, refer to:
- EasyOCR GitHub: https://github.com/JaidedAI/EasyOCR
- Training documentation: https://github.com/JaidedAI/EasyOCR/blob/master/trainer/README.md
"""
        
        with open(self.output_dir / "README.md", 'w', encoding='utf-8') as f:
            f.write(readme_content)
        
        print(f"Sample structure created at: {self.output_dir}")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="EasyOCR Training and Inference for Nutrition Labels"
    )
    
    # Action arguments
    parser.add_argument(
        "--infer",
        type=str,
        help="Path to image for inference"
    )
    parser.add_argument(
        "--prepare-data",
        nargs=2,
        metavar=("IMAGES_DIR", "ANNOTATIONS"),
        help="Prepare training data from images and annotations"
    )
    parser.add_argument(
        "--create-sample",
        action="store_true",
        help="Create sample directory structure"
    )
    
    # Configuration arguments
    parser.add_argument(
        "--languages",
        nargs="+",
        default=["ko", "en"],
        help="Languages to use (default: ko en)"
    )
    parser.add_argument(
        "--no-gpu",
        action="store_true",
        help="Disable GPU (uses CPU only). By default, GPU is used if available."
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default="./easyocr_training_data",
        help="Output directory for prepared data"
    )
    
    args = parser.parse_args()
    
    # Create sample structure
    if args.create_sample:
        preparer = EasyOCRDataPreparer(args.output_dir)
        preparer.create_sample_structure()
        return
    
    # Prepare training data
    if args.prepare_data:
        images_dir, annotations = args.prepare_data
        preparer = EasyOCRDataPreparer(args.output_dir)
        preparer.prepare_from_annotations(images_dir, annotations)
        return
    
    # Run inference
    if args.infer:
        use_gpu = not args.no_gpu
        extractor = EasyOCRNutritionExtractor(
            languages=args.languages,
            gpu=use_gpu
        )
        
        print(f"\nProcessing: {args.infer}")
        nutrition = extractor.process_image(args.infer)
        
        print("\n" + "="*50)
        print("Extracted Nutrition Information")
        print("="*50)
        print(f"Calories:      {nutrition.calories or 'N/A'} kcal")
        print(f"Carbohydrates: {nutrition.carbohydrates or 'N/A'} g")
        print(f"Protein:       {nutrition.protein or 'N/A'} g")
        print(f"Fat:           {nutrition.fat or 'N/A'} g")
        print(f"Sodium:        {nutrition.sodium or 'N/A'} mg")
        print(f"Sugar:         {nutrition.sugar or 'N/A'} g")
        print(f"Serving Size:  {nutrition.serving_size or 'N/A'}")
        print(f"Confidence:    {nutrition.confidence:.2%}")
        print("="*50)
        print(f"\nRaw Text:\n{nutrition.raw_text}")
        return
    
    # No action specified
    parser.print_help()


if __name__ == "__main__":
    main()
