# prepare_data.py

import pandas as pd
import os

# --- 설정 부분 (이곳을 수정하세요!) ---

# 1. 변환할 원본 데이터 파일 경로를 지정합니다.
#    여기서는 프로젝트에 포함된 샘플 평점 데이터를 사용합니다.
ORIGINAL_DATA_FILE = 'sample_ratings.csv'

# 2. 최종적으로 생성될 표준 데이터 파일 이름입니다.
OUTPUT_FILE = 'ratings.csv'

# ------------------------------------


def main():
    """
    원본 데이터를 읽어 추천 시스템이 사용할 수 있는 ratings.csv 형식으로 변환합니다.
    (이 경우, sample_ratings.csv를 ratings.csv로 복사하는 역할을 합니다.)
    """
    print(f"'{ORIGINAL_DATA_FILE}' 파일을 읽어 '{OUTPUT_FILE}' 파일을 생성합니다...")

    # 파일 존재 여부 확인
    if not os.path.exists(ORIGINAL_DATA_FILE):
        print(f"[오류] 원본 데이터 파일 '{ORIGINAL_DATA_FILE}'을 찾을 수 없습니다.")
        print("파일 이름과 경로를 다시 확인해주세요.")
        return

    # 원본 데이터 로드
    try:
        df = pd.read_csv(ORIGINAL_DATA_FILE)
    except Exception as e:
        print(f"[오류] 파일을 읽는 중 문제가 발생했습니다: {e}")
        return

    # 최종 결과물을 'ratings.csv' 파일로 저장
    # sample_ratings.csv는 이미 필요한 형식이므로, 그대로 저장합니다.
    df.to_csv(OUTPUT_FILE, index=False)

    print("-" * 30)
    print(f"✅ 변환 완료! '{OUTPUT_FILE}' 파일이 성공적으로 생성되었습니다.")
    print("이제 '3단계: 모델 학습'을 진행할 수 있습니다.")
    print("-" * 30)


if __name__ == "__main__":
    main()
