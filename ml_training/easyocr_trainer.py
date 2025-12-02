"""
EasyOCR Training/Fine-tuning Script for Nutrition Label Recognition

This script provides utilities for preparing data and fine-tuning EasyOCR
for recognizing nutrition labels in Korean and English.

EasyOCR fine-tuning involves training a custom recognition model on your
specific dataset. This is useful for improving accuracy on nutrition labels.

Note: EasyOCR fine-tuning requires the separate easyocr-trainer package
and follows a specific data format. This script provides:
1. Data preparation utilities
2. Basic inference wrapper
3. Guidelines for fine-tuning setup

Usage:
    # For data preparation:
    python easyocr_trainer.py --prepare-data path/to/images path/to/labels
    
    # For inference (using pretrained model):
    python easyocr_trainer.py --infer path/to/image.jpg

Requirements:
    - easyocr >= 1.7.0
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
    
    def parse_nutrition(self, ocr_results: list) -> NutritionInfo:
        """
        Parse OCR results to extract nutrition information.
        
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
    
    EasyOCR training requires data in a specific format:
    - Images cropped to individual text lines
    - Ground truth text labels
    - Proper directory structure
    
    This class helps convert existing annotations to the required format.
    """
    
    def __init__(self, output_dir: str = "./easyocr_training_data"):
        """
        Initialize the data preparer.
        
        Args:
            output_dir: Directory to store prepared training data
        """
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def prepare_from_annotations(
        self,
        images_dir: str,
        annotations_file: str,
        split_ratio: float = 0.9
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
            split_ratio: Train/val split ratio (default: 0.9 = 90% train)
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
        "--gpu",
        action="store_true",
        default=True,
        help="Use GPU for inference"
    )
    parser.add_argument(
        "--no-gpu",
        action="store_true",
        help="Disable GPU"
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
        use_gpu = args.gpu and not args.no_gpu
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
