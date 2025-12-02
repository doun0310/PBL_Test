# ML Training for Diet Tracking App

This directory contains training scripts for the AI/ML models used in the diet tracking application.

## Models Overview

| Model | Purpose | Dataset Size |
|-------|---------|--------------|
| YOLO v8 | Korean food detection | 289,426 images |
| EasyOCR | Nutrition label OCR | 51,800 samples |
| Collaborative Filtering | Food recommendations | User preference data |

---

## Dataset Sources

### 1. YOLO v8 - Food Detection

#### Stage 1: Food-11 Image Dataset (Kaggle)
- **Source**: https://www.kaggle.com/datasets/trolukovich/food11-image-dataset
- **Size**: 16,643 images
- **Purpose**: Train YOLO to recognize food vs non-food objects
- **Classes**: 11 food categories (Bread, Dairy, Dessert, Egg, Fried food, Meat, Noodles, Rice, Seafood, Soup, Vegetable)

**Download Instructions:**
1. Create a Kaggle account at https://www.kaggle.com
2. Go to https://www.kaggle.com/datasets/trolukovich/food11-image-dataset
3. Click "Download" button
4. Extract to `datasets/food11/`

#### Stage 2: AI Hub Korean Food Images (건강관리를 위한 음식 이미지)
- **Source**: https://www.aihub.or.kr/aihubdata/data/view.do?currMenu=115&topMenu=100&aihubDataSe=data&dataSetSn=74
- **Original Size**: 3,000,000 images (3,500 classes)
- **Reduced Size**: 272,783 images (154 classes - selected for training)
- **Purpose**: Fine-tune for specific Korean food classification

**Download Instructions:**
1. Create an AI Hub account at https://www.aihub.or.kr (Korean ID required)
2. Navigate to the dataset page
3. Request access and download
4. Extract to `datasets/korean_food/`

---

### 2. EasyOCR - Nutrition Label Recognition

#### Stage 1: Korean Text Data (Generated)
- **Tool**: TextRecognitionDataGenerator (trdg)
- **Size**: 1,000 samples
- **Purpose**: Basic Korean character recognition

**Generate with:**
```bash
python easyocr_trainer.py --generate-korean-data 1000
```

#### Stage 2: AI Hub Pharmaceutical/Cosmetic OCR Data (의약품, 화장품 패키징 OCR 데이터)
- **Source**: https://www.aihub.or.kr/aihubdata/data/view.do?currMenu=115&topMenu=100&aihubDataSe=data&dataSetSn=88
- **Size**: 50,000 labeled samples
- **Purpose**: Product label text recognition training

#### Stage 3: Custom Nutrition Labels
- **Size**: 800 manually labeled samples
- **Purpose**: Fine-tuning for nutrition-specific terms (탄수화물, 포화지방, etc.)
- **Note**: This dataset was manually captured and labeled

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
│   ├── korean_food/               # AI Hub Korean food dataset
│   │   ├── images/
│   │   │   ├── train/
│   │   │   └── val/
│   │   └── labels/
│   │       ├── train/
│   │       └── val/
│   └── easyocr/                   # EasyOCR training data
│       ├── korean_generated/
│       ├── aihub_ocr/
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
```

### 2. Prepare Datasets
```bash
# Download datasets manually from sources above, then:
python download_datasets.py --setup-structure
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
- **Classes**: 154 Korean food items

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
