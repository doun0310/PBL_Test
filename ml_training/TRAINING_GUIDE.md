# 상세 학습 가이드 (Detailed Training Guide)

이 문서는 YOLO v8, EasyOCR, Collaborative Filtering 모델을 학습시키는 방법을 단계별로 설명합니다.

**데이터셋 소스: Kaggle 기반** (AI Hub 대체)

---

## 목차
1. [환경 설정](#1-환경-설정)
2. [YOLO v8 학습](#2-yolo-v8-학습)
3. [EasyOCR 학습](#3-easyocr-학습)
4. [Collaborative Filtering 학습](#4-collaborative-filtering-학습)
5. [문제 해결](#5-문제-해결)

---

## 1. 환경 설정

### 1.1 필수 요구사항
- Python 3.8 이상
- CUDA 지원 GPU (권장: NVIDIA GTX 1080 이상)
- 최소 16GB RAM
- 최소 20GB 저장 공간 (데이터셋용)

### 1.2 가상환경 생성 및 의존성 설치

```bash
# 가상환경 생성
python -m venv venv

# 가상환경 활성화
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# ml_training 디렉토리로 이동
cd ml_training

# 의존성 설치
pip install -r requirements.txt

# Kaggle API 설치
pip install kaggle
```

### 1.3 Kaggle API 설정

```bash
# 1. https://www.kaggle.com/settings 접속
# 2. "Create New Token" 클릭하여 kaggle.json 다운로드
# 3. kaggle.json을 ~/.kaggle/ 폴더로 이동

# Linux/Mac:
mkdir -p ~/.kaggle
mv ~/Downloads/kaggle.json ~/.kaggle/
chmod 600 ~/.kaggle/kaggle.json

# Windows:
# C:\Users\<username>\.kaggle\kaggle.json 에 저장
```

### 1.4 GPU 확인

```python
import torch
print(f"CUDA 사용 가능: {torch.cuda.is_available()}")
print(f"GPU 이름: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A'}")
```

---

## 2. YOLO v8 학습

### 2.1 데이터셋 다운로드 (Kaggle)

#### 자동 다운로드 (권장)
```bash
# 디렉토리 구조 설정
python download_datasets.py --setup-structure

# 모든 데이터셋 다운로드
python download_datasets.py --download-all

# 또는 개별 다운로드
python download_datasets.py --download-food11
python download_datasets.py --download-korean-food
```

#### 수동 다운로드

**Option A: Food-11 Dataset (기본)**
```bash
# Kaggle API 사용
kaggle datasets download -d trolukovich/food11-image-dataset
unzip food11-image-dataset.zip -d datasets/food11/
```

**Option B: Korean Food Object Detection (한식 특화) ⭐**
```bash
# Kaggle API 사용 - YOLO 형식으로 제공됨
kaggle datasets download -d jiminkoo/koreanfood-objectdetection-dataset
unzip koreanfood-objectdetection-dataset.zip -d datasets/korean_food/
```

### 2.2 추가 데이터셋 (Roboflow)

더 많은 한식 이미지가 필요한 경우:

| Dataset | URL | Images | Classes |
|---------|-----|--------|---------|
| Korean Food Detector | [Roboflow](https://universe.roboflow.com/capstone-design-yolo-datasets/korean-food-detector-ouxym) | 2,482 | 다수 |
| Korean Food (DongA) | [Roboflow](https://universe.roboflow.com/donga-university-1jxx6/korean-food-rgogz) | 959 | 53 |
| Korean Food YOLOv5 | [Roboflow](https://universe.roboflow.com/dsupod/korean-food_yolov5-wwfz0) | 991 | 51 |

**Roboflow 다운로드 방법:**
1. 위 URL 접속
2. "Download Dataset" 클릭
3. "YOLO v8" 형식 선택
4. `datasets/korean_food_extra/`에 압축 해제

### 2.3 데이터셋 병합 (선택사항)

여러 데이터셋을 합치려면:

```python
# merge_datasets.py
import shutil
from pathlib import Path

def merge_yolo_datasets(datasets_list, output_dir):
    """여러 YOLO 데이터셋을 하나로 병합"""
    output = Path(output_dir)
    (output / "images" / "train").mkdir(parents=True, exist_ok=True)
    (output / "images" / "val").mkdir(parents=True, exist_ok=True)
    (output / "labels" / "train").mkdir(parents=True, exist_ok=True)
    (output / "labels" / "val").mkdir(parents=True, exist_ok=True)
    
    for dataset_dir in datasets_list:
        dataset = Path(dataset_dir)
        # 이미지 복사
        for img in dataset.rglob("*.jpg"):
            if "train" in str(img):
                shutil.copy(img, output / "images" / "train" / img.name)
            elif "val" in str(img):
                shutil.copy(img, output / "images" / "val" / img.name)
        # 레이블 복사
        for lbl in dataset.rglob("*.txt"):
            if "train" in str(lbl):
                shutil.copy(lbl, output / "labels" / "train" / lbl.name)
            elif "val" in str(lbl):
                shutil.copy(lbl, output / "labels" / "val" / lbl.name)

# 사용 예시
merge_yolo_datasets([
    "datasets/korean_food",
    "datasets/korean_food_extra"
], "datasets/korean_food_merged")
```

### 2.4 data.yaml 설정

Kaggle Korean Food 데이터셋은 이미 YOLO 형식으로 제공되므로 `data.yaml`만 경로 설정:

```yaml
# data.yaml
path: ./datasets/korean_food  # 데이터셋 루트 경로
train: images/train
val: images/val

# 클래스 수 (데이터셋에 따라 조정)
nc: 53  # Korean Food Object Detection 기준

# 클래스 이름 (데이터셋의 classes.txt 또는 data.yaml 참조)
names:
  0: rice
  1: kimchi
  # ... (다운로드한 데이터셋의 data.yaml 참조)
```

### 2.5 학습 실행

```bash
# 기본 학습 (GPU 사용)
python yolo_training.py --data data.yaml --epochs 100 --batch 16

# 상세 옵션
python yolo_training.py \
    --model yolov8m.pt \
    --data data.yaml \
    --epochs 200 \
    --batch 16 \
    --imgsz 640 \
    --device 0 \
    --workers 8

# CPU만 사용 (느림)
python yolo_training.py --data data.yaml --epochs 50 --batch 8 --device cpu
```

### 2.6 학습 모니터링

학습 진행 상황은 `runs/train/food_detection/` 디렉토리에서 확인:

```bash
# TensorBoard로 모니터링
tensorboard --logdir runs/train/

# 브라우저에서 http://localhost:6006 접속
```

### 2.7 모델 내보내기 (TFLite)

```bash
# TFLite로 내보내기 (모바일 배포용)
python yolo_training.py --export tflite --imgsz 640

# 내보낸 모델은 runs/train/food_detection/weights/ 에 저장됨
```

---

## 3. EasyOCR 학습

### 3.1 데이터셋 준비 (Kaggle)

#### Option A: Nutritional Facts from Food Label (Kaggle) ⭐
```bash
# Kaggle에서 영양 성분표 OCR 데이터셋 다운로드
kaggle datasets download -d shensivam/nutritional-facts-from-food-label
unzip nutritional-facts-from-food-label.zip -d datasets/nutrition_ocr/

# 또는 자동 다운로드
python download_datasets.py --download-nutrition-ocr
```

#### Option B: Handwriting OCR Data (Japanese/Korean) (Kaggle) ⭐
```bash
# Kaggle에서 한국어/일본어 손글씨 OCR 데이터셋 다운로드
kaggle datasets download -d nexdatafrank/handwriting-ocr-data-of-japanese-and-korean
unzip handwriting-ocr-data-of-japanese-and-korean.zip -d datasets/korean_ocr/

# 또는 자동 다운로드
python download_datasets.py --download-korean-ocr
```

#### Option C: 한글 합성 데이터 생성 (TextRecognitionDataGenerator)

```bash
# TextRecognitionDataGenerator로 한글 데이터 생성
python easyocr_trainer.py --generate-korean-data 1000 --output-dir datasets/easyocr/korean_generated
```

#### Option D: 커스텀 성분표 데이터 (직접 수집)

직접 성분표 이미지를 촬영하고 레이블링:

```
datasets/easyocr/nutrition_labels/
├── train/
│   ├── img_001.jpg
│   ├── img_002.jpg
│   └── ...
├── val/
│   └── ...
└── labels.txt  # 형식: 파일명\t텍스트
```

`labels.txt` 예시:
```
img_001.jpg	열량 250kcal
img_002.jpg	탄수화물 30g
img_003.jpg	단백질 15g
img_004.jpg	포화지방 5g
img_005.jpg	트랜스지방 0g
```

### 3.2 데이터 전처리

```bash
# OCR 데이터를 EasyOCR 형식으로 변환
python easyocr_trainer.py --prepare-data \
    datasets/nutrition_ocr/images \
    datasets/nutrition_ocr/annotations.json \
    --output-dir datasets/easyocr/prepared
```

### 3.3 학습 실행

EasyOCR 학습은 공식 trainer를 사용합니다:

```bash
# 1. EasyOCR trainer 클론
git clone https://github.com/JaidedAI/EasyOCR.git
cd EasyOCR/trainer

# 2. 설정 파일 수정
# config.yaml 에서 데이터 경로 설정

# 3. 학습 실행
python train.py --config config.yaml
```

### 3.4 학습 설정

`config.yaml` 예시:

```yaml
# EasyOCR 학습 설정
experiment_name: nutrition_label_ocr
train_data: ../../datasets/easyocr/prepared/train
valid_data: ../../datasets/easyocr/prepared/val

# 학습 파라미터
epochs: 3155
batch_size: 32
lr: 0.001

# 언어
lang_list: ['ko', 'en']

# 모델
model: CRNN

# 저장
saved_model: ./saved_models/
```

### 3.5 OCR 오인식 후처리

학습 후에도 오인식이 발생할 수 있으므로, 후처리 패턴을 적용:

```python
from easyocr_trainer import EasyOCRNutritionExtractor

# 추출기 초기화 (오인식 교정 패턴 포함)
extractor = EasyOCRNutritionExtractor(languages=['ko', 'en'])

# 이미지에서 성분 추출
nutrition = extractor.process_image("nutrition_label.jpg")

print(f"열량: {nutrition.calories} kcal")
print(f"탄수화물: {nutrition.carbohydrates} g")
print(f"단백질: {nutrition.protein} g")
print(f"지방: {nutrition.fat} g")
```

---

## 4. Collaborative Filtering 학습

### 4.1 데이터 준비

음식 데이터베이스 CSV 파일 생성:

```csv
food_id,name,calories,carbohydrates,protein,fat
food_001,흰쌀밥,300,65,5,1
food_002,김치찌개,150,8,12,8
food_003,삼겹살,450,2,20,40
...
```

### 4.2 샘플 데이터 생성 및 테스트

```bash
# 샘플 데이터 생성
python collaborative_filtering.py --create-sample

# 추천 테스트 (잔여 칼로리 기준)
python collaborative_filtering.py \
    --method cosine \
    --food-database sample_food_database.csv \
    --remaining-cal 500 \
    --remaining-carb 50 \
    --remaining-protein 30 \
    --remaining-fat 20
```

### 4.3 실제 데이터로 학습

```python
from collaborative_filtering import NutritionBasedRecommender
import pandas as pd

# 음식 데이터베이스 로드
food_db = pd.read_csv("food_database.csv")

# 추천기 초기화
recommender = NutritionBasedRecommender()
recommender.load_food_database(food_db)

# 사용자 선호도 추가 (앱에서 수집)
recommender.add_user_preference("user_001", "food_001", 5.0)  # 5점 평가
recommender.add_user_preference("user_001", "food_002", 4.0)

# 추천 받기
recommendations = recommender.recommend_foods(
    user_id="user_001",
    remaining_calories=500,
    remaining_carbs=50,
    remaining_protein=30,
    remaining_fat=20,
    n=10
)

for name, score, nutrition in recommendations:
    print(f"{name}: {score:.2f}점 (칼로리: {nutrition['calories']})")
```

### 4.4 모델 저장 및 로드

```python
# 모델 저장
recommender.save("recommender_model.pkl")

# 모델 로드
recommender = NutritionBasedRecommender()
recommender.load("recommender_model.pkl")
```

---

## 5. 문제 해결

### 5.1 CUDA 메모리 부족

```bash
# 배치 사이즈 줄이기
python yolo_training.py --batch 8

# 이미지 크기 줄이기
python yolo_training.py --imgsz 416
```

### 5.2 학습이 너무 느림

- GPU 드라이버 업데이트
- CUDA 버전 확인 (PyTorch와 호환되는지)
- 데이터 로더 워커 수 조정: `--workers 4`

### 5.3 과적합 방지

```bash
# 데이터 증강 활성화
python yolo_training.py --augment True

# 조기 종료 설정
python yolo_training.py --patience 30
```

### 5.4 EasyOCR 한글 인식 오류

- 더 많은 학습 데이터 추가
- `easyocr_trainer.py`의 `ocr_corrections` 딕셔너리에 패턴 추가:

```python
self.ocr_corrections = {
    '브랜스': '트랜스',
    '탄백질': '단백질',
    # 새로운 패턴 추가
    '새로운오류': '정확한텍스트',
}
```

---

## 학습 완료 후 체크리스트

- [ ] YOLO 모델이 음식을 정확히 감지하는지 테스트
- [ ] EasyOCR이 성분표를 올바르게 인식하는지 테스트
- [ ] 추천 시스템이 합리적인 음식을 추천하는지 테스트
- [ ] TFLite 모델이 모바일에서 동작하는지 테스트
- [ ] 모든 모델을 `assets/models/` 디렉토리에 배포
