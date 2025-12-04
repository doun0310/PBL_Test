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

**3-Stage Training Pipeline** (프로젝트에서 사용한 방법론):

#### Stage 1: Korean Character Recognition (1,000 samples)
- **Tool**: TextRecognitionDataGenerator (trdg)
- **Purpose**: Basic Hangul character recognition
- **Generate with:**
```bash
python easyocr_trainer.py --generate-korean-data 1000 --output-dir ./easyocr_training/training_data
```

#### Stage 2: Product Label OCR (50,000 samples)
- **Source**: https://www.kaggle.com/datasets/shensivam/nutritional-facts-from-food-label
- **Purpose**: General product label text patterns
- **Download:**
```bash
kaggle datasets download -d shensivam/nutritional-facts-from-food-label
unzip nutritional-facts-from-food-label.zip -d datasets/nutrition_ocr/
```

**Additional Korean OCR Dataset:**
- **Source**: https://www.kaggle.com/datasets/nexdatafrank/handwriting-ocr-data-of-japanese-and-korean
- **Purpose**: Korean handwriting recognition
```bash
kaggle datasets download -d nexdatafrank/handwriting-ocr-data-of-japanese-and-korean
unzip handwriting-ocr-data-of-japanese-and-korean.zip -d datasets/korean_ocr/
```

#### Stage 3: Nutrition Label Fine-tuning (800 samples)
- **Size**: 800+ manually labeled samples
- **Purpose**: Specific Korean nutrition terms (탄수화물, 포화지방, 트랜스지방, etc.)
- **Method**: Capture Korean product nutrition labels and annotate
- **Prepare with:**
```bash
python easyocr_trainer.py --prepare-data <images_dir> <annotations.json> --output-dir ./easyocr_training/training_data
```

#### EasyOCR Training Configuration
- **Train/Val Split**: 80:20
- **Epochs**: 3,155 iterations
- **OCR Error Correction**: Post-processing for common errors ('브랜스'→'트랜스', '탄백질'→'단백질')

**Complete EasyOCR Training Guide**: See [`EASYOCR_TRAINING_GUIDE.md`](EASYOCR_TRAINING_GUIDE.md)

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

**Option A: 자동 다운로드 (Kaggle API)**
```bash
# Step 1: Kaggle API 설정
# https://www.kaggle.com/settings 에서 'Create New Token' 클릭
# 다운로드된 kaggle.json을 ~/.kaggle/ 에 저장
mkdir -p ~/.kaggle
mv ~/Downloads/kaggle.json ~/.kaggle/
chmod 600 ~/.kaggle/kaggle.json

# Step 2: 디렉토리 구조 설정
python download_datasets.py --setup-structure

# Step 3: 모든 Kaggle 데이터셋 다운로드
python download_datasets.py --download-all

# Step 4: 다운로드 검증
python download_datasets.py --verify
```

**Option B: 수동 다운로드**

Kaggle API 설정이 어려운 경우 수동으로 다운로드:

1. **Food-11 Dataset**
   - URL: https://www.kaggle.com/datasets/trolukovich/food11-image-dataset
   - 다운로드 후: `datasets/food11/` 에 압축 해제

2. **Korean Food Object Detection**
   - URL: https://www.kaggle.com/datasets/jiminkoo/koreanfood-objectdetection-dataset
   - 다운로드 후: `datasets/korean_food/` 에 압축 해제

3. **Nutritional Facts OCR**
   - URL: https://www.kaggle.com/datasets/shensivam/nutritional-facts-from-food-label
   - 다운로드 후: `datasets/nutrition_ocr/` 에 압축 해제

4. **Korean OCR (Optional)**
   - URL: https://www.kaggle.com/datasets/nexdatafrank/handwriting-ocr-data-of-japanese-and-korean
   - 다운로드 후: `datasets/korean_ocr/` 에 압축 해제

### 3. Train Models

**YOLO v8:**
```bash
python yolo_training.py --data data.yaml --epochs 100 --batch 16
```

**EasyOCR:**
```bash
# Step 1: Setup training environment
python easyocr_trainer.py --setup-training --output-dir ./easyocr_training

# Step 2: Generate Korean synthetic data (Stage 1)
python easyocr_trainer.py --generate-korean-data 1000 --output-dir ./easyocr_training/training_data

# Step 3: Download and prepare datasets (Stage 2 & 3)
# Download Kaggle datasets first, then prepare
python easyocr_trainer.py --prepare-data datasets/nutrition_ocr annotations.json --output-dir ./easyocr_training/training_data

# Step 4: Start training (3155 epochs, 80:20 split)
cd easyocr_training
bash train.sh

# OR: Run inference with trained model
python easyocr_trainer.py --infer path/to/nutrition_label.jpg
```

**For detailed EasyOCR training guide, see**: [`EASYOCR_TRAINING_GUIDE.md`](EASYOCR_TRAINING_GUIDE.md)

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

## Troubleshooting Dataset Download

### Kaggle API 인증 오류
**오류**: `OSError: Could not find kaggle.json`
**해결**:
```bash
# 1. Kaggle에서 API 토큰 생성
# https://www.kaggle.com/settings -> "Create New API Token"

# 2. 토큰 파일 이동
mkdir -p ~/.kaggle
mv ~/Downloads/kaggle.json ~/.kaggle/
chmod 600 ~/.kaggle/kaggle.json

# 3. 검증
python -c "import kaggle; kaggle.api.authenticate(); print('Success!')"
```

### 다운로드 속도가 느린 경우
- Kaggle CLI를 사용한 수동 다운로드:
```bash
# 개별 데이터셋 다운로드
kaggle datasets download -d trolukovich/food11-image-dataset
kaggle datasets download -d jiminkoo/koreanfood-objectdetection-dataset
kaggle datasets download -d shensivam/nutritional-facts-from-food-label

# 압축 해제
unzip food11-image-dataset.zip -d datasets/food11/
unzip koreanfood-objectdetection-dataset.zip -d datasets/korean_food/
unzip nutritional-facts-from-food-label.zip -d datasets/nutrition_ocr/
```

### 데이터셋이 올바르게 다운로드되었는지 확인
```bash
python download_datasets.py --verify
```

**예상 결과**:
```
Dataset Verification Results:
============================================================

Food-11 Image Dataset:
  Directory exists: Yes
  Images found: 16,643
  Labels found: 0
  Status: ✓

Korean Food Object Detection:
  Directory exists: Yes
  Images found: 3,000+
  Labels found: 3,000+
  Status: ✓
```

### 디렉토리 구조가 잘못된 경우
```bash
# 디렉토리 구조 재생성
python download_datasets.py --setup-structure

# 검증
ls -la datasets/
```

### Windows에서 경로 오류 발생
Windows에서는 경로 구분자 문제로 오류가 발생할 수 있습니다:
```powershell
# PowerShell에서 실행
python download_datasets.py --setup-structure
python download_datasets.py --download-all --base-dir .\datasets
```

---
