# 상세 학습 가이드 (Detailed Training Guide)

이 문서는 YOLO v8, EasyOCR, Collaborative Filtering 모델을 학습시키는 방법을 단계별로 설명합니다.

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
- 최소 50GB 저장 공간 (데이터셋용)

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
```

### 1.3 GPU 확인

```python
import torch
print(f"CUDA 사용 가능: {torch.cuda.is_available()}")
print(f"GPU 이름: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A'}")
```

---

## 2. YOLO v8 학습

### 2.1 데이터셋 다운로드

#### Stage 1: Food-11 데이터셋 (Kaggle)

**방법 1: 웹에서 직접 다운로드**
1. https://www.kaggle.com/datasets/trolukovich/food11-image-dataset 접속
2. "Download" 버튼 클릭
3. `food11-image-dataset.zip` 다운로드
4. `ml_training/datasets/food11/`에 압축 해제

**방법 2: Kaggle API 사용**
```bash
# Kaggle API 설치
pip install kaggle

# Kaggle API 키 설정 (~/.kaggle/kaggle.json)
# https://www.kaggle.com/settings에서 API 토큰 생성

# 다운로드
kaggle datasets download -d trolukovich/food11-image-dataset
unzip food11-image-dataset.zip -d datasets/food11/
```

#### Stage 2: AI Hub 한식 이미지 데이터셋

1. https://www.aihub.or.kr 회원가입 (한국 인증 필요)
2. "건강관리를 위한 음식 이미지" 검색
3. 데이터 신청 및 승인 대기
4. 다운로드 후 `ml_training/datasets/korean_food/`에 압축 해제

### 2.2 데이터 전처리

AI Hub 데이터는 YOLO 형식으로 변환이 필요합니다:

```python
# convert_aihub_to_yolo.py
import os
import json
import shutil
from pathlib import Path

def convert_aihub_to_yolo(aihub_dir, output_dir, selected_classes=154):
    """
    AI Hub 음식 이미지 데이터를 YOLO 형식으로 변환
    
    Args:
        aihub_dir: AI Hub 데이터 디렉토리
        output_dir: YOLO 형식 출력 디렉토리
        selected_classes: 선택할 클래스 수 (기본: 154)
    """
    # 출력 디렉토리 생성
    images_train = Path(output_dir) / "images" / "train"
    images_val = Path(output_dir) / "images" / "val"
    labels_train = Path(output_dir) / "labels" / "train"
    labels_val = Path(output_dir) / "labels" / "val"
    
    for d in [images_train, images_val, labels_train, labels_val]:
        d.mkdir(parents=True, exist_ok=True)
    
    # JSON 어노테이션 파일 처리
    annotation_dir = Path(aihub_dir) / "annotations"
    image_dir = Path(aihub_dir) / "images"
    
    class_mapping = {}  # 클래스 이름 -> 인덱스
    current_class_idx = 0
    
    for json_file in annotation_dir.glob("*.json"):
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # 이미지 정보
        image_info = data.get('images', [{}])[0]
        image_filename = image_info.get('file_name', '')
        img_width = image_info.get('width', 640)
        img_height = image_info.get('height', 640)
        
        # 어노테이션 처리
        annotations = data.get('annotations', [])
        yolo_labels = []
        
        for ann in annotations:
            category_name = ann.get('category_name', '')
            
            # 클래스 수 제한
            if category_name not in class_mapping:
                if current_class_idx >= selected_classes:
                    continue
                class_mapping[category_name] = current_class_idx
                current_class_idx += 1
            
            class_idx = class_mapping[category_name]
            
            # Bounding box 변환 (x, y, w, h -> YOLO 형식)
            bbox = ann.get('bbox', [0, 0, 0, 0])
            x, y, w, h = bbox
            
            # YOLO 형식: center_x, center_y, width, height (정규화)
            center_x = (x + w / 2) / img_width
            center_y = (y + h / 2) / img_height
            norm_w = w / img_width
            norm_h = h / img_height
            
            yolo_labels.append(f"{class_idx} {center_x:.6f} {center_y:.6f} {norm_w:.6f} {norm_h:.6f}")
        
        if yolo_labels:
            # Train/Val 분할 (80:20)
            import random
            is_train = random.random() < 0.8
            
            # 이미지 복사
            src_image = image_dir / image_filename
            if src_image.exists():
                dst_image = (images_train if is_train else images_val) / image_filename
                shutil.copy(src_image, dst_image)
                
                # 레이블 저장
                label_filename = Path(image_filename).stem + ".txt"
                dst_label = (labels_train if is_train else labels_val) / label_filename
                with open(dst_label, 'w') as f:
                    f.write('\n'.join(yolo_labels))
    
    # 클래스 매핑 저장
    with open(Path(output_dir) / "classes.txt", 'w', encoding='utf-8') as f:
        for name, idx in sorted(class_mapping.items(), key=lambda x: x[1]):
            f.write(f"{name}\n")
    
    print(f"변환 완료: {len(class_mapping)}개 클래스")
    return class_mapping

# 실행
if __name__ == "__main__":
    convert_aihub_to_yolo(
        aihub_dir="datasets/aihub_raw",
        output_dir="datasets/korean_food"
    )
```

### 2.3 data.yaml 설정

`data.yaml` 파일을 데이터셋 경로에 맞게 수정:

```yaml
# data.yaml
path: ./datasets/korean_food  # 데이터셋 루트 경로
train: images/train
val: images/val

# 클래스 수
nc: 154

# 클래스 이름 (classes.txt에서 로드)
names:
  0: white_rice
  1: kimchi_jjigae
  # ... (data.yaml 참조)
```

### 2.4 학습 실행

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

### 2.5 학습 모니터링

학습 진행 상황은 `runs/train/food_detection/` 디렉토리에서 확인:

```bash
# TensorBoard로 모니터링
tensorboard --logdir runs/train/

# 브라우저에서 http://localhost:6006 접속
```

### 2.6 모델 내보내기 (TFLite)

```bash
# TFLite로 내보내기 (모바일 배포용)
python yolo_training.py --export tflite --imgsz 640

# 내보낸 모델은 runs/train/food_detection/weights/ 에 저장됨
```

---

## 3. EasyOCR 학습

### 3.1 데이터셋 준비

#### Stage 1: 한글 합성 데이터 생성

```bash
# TextRecognitionDataGenerator로 한글 데이터 생성
python easyocr_trainer.py --generate-korean-data 1000 --output-dir datasets/easyocr/korean_generated
```

#### Stage 2: AI Hub OCR 데이터셋

1. https://www.aihub.or.kr 에서 "의약품, 화장품 패키징 OCR 데이터" 다운로드
2. `datasets/easyocr/aihub_ocr/`에 압축 해제

#### Stage 3: 커스텀 성분표 데이터

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
# AI Hub OCR 데이터를 EasyOCR 형식으로 변환
python easyocr_trainer.py --prepare-data \
    datasets/easyocr/aihub_ocr/images \
    datasets/easyocr/aihub_ocr/annotations.json \
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
