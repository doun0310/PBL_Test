# ML Training for Diet Tracking App

This directory contains training scripts for the AI/ML models used in the diet tracking application.

## Models Overview

| Model | Purpose | Dataset Size |
|-------|---------|--------------|
| YOLO v8 | Korean food detection | ~20,000+ images |
| EasyOCR | Nutrition label OCR | ~10,000+ samples |
| Collaborative Filtering | Food recommendations | User preference data |

---

## Dataset Sources (Kaggle)

### 1. YOLO v8 - Food Detection

#### Option A: Food-11 Image Dataset (Kaggle) - 기본
- **Source**: https://www.kaggle.com/datasets/trolukovich/food11-image-dataset
- **Size**: 16,643 images
- **Purpose**: Train YOLO to recognize food vs non-food objects
- **Classes**: 11 food categories (Bread, Dairy, Dessert, Egg, Fried food, Meat, Noodles, Rice, Seafood, Soup, Vegetable)

**Download Instructions:**
```bash
# Kaggle API 사용
kaggle datasets download -d trolukovich/food11-image-dataset
unzip food11-image-dataset.zip -d datasets/food11/
```

#### Option B: Korean Food Object Detection (Kaggle) - 한식 특화 ⭐
- **Source**: https://www.kaggle.com/datasets/jiminkoo/koreanfood-objectdetection-dataset
- **Size**: ~3,000+ images
- **Purpose**: Korean food object detection with bounding box annotations
- **Format**: YOLO format ready

**Download Instructions:**
```bash
kaggle datasets download -d jiminkoo/koreanfood-objectdetection-dataset
unzip koreanfood-objectdetection-dataset.zip -d datasets/korean_food/
```

#### Option C: Roboflow Korean Food Datasets (추가 데이터)
더 많은 한식 이미지가 필요한 경우 Roboflow에서 추가 데이터를 다운로드할 수 있습니다:

| Dataset | Source | Images | Classes |
|---------|--------|--------|---------|
| Korean Food Detector | [Roboflow](https://universe.roboflow.com/capstone-design-yolo-datasets/korean-food-detector-ouxym) | 2,482 | 다수 |
| Korean Food (DongA Univ) | [Roboflow](https://universe.roboflow.com/donga-university-1jxx6/korean-food-rgogz) | 959 | 53 |
| Korean Food YOLOv5 | [Roboflow](https://universe.roboflow.com/dsupod/korean-food_yolov5-wwfz0) | 991 | 51 |

---

### 2. EasyOCR - Nutrition Label Recognition

#### Option A: Nutritional Facts from Food Label (Kaggle) ⭐
- **Source**: https://www.kaggle.com/datasets/shensivam/nutritional-facts-from-food-label
- **Size**: 영양 성분표 이미지 + 레이블
- **Purpose**: Nutrition label OCR training

**Download Instructions:**
```bash
kaggle datasets download -d shensivam/nutritional-facts-from-food-label
unzip nutritional-facts-from-food-label.zip -d datasets/nutrition_ocr/
```

#### Option B: Handwriting OCR Data (Japanese/Korean) (Kaggle) ⭐
- **Source**: https://www.kaggle.com/datasets/nexdatafrank/handwriting-ocr-data-of-japanese-and-korean
- **Size**: 일본어/한국어 손글씨 이미지
- **Purpose**: Korean text recognition training

**Download Instructions:**
```bash
kaggle datasets download -d nexdatafrank/handwriting-ocr-data-of-japanese-and-korean
unzip handwriting-ocr-data-of-japanese-and-korean.zip -d datasets/korean_ocr/
```

#### Option C: Korean Text Generation (자체 생성)
- **Tool**: TextRecognitionDataGenerator (trdg)
- **Size**: 1,000+ samples (customizable)
- **Purpose**: Korean character recognition for nutrition terms

**Generate with:**
```bash
python easyocr_trainer.py --generate-korean-data 1000
```

#### Option D: Custom Nutrition Labels (직접 수집)
- **Size**: 800+ manually labeled samples
- **Purpose**: Fine-tuning for nutrition-specific Korean terms (탄수화물, 포화지방, etc.)
- **Note**: Capture and label nutrition labels from Korean products

---

### 3. Collaborative Filtering - Food Recommendations

No external dataset required. The recommender uses:
- Food database with nutrition information (calories, carbs, protein, fat)
- User preference history collected from app usage

Generate sample data for testing:
```bash
python collaborative_filtering.py --create-sample
```

---

## Directory Structure

After downloading datasets, organize them as follows:

```
ml_training/
├── datasets/
│   ├── food11/                    # Kaggle Food-11 dataset
│   │   ├── training/
│   │   ├── validation/
│   │   └── evaluation/
│   ├── korean_food/               # Kaggle Korean Food dataset (YOLO format)
│   │   ├── images/
│   │   │   ├── train/
│   │   │   └── val/
│   │   └── labels/
│   │       ├── train/
│   │       └── val/
│   ├── nutrition_ocr/             # Kaggle Nutrition Facts OCR
│   │   └── ...
│   └── easyocr/                   # EasyOCR training data
│       ├── korean_generated/
│       └── nutrition_labels/
├── data.yaml                      # YOLO dataset configuration
├── yolo_training.py               # YOLO training script
├── easyocr_trainer.py             # EasyOCR training script
├── collaborative_filtering.py    # Recommendation system
└── requirements.txt               # Python dependencies
```

---

## Quick Start

### 1. Install Dependencies
```bash
cd ml_training
pip install -r requirements.txt

# Kaggle API 설정
pip install kaggle
# ~/.kaggle/kaggle.json 파일 설정 필요 (https://www.kaggle.com/settings에서 API 토큰 생성)
```

### 2. Prepare Datasets
```bash
# 디렉토리 구조 설정
python download_datasets.py --setup-structure

# Kaggle 데이터셋 다운로드
python download_datasets.py --download-all
```

### 3. Train Models

**YOLO v8:**
```bash
python yolo_training.py --data data.yaml --epochs 100 --batch 16
```

**EasyOCR:**
```bash
# Generate Korean training data
python easyocr_trainer.py --generate-korean-data 1000

# Prepare training data from annotations
python easyocr_trainer.py --prepare-data datasets/easyocr/images datasets/easyocr/annotations.json
```

**Collaborative Filtering:**
```bash
# Create sample data and test
python collaborative_filtering.py --create-sample
python collaborative_filtering.py --method cosine --remaining-cal 500 --remaining-carb 50
```

---

## Training Configuration

### YOLO v8
- **Epochs**: 100-200 recommended
- **Batch Size**: 16 (adjust based on GPU memory)
- **Image Size**: 640x640
- **Classes**: 53-154 Korean food items (dataset dependent)

### EasyOCR
- **Epochs**: 3155 (as used in original training)
- **Train/Val Split**: 80:20
- **Languages**: Korean (ko), English (en)

### Collaborative Filtering
- **Algorithm**: Cosine similarity + Predicted preference
- **Features**: Calories, Carbohydrates, Protein, Fat

---

## Notes

- Large datasets (Food-11, AI Hub) should NOT be committed to git
- Add `datasets/` to `.gitignore`
- Training requires GPU for reasonable performance (YOLO, EasyOCR)
- AI Hub datasets require Korean ID for registration
