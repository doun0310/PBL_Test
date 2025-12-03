# Quick Start Guide - ML Training Setup

이 가이드는 ML 학습 환경을 빠르게 설정하고 검증하는 방법을 설명합니다.

## 🚀 빠른 시작

### 1. 환경 설정 및 검증

```bash
# ml_training 디렉토리로 이동
cd ml_training

# 설정 검증 (의존성 설치 전)
python test_setup.py

# 의존성 설치
pip install -r requirements.txt

# 설정 재검증 (의존성 설치 후)
python test_setup.py
```

### 2. 데이터셋 다운로드

#### Kaggle 설정
```bash
# Kaggle API 설치 (이미 requirements.txt에 포함됨)
pip install kaggle

# Kaggle 인증 설정
# 1. https://www.kaggle.com/settings/account 접속
# 2. "Create New API Token" 클릭 -> kaggle.json 다운로드
# 3. kaggle.json을 ~/.kaggle/ 디렉토리에 저장
mkdir -p ~/.kaggle
mv ~/Downloads/kaggle.json ~/.kaggle/
chmod 600 ~/.kaggle/kaggle.json
```

#### 자동 다운로드
```bash
# 모든 데이터셋 다운로드
python download_datasets.py --download-all

# 또는 개별 다운로드
python download_datasets.py --download-food11
python download_datasets.py --download-korean-food
python download_datasets.py --download-nutrition-ocr
python download_datasets.py --download-korean-ocr
```

### 3. 학습 시작

#### YOLO v8 학습
```bash
# 기본 학습 (100 epochs)
python yolo_training.py --data data.yaml --epochs 100 --batch 16

# TFLite로 내보내기 (모바일 배포용)
python yolo_training.py --data data.yaml --export tflite
```

#### EasyOCR 데이터 준비
```bash
# 한글 데이터 생성 (1000 샘플)
python easyocr_trainer.py --generate-korean-data 1000

# 샘플 구조 생성
python easyocr_trainer.py --create-sample

# 성분표 이미지 추론
python easyocr_trainer.py --infer path/to/nutrition_label.jpg
```

#### Collaborative Filtering
```bash
# 음식 추천 (잔여 영양소 기반)
python collaborative_filtering.py --remaining-cal 500 --remaining-carb 50 \
    --remaining-protein 30 --remaining-fat 20
```

---

## 📋 필수 확인 사항

### ✅ 파일 검증
test_setup.py를 실행하여 다음 항목들을 확인하세요:

- [x] 모든 Python 스크립트 (.py 파일)
- [x] 설정 파일 (data.yaml, requirements.txt)
- [x] 문서 파일 (README.md, TRAINING_GUIDE.md)
- [x] Python 문법 검증
- [x] YAML 형식 검증

### 📦 의존성 확인
```bash
python -c "import torch, ultralytics, easyocr, sklearn; print('✓ All dependencies installed')"
```

---

## 🔧 문제 해결

### ImportError: No module named 'xxx'
```bash
# 의존성 재설치
pip install -r requirements.txt --upgrade
```

### CUDA/GPU 관련 오류
```bash
# CPU 모드로 학습 (GPU 없이)
python yolo_training.py --data data.yaml --device cpu
python easyocr_trainer.py --infer image.jpg --no-gpu
```

### 데이터셋 다운로드 실패
```bash
# Kaggle 인증 확인
kaggle datasets list

# 수동 다운로드
# 1. Kaggle 웹사이트에서 직접 다운로드
# 2. datasets/ 디렉토리에 압축 해제
```

### 메모리 부족 오류
```bash
# 배치 크기 줄이기
python yolo_training.py --data data.yaml --batch 8  # 기본 16에서 8로

# 이미지 크기 줄이기
python yolo_training.py --data data.yaml --imgsz 416  # 기본 640에서 416으로
```

---

## 📚 추가 리소스

| 문서 | 설명 |
|------|------|
| `README.md` | 데이터셋 소스 및 다운로드 정보 |
| `TRAINING_GUIDE.md` | 단계별 학습 가이드 (한국어) |
| `test_setup.py` | 설정 검증 스크립트 |

### 스크립트 도움말
```bash
python yolo_training.py --help
python easyocr_trainer.py --help
python collaborative_filtering.py --help
python download_datasets.py --help
```

---

## ✨ 다음 단계

1. **데이터 수집 완료 후**: 데이터셋을 `datasets/` 디렉토리에 정리
2. **data.yaml 수정**: 실제 데이터셋 경로 및 클래스 설정
3. **학습 시작**: 위의 학습 명령어 실행
4. **모델 검증**: 학습된 모델의 성능 평가
5. **모델 배포**: TFLite/ONNX로 내보내기

---

## 🆘 지원

문제가 발생하면:
1. `test_setup.py`를 실행하여 환경 확인
2. 에러 메시지 전체 복사
3. 사용한 명령어와 함께 보고

Happy Training! 🎉
