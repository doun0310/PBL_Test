"""
Dataset Download and Setup Helper Script (Kaggle 기반)

Kaggle에서 학습 데이터셋을 다운로드하고 설정하는 스크립트입니다.

Usage:
    # 디렉토리 구조 설정
    python download_datasets.py --setup-structure
    
    # 모든 Kaggle 데이터셋 다운로드
    python download_datasets.py --download-all
    
    # 개별 다운로드
    python download_datasets.py --download-food11
    python download_datasets.py --download-korean-food
    python download_datasets.py --download-nutrition-ocr
    
    # 데이터셋 검증
    python download_datasets.py --verify

Requirements:
    - kaggle (pip install kaggle)
    - kaggle.json 설정 필요 (~/.kaggle/kaggle.json)
"""

import argparse
import os
import subprocess
import zipfile
from pathlib import Path

try:
    from tqdm import tqdm
except ImportError:
    tqdm = None


class KaggleDatasetDownloader:
    """Kaggle 데이터셋 다운로드 헬퍼 클래스."""
    
    # Kaggle 데이터셋 정보
    DATASETS = {
        'food11': {
            'name': 'Food-11 Image Dataset',
            'kaggle_id': 'trolukovich/food11-image-dataset',
            'url': 'https://www.kaggle.com/datasets/trolukovich/food11-image-dataset',
            'size': '16,643 images',
            'purpose': 'Food vs non-food classification for YOLO',
            'output_dir': 'food11'
        },
        'korean_food': {
            'name': 'Korean Food Object Detection',
            'kaggle_id': 'jiminkoo/koreanfood-objectdetection-dataset',
            'url': 'https://www.kaggle.com/datasets/jiminkoo/koreanfood-objectdetection-dataset',
            'size': '~3,000+ images',
            'purpose': 'Korean food object detection (YOLO format)',
            'output_dir': 'korean_food'
        },
        'nutrition_ocr': {
            'name': 'Nutritional Facts from Food Label',
            'kaggle_id': 'shensivam/nutritional-facts-from-food-label',
            'url': 'https://www.kaggle.com/datasets/shensivam/nutritional-facts-from-food-label',
            'size': 'Nutrition label images',
            'purpose': 'OCR training for nutrition labels',
            'output_dir': 'nutrition_ocr'
        }
    }
    
    # Roboflow 추가 데이터셋 (수동 다운로드 필요)
    ROBOFLOW_DATASETS = {
        'korean_food_detector': {
            'name': 'Korean Food Detector',
            'url': 'https://universe.roboflow.com/capstone-design-yolo-datasets/korean-food-detector-ouxym',
            'size': '2,482 images',
            'purpose': 'Korean food detection with bounding boxes'
        },
        'korean_food_donga': {
            'name': 'Korean Food (DongA University)',
            'url': 'https://universe.roboflow.com/donga-university-1jxx6/korean-food-rgogz',
            'size': '959 images, 53 classes',
            'purpose': 'Korean food classification'
        },
        'korean_food_yolov5': {
            'name': 'Korean Food YOLOv5',
            'url': 'https://universe.roboflow.com/dsupod/korean-food_yolov5-wwfz0',
            'size': '991 images, 51 classes',
            'purpose': 'Korean food detection for restaurants/apps'
        }
    }
    
    def __init__(self, base_dir: str = "./datasets"):
        """Initialize with base directory for datasets."""
        self.base_dir = Path(base_dir)
    
    def check_kaggle_api(self) -> bool:
        """Kaggle API 설치 및 인증 확인."""
        try:
            import kaggle
            # 인증 확인
            kaggle.api.authenticate()
            print("✓ Kaggle API 인증 성공")
            return True
        except ImportError:
            print("✗ Kaggle 패키지가 설치되지 않았습니다.")
            print("  설치: pip install kaggle")
            return False
        except Exception as e:
            print(f"✗ Kaggle 인증 실패: {e}")
            print("\n  Kaggle API 설정 방법:")
            print("  1. https://www.kaggle.com/settings 접속")
            print("  2. 'Create New Token' 클릭")
            print("  3. 다운로드된 kaggle.json을 ~/.kaggle/kaggle.json으로 이동")
            print("  4. chmod 600 ~/.kaggle/kaggle.json (Linux/Mac)")
            return False
    
    def setup_directory_structure(self):
        """데이터셋 디렉토리 구조 생성."""
        print("Setting up dataset directory structure...")
        
        # YOLO 데이터셋 디렉토리
        yolo_dirs = [
            self.base_dir / "food11" / "training",
            self.base_dir / "food11" / "validation",
            self.base_dir / "food11" / "evaluation",
            self.base_dir / "korean_food" / "images" / "train",
            self.base_dir / "korean_food" / "images" / "val",
            self.base_dir / "korean_food" / "labels" / "train",
            self.base_dir / "korean_food" / "labels" / "val",
        ]
        
        # EasyOCR 데이터셋 디렉토리
        ocr_dirs = [
            self.base_dir / "nutrition_ocr",
            self.base_dir / "easyocr" / "korean_generated",
            self.base_dir / "easyocr" / "nutrition_labels" / "train",
            self.base_dir / "easyocr" / "nutrition_labels" / "val",
        ]
        
        all_dirs = yolo_dirs + ocr_dirs
        
        for dir_path in all_dirs:
            dir_path.mkdir(parents=True, exist_ok=True)
            print(f"  Created: {dir_path}")
        
        print("\n✓ 디렉토리 구조 생성 완료!")
    
    def download_dataset(self, dataset_key: str) -> bool:
        """Kaggle 데이터셋 다운로드."""
        if dataset_key not in self.DATASETS:
            print(f"Unknown dataset: {dataset_key}")
            return False
        
        info = self.DATASETS[dataset_key]
        output_dir = self.base_dir / info['output_dir']
        output_dir.mkdir(parents=True, exist_ok=True)
        
        print(f"\n{'='*60}")
        print(f"Downloading: {info['name']}")
        print(f"{'='*60}")
        print(f"Kaggle ID: {info['kaggle_id']}")
        print(f"Size: {info['size']}")
        print(f"Output: {output_dir}")
        print()
        
        try:
            import kaggle
            
            # 다운로드
            print("Downloading...")
            kaggle.api.dataset_download_files(
                info['kaggle_id'],
                path=str(output_dir),
                unzip=True
            )
            
            print(f"✓ 다운로드 완료: {output_dir}")
            return True
            
        except Exception as e:
            print(f"✗ 다운로드 실패: {e}")
            print(f"\n수동 다운로드:")
            print(f"  1. {info['url']} 접속")
            print(f"  2. 'Download' 버튼 클릭")
            print(f"  3. {output_dir}에 압축 해제")
            return False
    
    def download_all(self):
        """모든 Kaggle 데이터셋 다운로드."""
        if not self.check_kaggle_api():
            return
        
        print("\n" + "="*60)
        print("모든 Kaggle 데이터셋 다운로드")
        print("="*60)
        
        results = {}
        for key in self.DATASETS:
            results[key] = self.download_dataset(key)
        
        # 결과 요약
        print("\n" + "="*60)
        print("다운로드 결과")
        print("="*60)
        for key, success in results.items():
            status = "✓ 성공" if success else "✗ 실패"
            print(f"  {self.DATASETS[key]['name']}: {status}")
    
    def verify_datasets(self):
        """데이터셋 검증."""
        print("\nVerifying datasets...\n")
        
        results = {}
        
        for key, info in self.DATASETS.items():
            dataset_dir = self.base_dir / info['output_dir']
            
            if dataset_dir.exists():
                # 이미지 파일 수 계산
                images = list(dataset_dir.rglob("*.jpg")) + \
                         list(dataset_dir.rglob("*.jpeg")) + \
                         list(dataset_dir.rglob("*.png"))
                labels = list(dataset_dir.rglob("*.txt")) + \
                         list(dataset_dir.rglob("*.xml")) + \
                         list(dataset_dir.rglob("*.json"))
                
                results[key] = {
                    'exists': True,
                    'images': len(images),
                    'labels': len(labels)
                }
            else:
                results[key] = {
                    'exists': False,
                    'images': 0,
                    'labels': 0
                }
        
        # 결과 출력
        print("Dataset Verification Results:")
        print("=" * 60)
        
        for key, info in results.items():
            dataset_info = self.DATASETS[key]
            status = "✓" if info['exists'] and info['images'] > 0 else "✗"
            
            print(f"\n{dataset_info['name']}:")
            print(f"  Directory exists: {'Yes' if info['exists'] else 'No'}")
            print(f"  Images found: {info['images']:,}")
            print(f"  Labels found: {info['labels']:,}")
            print(f"  Status: {status}")
        
        return results
    
    def print_roboflow_instructions(self):
        """Roboflow 데이터셋 다운로드 안내."""
        print("\n" + "="*60)
        print("추가 데이터셋 (Roboflow - 수동 다운로드)")
        print("="*60)
        
        for key, info in self.ROBOFLOW_DATASETS.items():
            print(f"\n📦 {info['name']}")
            print(f"   URL: {info['url']}")
            print(f"   Size: {info['size']}")
            print(f"   Purpose: {info['purpose']}")
        
        print("\n" + "-"*60)
        print("Roboflow 다운로드 방법:")
        print("1. 위 URL 접속")
        print("2. 'Download Dataset' 클릭")
        print("3. 'YOLO v8' 또는 'YOLOv5 PyTorch' 형식 선택")
        print("4. datasets/korean_food_extra/ 디렉토리에 압축 해제")


