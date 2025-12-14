#!/bin/bash
# EasyOCR Training Script with Docker (Final Corrected Version)

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# --- 경로 정의 ---
DATASET_DIR="$SCRIPT_DIR/training_data"
LMDB_OUTPUT_DIR="$SCRIPT_DIR/lmdb_data"
SAVED_MODEL_DIR="$SCRIPT_DIR/saved_models"
CHARSET_FILE="$SCRIPT_DIR/korean_nutrition_charset.txt"
EASYOCR_REPO_DIR="$SCRIPT_DIR/EasyOCR"

# --- 사전 준비 ---
echo "[Step 1] Preparing directories and files..."
mkdir -p "$LMDB_OUTPUT_DIR/train" "$LMDB_OUTPUT_DIR/val"
mkdir -p "$SAVED_MODEL_DIR"

if [ ! -d "$EASYOCR_REPO_DIR" ]; then
    echo "  - Cloning EasyOCR repository for utility scripts..."
    git clone https://github.com/JaidedAI/EasyOCR.git "$EASYOCR_REPO_DIR"
fi
echo "[Step 1] Preparation complete."
echo ""

# --- LMDB 데이터셋 생성 (로컬에서 실행) ---
echo "[Step 2] Creating LMDB datasets locally..."
VENV_PATH="$SCRIPT_DIR/wsl_venv/bin/activate"
if [ -f "$VENV_PATH" ]; then
    source "$VENV_PATH"
    pip show lmdb &> /dev/null || pip install lmdb
fi

echo "  - Creating training LMDB..."
python "$EASYOCR_REPO_DIR/create_lmdb_dataset.py" \
    --gtFile "$DATASET_DIR/train/labels.txt" \
    --inputPath "$DATASET_DIR/train/" \
    --outputPath "$LMDB_OUTPUT_DIR/train"

echo "  - Creating validation LMDB..."
python "$EASYOCR_REPO_DIR/create_lmdb_dataset.py" \
    --gtFile "$DATASET_DIR/val/labels.txt" \
    --inputPath "$DATASET_DIR/val/" \
    --outputPath "$LMDB_OUTPUT_DIR/val"
echo "[Step 2] LMDB creation complete."
echo ""

# --- Docker를 이용한 학습 시작 ---
echo "[Step 3] Starting model training inside Docker container..."

SELECTED_IMAGE="python:3.10-slim"
echo "  - Using base image: $SELECTED_IMAGE"
docker pull "$SELECTED_IMAGE"

RUN_ARGS=(--gpus all --rm
    -v "$LMDB_OUTPUT_DIR":/workspace/data
    -v "$SAVED_MODEL_DIR":/workspace/saved_models
    -v "$CHARSET_FILE":/workspace/charset.txt
    -v "$EASYOCR_REPO_DIR":/workspace/EasyOCR
    -w /workspace/EasyOCR
)

# ✅ 수정: 호환되는 패키지 버전을 설치하고 학습을 실행하는 스크립트
# CUDA 11.8 기반의 PyTorch로 변경하고, 모든 의존성을 한 번에 설치합니다.
EXEC_SCRIPT="
set -e
echo '--- Installing compatible packages ---'
pip install --upgrade pip --no-cache-dir

pip install --no-cache-dir \
    'numpy<2.0' \
    'opencv-python-headless==4.8.1.78' \
    'pandas' \
    'natsort' \
    'nltk' \
    'scipy' \
    'scikit-image' \
    'python-bidi' \
    'PyYAML' \
    'Shapely' \
    'pyclipper' \
    'ninja' \
    'lmdb' \
    'torch==2.0.1+cu118' \
    'torchvision==0.15.2+cu118' \
    --extra-index-url https://download.pytorch.org/whl/cu118

echo '--- Verifying installations ---'
python3 -c \"import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CUDA available: {torch.cuda.is_available()}')\"
python3 -c \"import cv2; print(f'OpenCV version: {cv2.__version__}')\"
python3 -c \"import nltk; print('OK: nltk module successfully imported.')\"

echo '--- Starting training ---'
python3 trainer/train.py \
    --train_data /workspace/data/train \
    --valid_data /workspace/data/val \
    --experiment_name \"korean_nutrition_model\" \
    --saved_model /workspace/saved_models/korean_nutrition_model.pth \
    --character_list /workspace/charset.txt \
    --Transformation TPS \
    --FeatureExtraction ResNet \
    --SequenceModeling BiLSTM \
    --Prediction Attn \
    --num_iter 500 \
    --batch_size 4 \
    --valInterval 100 \
    --workers 0 \
    --imgH 64 \
    --imgW 200 \
    --rgb
"

# Docker 컨테이너 실행
docker run "${RUN_ARGS[@]}" "$SELECTED_IMAGE" bash -c "$EXEC_SCRIPT"

echo "[Step 3] Training finished."
echo ""
echo "========================================================"
echo "Script finished. Trained model should be in: $SAVED_MODEL_DIR"
echo "========================================================"
