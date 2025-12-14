sh
sh
#!/bin/bash
# LMDB Creation Script for EasyOCR Training

# 스크립트가 위치한 디렉토리의 절대 경로를 가져옵니다.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# --- 경로 정의 ---
DATASET_DIR="$SCRIPT_DIR/training_data"
CREATE_LMDB_SCRIPT="$SCRIPT_DIR/EasyOCR/create_lmdb_dataset.py"
OUTPUT_DIR="$SCRIPT_DIR/lmdb_data"
TRAIN_GT_FILE="$DATASET_DIR/train/labels.txt"
VAL_GT_FILE="$DATASET_DIR/val/labels.txt"

# --- 가상 환경 활성화 ---
VENV_PATH="$SCRIPT_DIR/wsl_venv/bin/activate"
if [ ! -f "$VENV_PATH" ]; then
    echo "ERROR: Virtual environment not found at $VENV_PATH"
    exit 1
fi
source "$VENV_PATH"

echo "========================================================"
echo "Starting LMDB Dataset Creation..."
echo "Python version being used: $(python --version)"
echo "========================================================"

# 1. 필수 패키지 설치
echo "[Step 1] Installing 'lmdb' package..."
python -m pip install lmdb
echo "[Step 1] Installation complete."
echo ""

# 2. 라벨 파일 존재 여부 검증
echo "[Step 2] Verifying label files (labels.txt)..."
if [ ! -f "$TRAIN_GT_FILE" ]; then
    echo "  - ERROR: Training label file not found at: $TRAIN_GT_FILE"
    exit 1
fi
if [ ! -f "$VAL_GT_FILE" ]; then
    echo "  - ERROR: Validation label file not found at: $VAL_GT_FILE"
    exit 1
fi
echo "  - OK: Both train and val label files found."
echo "[Step 2] Verification complete."
echo ""

# 3. 라벨 파일 내용 검증
echo "[Step 3] Verifying content of label files..."
train_tab_lines=$(grep -P '\t' "$TRAIN_GT_FILE" | wc -l)
train_total_lines=$(grep -v '^\s*$' "$TRAIN_GT_FILE" | wc -l) # 비어있지 않은 라인만 계산

if [ "$train_tab_lines" -ne "$train_total_lines" ]; then
    echo "  - ERROR in '$TRAIN_GT_FILE': Not all lines contain a Tab separator."
    exit 1
fi
echo "  - OK: Training label file content seems valid."

val_tab_lines=$(grep -P '\t' "$VAL_GT_FILE" | wc -l)
val_total_lines=$(grep -v '^\s*$' "$VAL_GT_FILE" | wc -l) # 비어있지 않은 라인만 계산

if [ "$val_tab_lines" -ne "$val_total_lines" ]; then
    echo "  - ERROR in '$VAL_GT_FILE': Not all lines contain a Tab separator."
    exit 1
fi
echo "  - OK: Validation label file content seems valid."
echo "[Step 3] Content verification complete."
echo ""

# 4. 기존 LMDB 데이터 삭제
echo "[Step 4] Removing old LMDB directories..."
rm -rf "$OUTPUT_DIR/train"
rm -rf "$OUTPUT_DIR/val"
echo "[Step 4] Removal complete."
echo ""

# 5. LMDB 생성 실행
echo "[Step 5] Creating new LMDB datasets..."
# ✅ 수정된 부분: --data_dir를 --inputPath로 변경
python "$CREATE_LMDB_SCRIPT" \
    --gtFile "$TRAIN_GT_FILE" \
    --inputPath "${TRAIN_GT_FILE%/*}/" \
    --outputPath "$OUTPUT_DIR/train"

python "$CREATE_LMDB_SCRIPT" \
    --gtFile "$VAL_GT_FILE" \
    --inputPath "${VAL_GT_FILE%/*}/" \
    --outputPath "$OUTPUT_DIR/val"
echo "[Step 5] LMDB creation process finished."
echo ""

# 6. 데이터셋 검증
echo "[Step 6] Verifying created datasets..."
# ... (검증 스크립트는 이전과 동일) ...
VERIFY_SCRIPT="
import lmdb, sys
try:
    env = lmdb.open(sys.argv[1], readonly=True)
    with env.begin() as txn:
        num_samples = txn.get(b'num-samples')
        if num_samples: print(f'OK: Dataset at {sys.argv[1]} contains {num_samples.decode()} samples.')
        else: print(f'ERROR: Dataset at {sys.argv[1]} is empty or invalid.')
except Exception as e: print(f'ERROR: Failed to open dataset at {sys.argv[1]}. Reason: {e}')"
echo "--- Checking training dataset ---"
python -c "$VERIFY_SCRIPT" "$OUTPUT_DIR/train"
echo "--- Checking validation dataset ---"
python -c "$VERIFY_SCRIPT" "$OUTPUT_DIR/val"
echo "[Step 6] Verification complete."
echo ""

echo "========================================================"
echo "Script finished. LMDB datasets are ready at: $OUTPUT_DIR"
echo "========================================================"

deactivate