"""
Dataset Download and Setup Helper Script

This script helps set up the directory structure for ML training datasets
and provides guidance on downloading required datasets.

Note: Most datasets require manual download due to:
- Kaggle API authentication
- AI Hub account registration (Korean ID required)

Usage:
    # Set up directory structure
    python download_datasets.py --setup-structure
    
    # Download Food-11 from Kaggle (requires kaggle.json credentials)
    python download_datasets.py --download-food11
    
    # Verify dataset structure
    python download_datasets.py --verify

Requirements:
    - kaggle (for Kaggle dataset download)
    - requests
    - tqdm
"""

import argparse
import os
import zipfile
from pathlib import Path

try:
    from tqdm import tqdm
except ImportError:
    tqdm = None


class DatasetSetup:
    """Helper class for setting up ML training datasets."""
    
    # Dataset information
    DATASETS = {
        'food11': {
            'name': 'Food-11 Image Dataset',
            'source': 'Kaggle',
            'url': 'https://www.kaggle.com/datasets/trolukovich/food11-image-dataset',
            'kaggle_dataset': 'trolukovich/food11-image-dataset',
            'size': '16,643 images',
            'purpose': 'Food vs non-food classification for YOLO'
        },
        'korean_food': {
            'name': 'AI Hub Korean Food Images',
            'source': 'AI Hub',
            'url': 'https://www.aihub.or.kr/aihubdata/data/view.do?currMenu=115&topMenu=100&aihubDataSe=data&dataSetSn=74',
            'size': '272,783 images (reduced from 3M)',
            'purpose': 'Korean food classification (154 classes)'
        },
        'aihub_ocr': {
            'name': 'AI Hub Pharmaceutical/Cosmetic OCR',
            'source': 'AI Hub',
            'url': 'https://www.aihub.or.kr/aihubdata/data/view.do?currMenu=115&topMenu=100&aihubDataSe=data&dataSetSn=88',
            'size': '50,000 labeled samples',
            'purpose': 'Product label OCR training'
        }
    }
    
    def __init__(self, base_dir: str = "./datasets"):
        """Initialize with base directory for datasets."""
        self.base_dir = Path(base_dir)
    
    def setup_directory_structure(self):
        """Create the required directory structure for all datasets."""
        print("Setting up dataset directory structure...")
        
        # YOLO datasets
        yolo_dirs = [
            self.base_dir / "food11" / "training",
            self.base_dir / "food11" / "validation",
            self.base_dir / "food11" / "evaluation",
            self.base_dir / "korean_food" / "images" / "train",
            self.base_dir / "korean_food" / "images" / "val",
            self.base_dir / "korean_food" / "labels" / "train",
            self.base_dir / "korean_food" / "labels" / "val",
        ]
        
        # EasyOCR datasets
        ocr_dirs = [
            self.base_dir / "easyocr" / "korean_generated",
            self.base_dir / "easyocr" / "aihub_ocr" / "train",
            self.base_dir / "easyocr" / "aihub_ocr" / "val",
            self.base_dir / "easyocr" / "nutrition_labels" / "train",
            self.base_dir / "easyocr" / "nutrition_labels" / "val",
        ]
        
        all_dirs = yolo_dirs + ocr_dirs
        
        for dir_path in all_dirs:
            dir_path.mkdir(parents=True, exist_ok=True)
            print(f"  Created: {dir_path}")
        
        # Create placeholder README files
        self._create_placeholder_readme(
            self.base_dir / "food11" / "README.md",
            "Food-11 Dataset",
            self.DATASETS['food11']
        )
        self._create_placeholder_readme(
            self.base_dir / "korean_food" / "README.md",
            "Korean Food Dataset",
            self.DATASETS['korean_food']
        )
        self._create_placeholder_readme(
            self.base_dir / "easyocr" / "README.md",
            "EasyOCR Training Data",
            self.DATASETS['aihub_ocr']
        )
        
        print("\nDirectory structure created successfully!")
        print("\nNext steps:")
        print("1. Download Food-11 from Kaggle: https://www.kaggle.com/datasets/trolukovich/food11-image-dataset")
        print("2. Register at AI Hub (Korean ID required): https://www.aihub.or.kr")
        print("3. Download Korean food dataset from AI Hub")
        print("4. Extract datasets to their respective directories")
    
    def _create_placeholder_readme(self, path: Path, title: str, info: dict):
        """Create a placeholder README for a dataset directory."""
        content = f"""# {title}

## Dataset Information
- **Name**: {info['name']}
- **Source**: {info['source']}
- **URL**: {info['url']}
- **Size**: {info['size']}
- **Purpose**: {info['purpose']}

## Download Instructions

1. Visit the URL above
2. Create an account if required
3. Download the dataset
4. Extract files to this directory

## Status
[ ] Not yet downloaded
"""
        path.write_text(content, encoding='utf-8')
    
    def download_food11_kaggle(self):
        """Download Food-11 dataset from Kaggle using Kaggle API."""
        try:
            import kaggle
        except ImportError:
            print("Error: kaggle package not installed.")
            print("Install with: pip install kaggle")
            print("\nAlternatively, download manually from:")
            print(self.DATASETS['food11']['url'])
            return False
        
        # Check for Kaggle credentials
        kaggle_json = Path.home() / ".kaggle" / "kaggle.json"
        if not kaggle_json.exists():
            print("Error: Kaggle credentials not found.")
            print("\nTo set up Kaggle API:")
            print("1. Go to https://www.kaggle.com/settings")
            print("2. Click 'Create New Token' under API section")
            print("3. Save kaggle.json to ~/.kaggle/kaggle.json")
            print("4. Run: chmod 600 ~/.kaggle/kaggle.json")
            return False
        
        output_dir = self.base_dir / "food11"
        output_dir.mkdir(parents=True, exist_ok=True)
        
        print(f"Downloading Food-11 dataset to {output_dir}...")
        
        try:
            kaggle.api.dataset_download_files(
                self.DATASETS['food11']['kaggle_dataset'],
                path=str(output_dir),
                unzip=True
            )
            print("Download complete!")
            return True
        except Exception as e:
            print(f"Error downloading dataset: {e}")
            return False
    
    def verify_datasets(self):
        """Verify that datasets are properly set up."""
        print("Verifying dataset structure...\n")
        
        results = {}
        
        # Check Food-11
        food11_path = self.base_dir / "food11"
        food11_images = list(food11_path.rglob("*.jpg")) + list(food11_path.rglob("*.png"))
        results['food11'] = {
            'exists': food11_path.exists(),
            'images': len(food11_images),
            'expected': 16643
        }
        
        # Check Korean Food
        korean_food_path = self.base_dir / "korean_food"
        korean_images = list(korean_food_path.rglob("*.jpg")) + list(korean_food_path.rglob("*.png"))
        korean_labels = list(korean_food_path.rglob("*.txt"))
        results['korean_food'] = {
            'exists': korean_food_path.exists(),
            'images': len(korean_images),
            'labels': len(korean_labels),
            'expected': 272783
        }
        
        # Check EasyOCR data
        easyocr_path = self.base_dir / "easyocr"
        ocr_images = list(easyocr_path.rglob("*.jpg")) + list(easyocr_path.rglob("*.png"))
        results['easyocr'] = {
            'exists': easyocr_path.exists(),
            'images': len(ocr_images),
            'expected': 51800
        }
        
        # Print results
        print("Dataset Verification Results:")
        print("=" * 60)
        
        for name, info in results.items():
            status = "✓" if info['images'] >= info.get('expected', 0) * 0.8 else "✗"
            print(f"\n{name}:")
            print(f"  Directory exists: {'Yes' if info['exists'] else 'No'}")
            print(f"  Images found: {info['images']:,}")
            print(f"  Expected: ~{info.get('expected', 'N/A'):,}")
            if 'labels' in info:
                print(f"  Labels found: {info['labels']:,}")
            print(f"  Status: {status}")
        
        return results
    
    def print_download_instructions(self):
        """Print detailed download instructions for all datasets."""
        print("\n" + "=" * 70)
        print("DATASET DOWNLOAD INSTRUCTIONS")
        print("=" * 70)
        
        for key, info in self.DATASETS.items():
            print(f"\n{'─' * 50}")
            print(f"📦 {info['name']}")
            print(f"{'─' * 50}")
            print(f"Source: {info['source']}")
            print(f"URL: {info['url']}")
            print(f"Size: {info['size']}")
            print(f"Purpose: {info['purpose']}")
            
            if info['source'] == 'Kaggle':
                print("\nDownload Options:")
                print("  Option 1 (Manual):")
                print("    1. Visit the URL above")
                print("    2. Click 'Download' button")
                print("    3. Extract to datasets/food11/")
                print("  Option 2 (Kaggle API):")
                print("    kaggle datasets download -d trolukovich/food11-image-dataset")
            elif info['source'] == 'AI Hub':
                print("\nDownload Instructions:")
                print("  1. Register at https://www.aihub.or.kr (Korean ID required)")
                print("  2. Navigate to the dataset page")
                print("  3. Request access (may require approval)")
                print("  4. Download and extract to appropriate directory")


def main():
    parser = argparse.ArgumentParser(
        description="Dataset Download and Setup Helper"
    )
    
    parser.add_argument(
        "--setup-structure",
        action="store_true",
        help="Create directory structure for datasets"
    )
    parser.add_argument(
        "--download-food11",
        action="store_true",
        help="Download Food-11 dataset from Kaggle"
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Verify dataset setup"
    )
    parser.add_argument(
        "--instructions",
        action="store_true",
        help="Print download instructions"
    )
    parser.add_argument(
        "--base-dir",
        type=str,
        default="./datasets",
        help="Base directory for datasets"
    )
    
    args = parser.parse_args()
    
    setup = DatasetSetup(args.base_dir)
    
    if args.setup_structure:
        setup.setup_directory_structure()
    elif args.download_food11:
        setup.download_food11_kaggle()
    elif args.verify:
        setup.verify_datasets()
    elif args.instructions:
        setup.print_download_instructions()
    else:
        # Default: show instructions
        setup.print_download_instructions()
        print("\n" + "=" * 70)
        print("To set up directory structure, run:")
        print("  python download_datasets.py --setup-structure")


if __name__ == "__main__":
    main()
