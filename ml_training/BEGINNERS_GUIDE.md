# 초보자를 위한 ML 학습 가이드

## 📚 목차

1. [시작하기 전에](#시작하기-전에)
2. [YOLO v8 음식 인식 가이드](#yolo-v8-음식-인식-가이드)
3. [EasyOCR 성분표 인식 가이드](#easyocr-성분표-인식-가이드)
4. [Collaborative Filtering 추천 시스템 가이드](#collaborative-filtering-추천-시스템-가이드)
5. [자주 묻는 질문 (FAQ)](#자주-묻는-질문-faq)

---

## 시작하기 전에

### 필요한 것들

1. **Python 3.8 이상** - [Python 설치 가이드](https://www.python.org/downloads/)
2. **충분한 디스크 공간** - 최소 20GB 권장
3. **GPU (선택사항)** - 학습 속도를 높이려면 NVIDIA GPU 권장

### 환경 설정 (한 번만 하면 됩니다!)

```bash
# 1. ml_training 폴더로 이동
cd ml_training

# 2. 필요한 패키지 설치 (5-10분 소요)
pip install -r requirements.txt

# 3. 설치 확인
python test_setup.py
```

✅ "모든 검증 통과!" 메시지가 나오면 준비 완료!

---

## YOLO v8 음식 인식 가이드

### 🎯 YOLO란?

**YOLO (You Only Look Once)**는 사진 속에서 음식을 찾아내는 AI입니다.

**예시:**
- 입력: 삼겹살과 김치가 있는 사진
- 출력: "삼겹살 발견! (신뢰도: 95%)", "김치 발견! (신뢰도: 92%)"

### 단계별 학습 과정

#### 1단계: 데이터 다운로드 (처음 한 번만)

```bash
# Kaggle 계정 필요 (무료)
# https://www.kaggle.com/ 에서 회원가입

# API 키 설정
# 1. Kaggle 프로필 > Account > Create New API Token
# 2. 다운로드된 kaggle.json을 ~/.kaggle/ 폴더에 복사

# 데이터셋 다운로드
python download_datasets.py --download-food11
python download_datasets.py --download-korean-food
```

**다운로드되는 것:**
- Food-11: 16,643개 음식 이미지 (기본 음식 인식 학습용)
- Korean Food: 3,000+개 한식 이미지 (한식 특화 학습용)

#### 2단계: 데이터 구조 확인

```
datasets/
├── food11/
│   ├── images/
│   │   ├── train/  ← 학습용 이미지
│   │   └── val/    ← 검증용 이미지
│   └── labels/
│       ├── train/  ← 학습용 라벨 (음식 위치 정보)
│       └── val/    ← 검증용 라벨
```

**라벨 파일 예시 (labels/train/image001.txt):**
```
0 0.5 0.5 0.3 0.4
# 클래스번호 중심x 중심y 너비 높이
# 0 = 삼겹살, 좌표는 0-1 사이 비율
```

#### 3단계: 학습 시작!

```bash
# 기본 학습 (CPU, 1-2일 소요)
python yolo_training.py --data data.yaml --epochs 100 --batch 8

# GPU 사용 시 (4-6시간 소요, 추천!)
python yolo_training.py --data data.yaml --epochs 100 --batch 16 --device 0

# 빠른 테스트 (5분, 결과는 부정확)
python yolo_training.py --data data.yaml --epochs 3 --batch 4
```

**주요 파라미터 설명:**
- `--epochs 100`: 전체 데이터를 100번 반복 학습
- `--batch 16`: 한 번에 16개 이미지씩 학습 (GPU 메모리에 따라 조정)
- `--device 0`: GPU 0번 사용 (CPU는 `cpu`로 설정)

#### 4단계: 학습 진행 확인

학습 중 출력 예시:
```
Epoch 1/100
  0%|          | 0/1043 [00:00<?, ?it/s]
 50%|█████     | 521/1043 [05:30<05:30, 1.57it/s]
100%|██████████| 1043/1043 [11:00<00:00, 1.58it/s]

Train: box_loss=2.5, cls_loss=1.2, dfl_loss=0.8
Val: mAP50=0.65, mAP50-95=0.42
```

**해석:**
- `box_loss`: 박스 위치 오차 (낮을수록 좋음)
- `cls_loss`: 분류 오차 (낮을수록 좋음)
- `mAP50`: 정확도 (높을수록 좋음, 0.6 이상이면 양호)

#### 5단계: 학습 결과 확인

```bash
# 학습된 모델 위치
runs/train/exp/weights/best.pt  ← 최고 성능 모델
runs/train/exp/weights/last.pt  ← 마지막 모델

# 결과 시각화
runs/train/exp/
├── results.png      ← 학습 그래프
├── confusion_matrix.png  ← 혼동 행렬
└── val_batch0_pred.jpg   ← 예측 결과 예시
```

#### 6단계: 모델 테스트

```bash
# 새 이미지로 테스트
python yolo_training.py --predict path/to/test_image.jpg

# 웹캠으로 실시간 테스트
python yolo_training.py --predict 0
```

#### 7단계: 모바일 앱용으로 변환

```bash
# TFLite 변환 (Flutter 앱에서 사용)
python yolo_training.py --export tflite

# 변환된 파일 위치
runs/train/exp/weights/best.tflite
```

### 💡 팁과 트릭

**Q: 학습이 너무 느려요!**
- GPU 사용을 권장합니다 (Colab 무료 GPU 사용 가능)
- `--batch` 크기를 줄여보세요 (예: 16 → 8)

**Q: 정확도가 낮아요 (mAP < 0.5)**
- Epochs를 늘려보세요 (100 → 200)
- 더 많은 데이터를 추가하세요
- 데이터 라벨이 정확한지 확인하세요

**Q: Out of Memory 에러가 나요!**
```bash
# Batch 크기 줄이기
python yolo_training.py --data data.yaml --epochs 100 --batch 4
```

---

## EasyOCR 성분표 인식 가이드

### 🎯 EasyOCR이란?

**EasyOCR**은 이미지에서 텍스트를 읽어내는 AI입니다.

**예시:**
- 입력: 영양성분표 사진
- 출력: "열량 250kcal, 탄수화물 30g, 단백질 5g"

### 단계별 학습 과정

#### 1단계: 학습 환경 자동 설정

```bash
# 한 번의 명령으로 모든 설정 완료!
python easyocr_trainer.py --setup-training --output-dir ./easyocr_training
```

**자동으로 실행되는 작업:**
- ✅ EasyOCR GitHub 저장소 복제
- ✅ 학습 데이터 폴더 생성
- ✅ 한글 문자 집합 생성
- ✅ 설정 파일 생성 (train_config.yaml)
- ✅ 학습 스크립트 생성 (train.sh)

#### 2단계: 한글 학습 데이터 생성

```bash
# 1,000개의 합성 한글 이미지 생성 (5-10분 소요)
python easyocr_trainer.py --generate-korean-data 1000 --output-dir ./easyocr_training/training_data
```

**생성되는 데이터 예시:**
```
training_data/korean_synthetic/
├── images/
│   ├── 탄수화물_001.png
│   ├── 단백질_002.png
│   └── 지방_003.png
└── labels.txt
    탄수화물
    단백질
    지방
```

#### 3단계: 실제 성분표 데이터 준비 (선택사항)

```bash
# Kaggle에서 영양성분표 데이터 다운로드
python download_datasets.py --download-nutrition-facts

# 자신이 직접 수집한 데이터 사용
python easyocr_trainer.py --prepare-data custom_labels/ annotations.json --output-dir ./easyocr_training/training_data
```

**커스텀 데이터 형식 (annotations.json):**
```json
{
  "image001.jpg": {
    "text": "열량 250kcal",
    "boxes": [[10, 20, 150, 40]]
  },
  "image002.jpg": {
    "text": "탄수화물 30g",
    "boxes": [[15, 25, 140, 45]]
  }
}
```

#### 4단계: 학습 파라미터 조정 (선택사항)

```bash
# easyocr_training/train_config.yaml 파일 편집
nano easyocr_training/train_config.yaml
```

**주요 설정:**
```yaml
# 기본 설정 (권장)
num_epochs: 3155  # 학습 반복 횟수
batch_size: 192   # 한 번에 처리할 이미지 수
train_val_split: 0.8  # 학습:검증 = 80:20

# 빠른 테스트용
num_epochs: 10
batch_size: 32
```

#### 5단계: 학습 시작

```bash
cd easyocr_training

# 학습 시작 (GPU: 2-3일, CPU: 1-2주 소요)
bash train.sh

# 백그라운드에서 실행 (터미널 종료해도 계속 실행)
nohup bash train.sh > training.log 2>&1 &

# 진행상황 확인
tail -f training.log
```

**학습 진행 예시:**
```
Epoch [1/3155]
Step [100/5000]: loss=2.45, acc=0.65
Step [200/5000]: loss=2.12, acc=0.72
...
Validation: loss=1.85, acc=0.78
```

#### 6단계: 학습된 모델 테스트

```bash
cd ..  # ml_training 폴더로 돌아가기

# 성분표 이미지 테스트
python easyocr_trainer.py --infer nutrition_label.jpg

# 결과 예시
# 인식 결과: "열량 250kcal"
# 교정 후: "열량 250kcal" (신뢰도: 0.92)
```

#### 7단계: OCR 오류 자동 수정

**내장된 오류 수정 패턴:**
```python
# 자동으로 수정되는 예시
"브랜스 지방" → "트랜스 지방"
"탄백질"     → "단백질"  
"나트륨"     → "나트륨"
```

### 💡 팁과 트릭

**Q: 학습 시간을 줄이고 싶어요!**
```bash
# Epochs 줄이기 (정확도는 낮아짐)
nano easyocr_training/train_config.yaml
# num_epochs: 3155 → 300
```

**Q: 특정 단어를 잘 인식 못 해요!**
```bash
# 해당 단어로 추가 데이터 생성
python easyocr_trainer.py --generate-korean-data 100 --words "포화지방,불포화지방,트랜스지방"
```

**Q: 학습 중 에러가 났어요!**
```bash
# 로그 확인
tail -100 easyocr_training/training.log

# 일반적인 해결법: 메모리 부족
# → batch_size 줄이기 (192 → 96)
```

---

## Collaborative Filtering 추천 시스템 가이드

### 🎯 Collaborative Filtering이란?

**협업 필터링**은 사용자의 취향을 분석해서 음식을 추천하는 AI입니다.

**예시:**
- 사용자 A: 삼겹살(좋아함), 김치찌개(좋아함), 샐러드(싫어함)
- 사용자 B: 삼겹살(좋아함), 된장찌개(좋아함)
- 추천: 사용자 B에게 "김치찌개" 추천!

### 단계별 구현 과정

#### 1단계: 데이터 준비

```bash
# 샘플 데이터 생성
python collaborative_filtering.py --generate-sample-data --output ratings.csv

# 생성된 데이터 확인
head ratings.csv
```

**ratings.csv 예시:**
```csv
user_id,food_id,rating,calories,carbs,protein,fat
user_001,food_삼겹살,5,250,5,15,20
user_001,food_김치찌개,4,120,15,8,5
user_002,food_삼겹살,5,250,5,15,20
user_002,food_된장찌개,4,110,12,7,6
```

**데이터 컬럼 설명:**
- `user_id`: 사용자 고유 번호
- `food_id`: 음식 고유 번호
- `rating`: 평점 (1-5, 높을수록 좋아함)
- `calories`: 칼로리
- `carbs`: 탄수화물 (g)
- `protein`: 단백질 (g)
- `fat`: 지방 (g)

#### 2단계: 실제 데이터 형식 맞추기

```python
# your_data.csv → ratings.csv 형식으로 변환
import pandas as pd

# 원본 데이터 로드
df = pd.read_csv('your_data.csv')

# 필요한 컬럼만 선택하고 이름 변경
df_formatted = df[['사용자ID', '음식ID', '평점', '칼로리', '탄수화물', '단백질', '지방']]
df_formatted.columns = ['user_id', 'food_id', 'rating', 'calories', 'carbs', 'protein', 'fat']

# 저장
df_formatted.to_csv('ratings.csv', index=False)
```

#### 3단계: 모델 학습

```bash
# SVD 방식 (추천, 빠르고 정확)
python collaborative_filtering.py --method svd --data ratings.csv --train

# 출력 예시:
# Cross-validation results:
# RMSE: 0.85 (낮을수록 좋음)
# MAE: 0.65 (낮을수록 좋음)
# 모델 저장: models/recommender_svd.pkl
```

**다른 방식도 시도 가능:**
```bash
# KNN 방식 (사용자 간 유사도 기반)
python collaborative_filtering.py --method knn --data ratings.csv --train

# PyTorch 방식 (딥러닝, 느리지만 복잡한 패턴 학습)
python collaborative_filtering.py --method pytorch --data ratings.csv --train --epochs 50
```

#### 4단계: 추천 받기

```bash
# 특정 사용자에게 추천
python collaborative_filtering.py --method svd --data ratings.csv --recommend-for user_001

# 출력 예시:
# user_001님을 위한 추천 음식:
# 1. 된장찌개 (예상 평점: 4.5)
# 2. 비빔밥 (예상 평점: 4.3)
# 3. 불고기 (예상 평점: 4.1)
```

#### 5단계: 영양 기반 추천

```bash
# 잔여 칼로리, 탄단지 기준 추천
python collaborative_filtering.py --method nutrition \
  --data ratings.csv \
  --user user_001 \
  --remaining-calories 500 \
  --remaining-carbs 50 \
  --remaining-protein 20 \
  --remaining-fat 15

# 출력 예시:
# 영양 기준 추천 음식 (user_001):
# 1. 닭가슴살샐러드 (칼로리: 180, 탄: 15g, 단: 25g, 지: 5g)
# 2. 김치찌개 (칼로리: 120, 탄: 15g, 단: 8g, 지: 5g)
```

#### 6단계: 모델 성능 평가

```bash
# 교차 검증으로 정확도 확인
python collaborative_filtering.py --method svd --data ratings.csv --cross-validate

# 결과 예시:
# Fold 1: RMSE=0.82, MAE=0.63
# Fold 2: RMSE=0.87, MAE=0.67
# Fold 3: RMSE=0.84, MAE=0.65
# Average: RMSE=0.84, MAE=0.65
```

**성능 지표 해석:**
- **RMSE (Root Mean Square Error)**: 예측 오차의 제곱근 평균
  - 0.5 이하: 매우 좋음
  - 0.5-1.0: 양호
  - 1.0 이상: 개선 필요
- **MAE (Mean Absolute Error)**: 예측 오차의 평균
  - 0.5 이하: 매우 좋음
  - 0.5-0.8: 양호
  - 0.8 이상: 개선 필요

### 💡 팁과 트릭

**Q: 추천 정확도를 높이려면?**
1. 더 많은 평점 데이터 수집 (최소 1,000개 이상)
2. 다양한 알고리즘 시도 (SVD, KNN, PyTorch)
3. 하이퍼파라미터 조정

**Q: 신규 사용자에게 어떻게 추천하나요?**
```bash
# 인기 음식 기반 추천 (Cold Start 문제 해결)
python collaborative_filtering.py --method popularity --data ratings.csv

# 영양 정보만으로 추천
python collaborative_filtering.py --method nutrition --data ratings.csv --user new_user_123
```

**Q: 실시간으로 추천하고 싶어요!**
```python
# Flask 서버로 API 제공
# ml_training/INTEGRATION_GUIDE.md 참조

# 간단한 예시
from collaborative_filtering import SurpriseRecommender

recommender = SurpriseRecommender()
recommender.load_model('models/recommender_svd.pkl')

# API 엔드포인트
@app.route('/recommend/<user_id>')
def recommend(user_id):
    recommendations = recommender.get_recommendations(user_id, top_n=5)
    return jsonify(recommendations)
```

---

## 자주 묻는 질문 (FAQ)

### 전체 과정

**Q: 세 가지 모델을 모두 학습해야 하나요?**
- 아니요! 필요한 것만 학습하면 됩니다.
- YOLO만 필요하면 YOLO만 학습하세요.

**Q: 학습 시간은 얼마나 걸리나요?**
| 모델 | CPU | GPU |
|------|-----|-----|
| YOLO v8 | 1-2일 | 4-6시간 |
| EasyOCR | 1-2주 | 2-3일 |
| Collaborative Filtering | 1-5분 | 1-5분 |

**Q: GPU가 꼭 필요한가요?**
- YOLO, EasyOCR: GPU 강력 권장 (Google Colab 무료 GPU 사용 가능)
- Collaborative Filtering: GPU 불필요

### 데이터 관련

**Q: 데이터가 부족해요!**
- YOLO: Data Augmentation 사용 (자동으로 적용됨)
- EasyOCR: 합성 데이터 생성 (`--generate-korean-data`)
- Collaborative Filtering: 샘플 데이터로 테스트 가능

**Q: 한글 라벨이 깨져요!**
```bash
# 인코딩 문제 해결
python script.py 2>&1 | iconv -f UTF-8 -t UTF-8
```

### 오류 해결

**Q: CUDA out of memory 오류**
```bash
# Batch 크기 줄이기
--batch 8  # 또는 4
```

**Q: Import Error 발생**
```bash
# 패키지 재설치
pip install -r requirements.txt --force-reinstall
```

**Q: 학습이 중단됐어요!**
```bash
# 체크포인트에서 재개 (YOLO)
python yolo_training.py --resume runs/train/exp/weights/last.pt

# 새로 시작하려면 그냥 다시 실행
```

### 결과 활용

**Q: 학습된 모델을 어떻게 사용하나요?**
- Flutter 앱 통합: `INTEGRATION_GUIDE.md` 참조
- Python 스크립트: 각 섹션의 "테스트" 부분 참조
- REST API: `INTEGRATION_GUIDE.md`의 서버 예제 참조

**Q: 모델 파일 크기가 너무 커요!**
```bash
# YOLO 모델 경량화
python yolo_training.py --export tflite  # 10MB → 5MB

# EasyOCR 모델 압축
zip -r easyocr_model.zip easyocr_training/trained_models/
```

---

## 도움이 되는 리소스

### 공식 문서
- [YOLO Ultralytics 문서](https://docs.ultralytics.com/)
- [EasyOCR GitHub](https://github.com/JaidedAI/EasyOCR)
- [Scikit-surprise 문서](https://surprise.readthedocs.io/)

### 이 프로젝트의 다른 가이드
- `QUICKSTART.md` - 빠른 시작 가이드
- `TRAINING_GUIDE.md` - 상세 학습 가이드
- `INTEGRATION_GUIDE.md` - Flutter 앱 통합 가이드
- `EASYOCR_TRAINING_GUIDE.md` - EasyOCR 전문 가이드

### 문제 해결
- GitHub Issues: 버그 리포트 및 질문
- `VALIDATION_REPORT.md` - 검증 체크리스트

---

**🎉 학습을 시작할 준비가 되셨나요?**

```bash
# 한 번에 모든 것 테스트하기
cd ml_training
python test_setup.py
python yolo_training.py --data data.yaml --epochs 3 --batch 4
python easyocr_trainer.py --setup-training --output-dir ./test_easyocr
python collaborative_filtering.py --generate-sample-data --output test_ratings.csv
```

행운을 빕니다! 🚀
