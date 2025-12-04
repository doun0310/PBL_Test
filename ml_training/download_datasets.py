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
        # YOLO v8 데이터셋
        'food11': {
            'name': 'Food-11 Image Dataset',
            'kaggle_id': 'trolukovich/food11-image-dataset',
            'url': 'https://www.kaggle.com/datasets/trolukovich/food11-image-dataset',
            'size': '16,643 images',
            'purpose': 'Food classification (11 categories)',
            'output_dir': 'food11',
            'category': 'yolo'
        },
        'food101': {
            'name': 'Food-101 Dataset',
            'kaggle_id': 'dansbecker/food-101',
            'url': 'https://www.kaggle.com/datasets/dansbecker/food-101',
            'size': '101,000 images (101 classes)',
            'purpose': 'Large-scale food recognition for robust training',
            'output_dir': 'food101',
            'category': 'yolo'
        },
        'korean_food': {
            'name': 'Korean Food Object Detection',
            'kaggle_id': 'jiminkoo/koreanfood-objectdetection-dataset',
            'url': 'https://www.kaggle.com/datasets/jiminkoo/koreanfood-objectdetection-dataset',
            'size': '~3,000+ images',
            'purpose': 'Korean food detection with bounding boxes',
            'output_dir': 'korean_food',
            'category': 'yolo'
        },
        
        # EasyOCR 데이터셋
        'nutrition_ocr': {
            'name': 'Nutritional Facts from Food Label',
            'kaggle_id': 'shensivam/nutritional-facts-from-food-label',
            'url': 'https://www.kaggle.com/datasets/shensivam/nutritional-facts-from-food-label',
            'size': '5,000+ label images',
            'purpose': 'Nutrition label OCR training',
            'output_dir': 'nutrition_ocr',
            'category': 'ocr'
        },
        'korean_ocr': {
            'name': 'Handwriting OCR Data (Japanese/Korean)',
            'kaggle_id': 'nexdatafrank/handwriting-ocr-data-of-japanese-and-korean',
            'url': 'https://www.kaggle.com/datasets/nexdatafrank/handwriting-ocr-data-of-japanese-and-korean',
            'size': '10,000+ handwriting samples',
            'purpose': 'Korean character recognition',
            'output_dir': 'korean_ocr',
            'category': 'ocr'
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
        print("Setting up optimized dataset directory structure...")
        
        # YOLO 데이터셋 디렉토리 (최적화된 구조)
        yolo_dirs = [
            # Food-11
            self.base_dir / "food11" / "training",
            self.base_dir / "food11" / "validation",
            self.base_dir / "food11" / "evaluation",
            
            # Food-101 (대규모 데이터셋)
            self.base_dir / "food101" / "images" / "train",
            self.base_dir / "food101" / "images" / "test",
            self.base_dir / "food101" / "meta",
            
            # Korean Food
            self.base_dir / "korean_food" / "images" / "train",
            self.base_dir / "korean_food" / "images" / "val",
            self.base_dir / "korean_food" / "labels" / "train",
            self.base_dir / "korean_food" / "labels" / "val",
            
            # Combined/Balanced dataset
            self.base_dir / "combined" / "images" / "train",
            self.base_dir / "combined" / "images" / "val",
            self.base_dir / "combined" / "labels" / "train",
            self.base_dir / "combined" / "labels" / "val",
        ]
        
        # EasyOCR 데이터셋 디렉토리 (확장된 구조)
        ocr_dirs = [
            # Nutrition labels
            self.base_dir / "nutrition_ocr" / "images",
            self.base_dir / "nutrition_ocr" / "labels",
            
            # Korean OCR
            self.base_dir / "korean_ocr" / "train",
            self.base_dir / "korean_ocr" / "test",
            
            # EasyOCR training data
            self.base_dir / "easyocr" / "korean_generated",
            self.base_dir / "easyocr" / "korean_augmented",
            self.base_dir / "easyocr" / "nutrition_labels" / "train",
            self.base_dir / "easyocr" / "nutrition_labels" / "val",
            self.base_dir / "easyocr" / "combined" / "train",
            self.base_dir / "easyocr" / "combined" / "val",
        ]
        
        # Collaborative Filtering 데이터베이스 디렉토리
        cf_dirs = [
            self.base_dir / "nutrition_db",
            self.base_dir / "nutrition_db" / "korean_foods",
            self.base_dir / "nutrition_db" / "user_preferences",
        ]
        
        all_dirs = yolo_dirs + ocr_dirs + cf_dirs
        
        for dir_path in all_dirs:
            dir_path.mkdir(parents=True, exist_ok=True)
            print(f"  ✓ {dir_path}")
        
        print(f"\n✓ {len(all_dirs)}개 디렉토리 생성 완료!")
        print("  - YOLO v8: Food-11, Food-101, Korean Food")
        print("  - EasyOCR: Nutrition labels, Korean OCR")
        print("  - Collaborative Filtering: Nutrition DB")
    
    def download_dataset(self, dataset_key: str) -> bool:
        """Kaggle 데이터셋 다운로드."""
        if dataset_key not in self.DATASETS:
            print(f"✗ Unknown dataset: {dataset_key}")
            print(f"  Available datasets: {', '.join(self.DATASETS.keys())}")
            return False
        
        info = self.DATASETS[dataset_key]
        
        try:
            output_dir = self.base_dir / info['output_dir']
            output_dir.mkdir(parents=True, exist_ok=True)
        except Exception as e:
            print(f"✗ 디렉토리 생성 실패: {e}")
            return False
        
        print(f"\n{'='*60}")
        print(f"Downloading: {info['name']}")
        print(f"{'='*60}")
        print(f"Kaggle ID: {info['kaggle_id']}")
        print(f"Size: {info['size']}")
        print(f"Output: {output_dir}")
        print()
        
        # 이미 다운로드 되었는지 확인
        try:
            existing_files = list(output_dir.rglob("*.jpg")) + \
                            list(output_dir.rglob("*.jpeg")) + \
                            list(output_dir.rglob("*.png"))
            if len(existing_files) > 100:  # 이미 상당량의 이미지가 있으면 건너뛰기
                print(f"⚠ 데이터셋이 이미 존재합니다 ({len(existing_files)} 이미지 발견)")
                print(f"  기존 데이터 사용. 다시 다운로드하려면 {output_dir} 삭제 후 재실행")
                return True
        except Exception as e:
            print(f"⚠ 파일 확인 중 오류 (무시하고 계속): {e}")
        
        try:
            import kaggle
            
            # 다운로드
            print("Downloading...")
            kaggle.api.dataset_download_files(
                info['kaggle_id'],
                path=str(output_dir),
                unzip=True,
                quiet=False
            )
            
            # 다운로드 검증
            try:
                downloaded_files = list(output_dir.rglob("*.jpg")) + \
                                 list(output_dir.rglob("*.jpeg")) + \
                                 list(output_dir.rglob("*.png"))
                
                if len(downloaded_files) > 0:
                    print(f"✓ 다운로드 완료: {output_dir}")
                    print(f"  {len(downloaded_files)} 이미지 파일 발견")
                    return True
                else:
                    print(f"⚠ 다운로드는 완료되었으나 이미지 파일이 없습니다.")
                    print(f"  압축 파일 확인: {output_dir}")
                    # 압축 파일이 있는지 확인
                    zip_files = list(output_dir.rglob("*.zip"))
                    if zip_files:
                        print(f"  ⚠ 압축 파일 발견: {zip_files[0].name}")
                        print(f"  수동으로 압축 해제가 필요할 수 있습니다")
                    return False
            except Exception as e:
                print(f"⚠ 다운로드 검증 중 오류: {e}")
                return False
            
        except ImportError:
            print(f"✗ Kaggle 패키지가 설치되지 않았습니다.")
            print(f"  설치: pip install kaggle")
            print(f"\n수동 다운로드:")
            print(f"  1. {info['url']} 접속")
            print(f"  2. 'Download' 버튼 클릭")
            print(f"  3. {output_dir}에 압축 해제")
            return False
        except Exception as e:
            print(f"✗ 다운로드 실패: {e}")
            print(f"\n수동 다운로드:")
            print(f"  1. {info['url']} 접속")
            print(f"  2. 'Download' 버튼 클릭")
            print(f"  3. 압축 파일을 {output_dir}에 직접 압축 해제")
            print(f"\n또는 Kaggle CLI 사용:")
            print(f"  kaggle datasets download -d {info['kaggle_id']}")
            print(f"  unzip {info['kaggle_id'].split('/')[-1]}.zip -d {output_dir}")
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
        
        try:
            for key, info in self.DATASETS.items():
                dataset_dir = self.base_dir / info['output_dir']
                
                try:
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
                except Exception as e:
                    print(f"⚠ {info['name']} 검증 중 오류: {e}")
                    results[key] = {
                        'exists': False,
                        'images': 0,
                        'labels': 0,
                        'error': str(e)
                    }
        except Exception as e:
            print(f"✗ 전체 검증 프로세스 오류: {e}")
            return {}
        
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
        "--download-all-yolo",
        action="store_true",
        help="모든 YOLO 데이터셋 다운로드 (Food-11, Food-101, Korean Food)"
    )
    parser.add_argument(
        "--download-all-ocr",
        action="store_true",
        help="모든 OCR 데이터셋 다운로드 (Nutrition OCR, Korean OCR)"
    )
    parser.add_argument(
        "--download-food11",
        action="store_true",
        help="Food-11 데이터셋 다운로드"
    )
    parser.add_argument(
        "--download-food101",
        action="store_true",
        help="Food-101 데이터셋 다운로드 (101,000 images)"
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
        "--download-korean-ocr",
        action="store_true",
        help="Handwriting OCR Data (Japanese/Korean) 데이터셋 다운로드"
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="데이터셋 검증"
    )
    parser.add_argument(
        "--stats",
        action="store_true",
        help="데이터셋 통계 정보 출력"
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
    elif args.download_all_yolo:
        print("\n모든 YOLO 데이터셋 다운로드 중...")
        if downloader.check_kaggle_api():
            for key in ['food11', 'food101', 'korean_food']:
                downloader.download_dataset(key)
    elif args.download_all_ocr:
        print("\n모든 OCR 데이터셋 다운로드 중...")
        if downloader.check_kaggle_api():
            for key in ['nutrition_ocr', 'korean_ocr']:
                downloader.download_dataset(key)
    elif args.download_food11:
        if downloader.check_kaggle_api():
            downloader.download_dataset('food11')
    elif args.download_food101:
        if downloader.check_kaggle_api():
            downloader.download_dataset('food101')
    elif args.download_korean_food:
        if downloader.check_kaggle_api():
            downloader.download_dataset('korean_food')
    elif args.download_nutrition_ocr:
        if downloader.check_kaggle_api():
            downloader.download_dataset('nutrition_ocr')
    elif args.download_korean_ocr:
        if downloader.check_kaggle_api():
            downloader.download_dataset('korean_ocr')
    elif args.verify:
        downloader.verify_datasets()
    elif args.stats:
        # stats는 verify와 동일한 기능
        downloader.verify_datasets()
    elif args.show_roboflow:
        downloader.print_roboflow_instructions()
    else:
        # 기본: 안내 출력
        print("="*60)
        print("Kaggle 데이터셋 다운로드 도우미 (Performance Optimized)")
        print("="*60)
        
        print("\n📦 YOLO v8 데이터셋:")
        for key, info in downloader.DATASETS.items():
            if info.get('category') == 'yolo':
                print(f"\n  ✓ {info['name']}")
                print(f"    ID: {info['kaggle_id']}")
                print(f"    Size: {info['size']}")
        
        print("\n📝 EasyOCR 데이터셋:")
        for key, info in downloader.DATASETS.items():
            if info.get('category') == 'ocr':
                print(f"\n  ✓ {info['name']}")
                print(f"    ID: {info['kaggle_id']}")
                print(f"    Size: {info['size']}")
        
        print("\n" + "-"*60)
        print("사용 방법:")
        print("  1. 디렉토리 구조 설정:")
        print("     python download_datasets.py --setup-structure")
        print("\n  2. 모든 데이터셋 다운로드:")
        print("     python download_datasets.py --download-all")
        print("\n  3. YOLO 데이터셋만 다운로드:")
        print("     python download_datasets.py --download-all-yolo")
        print("\n  4. OCR 데이터셋만 다운로드:")
        print("     python download_datasets.py --download-all-ocr")
        print("\n  5. 개별 다운로드:")
        print("     python download_datasets.py --download-food101")
        print("\n  6. 데이터셋 검증:")
        print("     python download_datasets.py --verify")


if __name__ == "__main__":
    main()