def main():
    parser = argparse.ArgumentParser(
        description="Kaggle 데이터셋 다운로드 및 설정"
    )
    
    parser.add_argument(
        "--setup-structure",
        action="store_true",
        help="데이터셋 디렉토리 구조 생성"
    )
    parser.add_argument(
        "--download-all",
        action="store_true",
        help="모든 Kaggle 데이터셋 다운로드"
    )
    parser.add_argument(
        "--download-food11",
        action="store_true",
        help="Food-11 데이터셋 다운로드"
    )
    parser.add_argument(
        "--download-korean-food",
        action="store_true",
        help="Korean Food Object Detection 데이터셋 다운로드"
    )
    parser.add_argument(
        "--download-nutrition-ocr",
        action="store_true",
        help="Nutritional Facts OCR 데이터셋 다운로드"
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="데이터셋 검증"
    )
    parser.add_argument(
        "--show-roboflow",
        action="store_true",
        help="Roboflow 추가 데이터셋 안내"
    )
    parser.add_argument(
        "--base-dir",
        type=str,
        default="./datasets",
        help="데이터셋 기본 디렉토리"
    )
    
    args = parser.parse_args()
    
    downloader = KaggleDatasetDownloader(args.base_dir)
    
    if args.setup_structure:
        downloader.setup_directory_structure()
    elif args.download_all:
        downloader.download_all()
    elif args.download_food11:
        if downloader.check_kaggle_api():
            downloader.download_dataset('food11')
    elif args.download_korean_food:
        if downloader.check_kaggle_api():
            downloader.download_dataset('korean_food')
    elif args.download_nutrition_ocr:
        if downloader.check_kaggle_api():
            downloader.download_dataset('nutrition_ocr')
    elif args.verify:
        downloader.verify_datasets()
    elif args.show_roboflow:
        downloader.print_roboflow_instructions()
    else:
        # 기본: 안내 출력
        print("="*60)
        print("Kaggle 데이터셋 다운로드 도우미")
        print("="*60)
        
        print("\n📦 사용 가능한 데이터셋:")
        for key, info in downloader.DATASETS.items():
            print(f"\n  {info['name']}")
            print(f"    Kaggle: {info['kaggle_id']}")
            print(f"    Size: {info['size']}")
        
        print("\n" + "-"*60)
        print("사용 방법:")
        print("  1. 디렉토리 구조 설정:")
        print("     python download_datasets.py --setup-structure")
        print("\n  2. 모든 데이터셋 다운로드:")
        print("     python download_datasets.py --download-all")
        print("\n  3. 데이터셋 검증:")
        print("     python download_datasets.py --verify")
        print("\n  4. Roboflow 추가 데이터셋 안내:")
        print("     python download_datasets.py --show-roboflow")


if __name__ == "__main__":
    main()
