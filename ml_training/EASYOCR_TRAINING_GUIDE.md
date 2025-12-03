# EasyOCR 학습 가이드 (Korean Nutrition Label OCR)

이 가이드는 한국어 영양 성분표 인식을 위한 EasyOCR 모델 학습 방법을 설명합니다.

## 📋 목차

1. [환경 설정](#1-환경-설정)
2. [학습 데이터 준비](#2-학습-데이터-준비)
3. [3단계 학습 파이프라인](#3-3단계-학습-파이프라인)
4. [모델 학습 실행](#4-모델-학습-실행)
5. [모델 사용 (Inference)](#5-모델-사용-inference)
6. [문제 해결](#6-문제-해결)

---

## 1. 환경 설정

### 1.1 필수 패키지 설치

```bash
cd ml_training
pip install -r requirements.txt
```

### 1.2 EasyOCR 학습 환경 설정

```bash
# EasyOCR 학습 환경 자동 설정
python easyocr_trainer.py --setup-training --output-dir ./easyocr_training

# 설정 완료 후 다음 구조가 생성됩니다:
# easyocr_training/
# ├── EasyOCR/                  # EasyOCR 저장소
# ├── training_data/            # 학습 데이터
# ├── saved_models/             # 학습된 모델
# ├── korean_nutrition_charset.txt  # 문자 집합
# ├── train_config.yaml         # 학습 설정
# ├── train.sh                  # 학습 스크립트
# └── TRAINING_README.md        # 상세 가이드
```

---

## 2. 학습 데이터 준비

EasyOCR 학습에는 다음 형식의 데이터가 필요합니다:

### 2.1 데이터 형식

```
training_data/
├── train/
│   ├── labels.txt      # 학습 레이블
│   ├── image_001.jpg   # 텍스트 이미지
│   ├── image_002.jpg
│   └── ...
└── val/
    ├── labels.txt      # 검증 레이블
    └── ...
```

### 2.2 labels.txt 형식

```text
image_001.jpg	열량 250kcal
image_002.jpg	탄수화물 30g
image_003.jpg	단백질 15g
```

각 줄은 `이미지파일명<TAB>텍스트` 형식입니다.

---

## 3. 3단계 학습 파이프라인

프로젝트에서 사용한 3단계 학습 전략:

### 📊 Stage 1: 한글 문자 인식 (1,000개 샘플)

**목적**: 기본 한글 문자 인식 학습

```bash
# TextRecognitionDataGenerator를 사용한 합성 데이터 생성
python easyocr_trainer.py --generate-korean-data 1000 --output-dir ./easyocr_training/training_data
```

**생성되는 데이터**:
- 영양 성분표 관련 한글 단어 (열량, 탄수화물, 단백질, 지방 등)
- 1,000개의 합성 이미지

---

### 📊 Stage 2: 제품 라벨 OCR (50,000개 샘플)

**목적**: 실제 제품 라벨의 텍스트 패턴 학습

#### 2.1 Kaggle 데이터셋 다운로드

```bash
# Nutritional Facts from Food Label 데이터셋
kaggle datasets download -d shensivam/nutritional-facts-from-food-label
unzip nutritional-facts-from-food-label.zip -d datasets/nutrition_facts
```

#### 2.2 데이터 변환 (JSON 어노테이션 → EasyOCR 형식)

`annotations.json` 파일 생성 예시:
```json
{
  "label_001.jpg": [
    {
      "bbox": [10, 20, 150, 45],
      "text": "Calories 250kcal"
    },
    {
      "bbox": [10, 50, 150, 75],
      "text": "Total Fat 8g"
    }
  ],
  "label_002.jpg": [
    {
      "bbox": [15, 25, 140, 50],
      "text": "Protein 15g"
    }
  ]
}
```

변환 실행:
```bash
python easyocr_trainer.py --prepare-data datasets/nutrition_facts annotations.json \
    --output-dir ./easyocr_training/training_data
```

---

### 📊 Stage 3: 영양 성분표 Fine-tuning (800개 샘플)

**목적**: 한국어 영양 성분표 특화 학습

#### 3.1 커스텀 데이터 수집
- 직접 촬영한 한국 식품 영양 성분표 이미지 800장
- 특정 용어에 집중: '탄수화물', '포화지방', '트랜스지방', '나트륨' 등

#### 3.2 어노테이션
이미지 레이블링 도구 사용 (예: LabelImg, CVAT):
```json
{
  "korean_nutrition_001.jpg": [
    {
      "bbox": [20, 30, 200, 55],
      "text": "열량 250kcal"
    },
    {
      "bbox": [20, 60, 200, 85],
      "text": "탄수화물 30g"
    },
    {
      "bbox": [20, 90, 200, 115],
      "text": "단백질 15g"
    }
  ]
}
```

#### 3.3 데이터 준비
```bash
python easyocr_trainer.py --prepare-data custom_nutrition_labels/ custom_annotations.json \
    --output-dir ./easyocr_training/training_data
```

---

## 4. 모델 학습 실행

### 4.1 학습 파라미터

프로젝트에서 사용한 설정:
- **Epochs (num_iter)**: 3,155
- **Batch Size**: 192
- **Train/Val Split**: 80:20
- **이미지 크기**: 32 x 100 pixels
- **아키텍처**: TPS-ResNet-BiLSTM-Attn

### 4.2 학습 시작

#### Option 1: 자동 스크립트 사용 (권장)

```bash
cd easyocr_training
bash train.sh
```

#### Option 2: 수동 실행

```bash
cd easyocr_training/EasyOCR/trainer

python train.py \
    --train_data ../../training_data/train \
    --valid_data ../../training_data/val \
    --select_data "/" \
    --batch_ratio "1" \
    --character ../../korean_nutrition_charset.txt \
    --saved_model ../../saved_models \
    --Transformation TPS \
    --FeatureExtraction ResNet \
    --SequenceModeling BiLSTM \
    --Prediction Attn \
    --num_iter 3155 \
    --batch_size 192 \
    --lr 1.0 \
    --valInterval 100 \
    --workers 4 \
    --manualSeed 1111 \
    --imgH 32 \
    --imgW 100 \
    --rgb
```

### 4.3 학습 모니터링

학습 중 출력되는 정보:
```
[1/3155] Train loss: 2.456, Valid loss: 2.123, Accuracy: 45.2%
[100/3155] Train loss: 1.234, Valid loss: 1.045, Accuracy: 67.8%
[200/3155] Train loss: 0.876, Valid loss: 0.723, Accuracy: 78.5%
...
```

**모니터링 지표**:
- ✅ Train loss: 감소해야 함
- ✅ Valid loss: 감소해야 함 (overfitting 주의)
- ✅ Accuracy: 증가해야 함
- ✅ Character Error Rate: 감소해야 함

---

## 5. 모델 사용 (Inference)

### 5.1 학습된 모델로 추론

#### Python 코드:
```python
import easyocr

# 커스텀 학습 모델 로드
reader = easyocr.Reader(
    ['ko', 'en'],
    gpu=True,
    model_storage_directory='./easyocr_training/saved_models',
    user_network_directory='./easyocr_training/saved_models',
    recog_network='custom'
)

# 영양 성분표 이미지 읽기
result = reader.readtext('nutrition_label.jpg')

# 결과 출력
for (bbox, text, confidence) in result:
    print(f"Text: {text}, Confidence: {confidence:.2%}")
```

#### 커맨드 라인:
```bash
# OCR 오류 보정 포함 추론
python easyocr_trainer.py --infer path/to/nutrition_label.jpg
```

### 5.2 OCR 오류 자동 보정

학습 과정에서 발견된 일반적인 오인식 패턴이 자동으로 보정됩니다:

| 오인식 | 보정 |
|--------|------|
| 브랜스 지방 | 트랜스 지방 |
| 탄백질 | 단백질 |
| 탄수하물 | 탄수화물 |
| 포화지밤 | 포화지방 |
| 나트류 | 나트륨 |
| 당규 | 당류 |

### 5.3 영양 정보 추출

```python
from easyocr_trainer import EasyOCRNutritionExtractor

# 추출기 초기화
extractor = EasyOCRNutritionExtractor(
    languages=['ko', 'en'],
    gpu=True,
    user_network_directory='./easyocr_training/saved_models'
)

# 영양 정보 추출
nutrition = extractor.process_image('nutrition_label.jpg')

print(f"열량: {nutrition.calories} kcal")
print(f"탄수화물: {nutrition.carbohydrates} g")
print(f"단백질: {nutrition.protein} g")
print(f"지방: {nutrition.fat} g")
print(f"나트륨: {nutrition.sodium} mg")
print(f"당류: {nutrition.sugar} g")
```

---

## 6. 문제 해결

### 6.1 메모리 부족 (Out of Memory)

**증상**: CUDA out of memory 에러

**해결책**:
```bash
# batch_size 줄이기
--batch_size 96  # 기본 192에서 줄임

# 또는 이미지 크기 줄이기
--imgH 24 --imgW 80  # 기본 32x100에서 줄임

# 또는 CPU 사용
--num_gpu 0
```

### 6.2 정확도가 낮음

**해결책**:
1. **학습 데이터 증가**: 특히 오인식되는 문자가 포함된 샘플 추가
2. **Epoch 증가**: `--num_iter 5000` (기본 3155에서 증가)
3. **Learning Rate 조정**: `--lr 0.5` (기본 1.0에서 감소)
4. **데이터 품질 확인**: 어노테이션 오류 검토

### 6.3 학습이 너무 느림

**해결책**:
```bash
# GPU 사용 확인
--num_gpu 1

# Worker 수 조정
--workers 2  # CPU 병목 시 줄임

# 검증 간격 늘리기
--valInterval 200  # 기본 100에서 증가
```

### 6.4 TextRecognitionDataGenerator 설치 오류

```bash
# trdg 수동 설치
pip install trdg

# 또는 GitHub에서 직접 설치
pip install git+https://github.com/Belval/TextRecognitionDataGenerator.git
```

### 6.5 한글 폰트 문제

합성 데이터 생성 시 한글 폰트가 필요합니다:

```bash
# Ubuntu/Debian
sudo apt-get install fonts-nanum fonts-nanum-coding

# macOS (Homebrew)
brew install --cask font-nanum-gothic

# Windows
# Nanum 폰트를 C:\Windows\Fonts에 복사
```

---

## 📚 추가 리소스

### 공식 문서
- [EasyOCR GitHub](https://github.com/JaidedAI/EasyOCR)
- [EasyOCR Training Guide](https://github.com/JaidedAI/EasyOCR/blob/master/trainer/README.md)
- [CRAFT Text Detection](https://github.com/clovaai/CRAFT-pytorch)

### 데이터셋
- [Nutritional Facts from Food Label (Kaggle)](https://www.kaggle.com/datasets/shensivam/nutritional-facts-from-food-label)
- [Korean Food Object Detection (Kaggle)](https://www.kaggle.com/datasets/jiminkoo/koreanfood-objectdetection-dataset)
- [Handwriting OCR Data (Kaggle)](https://www.kaggle.com/datasets/nexdatafrank/handwriting-ocr-data-of-japanese-and-korean)

### 도구
- [LabelImg](https://github.com/heartexlabs/labelImg) - 이미지 어노테이션 도구
- [CVAT](https://github.com/opencv/cvat) - 컴퓨터 비전 어노테이션 도구
- [TextRecognitionDataGenerator](https://github.com/Belval/TextRecognitionDataGenerator) - 합성 데이터 생성

---

## ✅ 체크리스트

학습 시작 전 확인사항:

- [ ] Python 3.8+ 설치
- [ ] CUDA/GPU 설정 (선택사항, 권장)
- [ ] requirements.txt 패키지 설치
- [ ] EasyOCR 학습 환경 설정 완료 (`--setup-training`)
- [ ] 학습 데이터 준비 (train/, val/ 디렉토리)
- [ ] labels.txt 파일 형식 확인
- [ ] 문자 집합 파일 생성 확인
- [ ] 충분한 디스크 공간 (최소 10GB)

학습 후 확인사항:

- [ ] saved_models/ 디렉토리에 모델 저장 확인
- [ ] 추론 테스트 성공
- [ ] OCR 정확도 만족
- [ ] 오류 보정 패턴 작동 확인

---

**문의사항이나 이슈가 있으면 GitHub Issues에 등록해주세요.**

Happy Training! 🚀
