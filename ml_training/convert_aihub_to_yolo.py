"""
AI Hub 데이터셋 변환 스크립트 (YOLO 형식)

AI Hub의 '건강관리를 위한 음식 이미지' 데이터셋을 
YOLO 학습에 필요한 형식으로 변환합니다.

Usage:
    python convert_aihub_to_yolo.py --input datasets/aihub_raw --output datasets/korean_food
    python convert_aihub_to_yolo.py --input datasets/aihub_raw --output datasets/korean_food --max-classes 154
"""

import argparse
import json
import os
import random
import shutil
from collections import Counter
from pathlib import Path
from typing import Dict, List, Tuple


def load_annotation(json_path: Path) -> dict:
    """JSON 어노테이션 파일 로드"""
    with open(json_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def get_all_categories(annotation_dir: Path) -> Dict[str, int]:
    """모든 카테고리와 빈도수 수집"""
    category_counts = Counter()
    
    for json_file in annotation_dir.glob("**/*.json"):
        try:
            data = load_annotation(json_file)
            annotations = data.get('annotations', [])
            
            for ann in annotations:
                category = ann.get('category_name') or ann.get('category_id')
                if category:
                    category_counts[str(category)] += 1
        except Exception as e:
            print(f"Warning: Failed to process {json_file}: {e}")
    
    return dict(category_counts)


def select_top_classes(category_counts: Dict[str, int], max_classes: int) -> List[str]:
    """가장 많이 등장하는 클래스 선택"""
    sorted_categories = sorted(category_counts.items(), key=lambda x: x[1], reverse=True)
    selected = [cat for cat, count in sorted_categories[:max_classes]]
    return selected


def convert_bbox_to_yolo(bbox: List[float], img_width: int, img_height: int) -> Tuple[float, float, float, float]:
    """
    바운딩 박스를 YOLO 형식으로 변환
    
    Input: [x, y, width, height] (픽셀 좌표)
    Output: (center_x, center_y, width, height) (정규화된 좌표 0-1)
    """
    x, y, w, h = bbox
    
    center_x = (x + w / 2) / img_width
    center_y = (y + h / 2) / img_height
    norm_w = w / img_width
    norm_h = h / img_height
    
    # 범위 클리핑
    center_x = max(0, min(1, center_x))
    center_y = max(0, min(1, center_y))
    norm_w = max(0, min(1, norm_w))
    norm_h = max(0, min(1, norm_h))
    
    return center_x, center_y, norm_w, norm_h


def process_dataset(
    input_dir: Path,
    output_dir: Path,
    selected_classes: List[str],
    train_ratio: float = 0.8
):
    """데이터셋 변환 처리"""
    
    # 클래스 매핑 생성
    class_to_idx = {cls: idx for idx, cls in enumerate(selected_classes)}
    
    # 출력 디렉토리 생성
    dirs = {
        'images_train': output_dir / "images" / "train",
        'images_val': output_dir / "images" / "val",
        'labels_train': output_dir / "labels" / "train",
        'labels_val': output_dir / "labels" / "val",
    }
    for d in dirs.values():
        d.mkdir(parents=True, exist_ok=True)
    
    # 어노테이션 디렉토리 찾기
    annotation_dir = None
    for possible_dir in ['annotations', 'Annotations', 'labels', 'Labels', '라벨링데이터']:
        if (input_dir / possible_dir).exists():
            annotation_dir = input_dir / possible_dir
            break
    
    if annotation_dir is None:
        # JSON 파일이 있는 디렉토리 찾기
        for json_file in input_dir.rglob("*.json"):
            annotation_dir = json_file.parent
            break
    
    if annotation_dir is None:
        raise FileNotFoundError(f"어노테이션 디렉토리를 찾을 수 없습니다: {input_dir}")
    
    # 이미지 디렉토리 찾기
    image_dir = None
    for possible_dir in ['images', 'Images', '원천데이터']:
        if (input_dir / possible_dir).exists():
            image_dir = input_dir / possible_dir
            break
    
    if image_dir is None:
        image_dir = input_dir
    
    # 변환 통계
    stats = {
        'processed': 0,
        'skipped': 0,
        'train': 0,
        'val': 0,
        'labels_created': 0
    }
    
    print(f"어노테이션 디렉토리: {annotation_dir}")
    print(f"이미지 디렉토리: {image_dir}")
    print(f"선택된 클래스 수: {len(selected_classes)}")
    print()
    
    json_files = list(annotation_dir.rglob("*.json"))
    total = len(json_files)
    
    for idx, json_file in enumerate(json_files):
        if (idx + 1) % 1000 == 0:
            print(f"진행: {idx + 1}/{total}")
        
        try:
            data = load_annotation(json_file)
            
            # 이미지 정보 추출
            images_info = data.get('images', [])
            if not images_info:
                stats['skipped'] += 1
                continue
            
            image_info = images_info[0] if isinstance(images_info, list) else images_info
            image_filename = image_info.get('file_name', '')
            img_width = image_info.get('width', 640)
            img_height = image_info.get('height', 640)
            
            # 어노테이션 처리
            annotations = data.get('annotations', [])
            yolo_labels = []
            
            for ann in annotations:
                category = str(ann.get('category_name') or ann.get('category_id', ''))
                
                if category not in class_to_idx:
                    continue
                
                class_idx = class_to_idx[category]
                bbox = ann.get('bbox', [0, 0, 0, 0])
                
                if len(bbox) != 4 or all(v == 0 for v in bbox):
                    continue
                
                cx, cy, w, h = convert_bbox_to_yolo(bbox, img_width, img_height)
                yolo_labels.append(f"{class_idx} {cx:.6f} {cy:.6f} {w:.6f} {h:.6f}")
            
            if not yolo_labels:
                stats['skipped'] += 1
                continue
            
            # 이미지 파일 찾기
            src_image = None
            for ext in ['.jpg', '.jpeg', '.png', '.JPG', '.JPEG', '.PNG']:
                possible_path = image_dir / (Path(image_filename).stem + ext)
                if possible_path.exists():
                    src_image = possible_path
                    break
                # 서브디렉토리 검색
                for found in image_dir.rglob(image_filename):
                    src_image = found
                    break
                if src_image:
                    break
            
            if src_image is None or not src_image.exists():
                stats['skipped'] += 1
                continue
            
            # Train/Val 분할
            is_train = random.random() < train_ratio
            
            # 파일 복사 및 레이블 저장
            dst_image_dir = dirs['images_train'] if is_train else dirs['images_val']
            dst_label_dir = dirs['labels_train'] if is_train else dirs['labels_val']
            
            dst_image = dst_image_dir / src_image.name
            dst_label = dst_label_dir / (src_image.stem + ".txt")
            
            shutil.copy(src_image, dst_image)
            with open(dst_label, 'w') as f:
                f.write('\n'.join(yolo_labels))
            
            stats['processed'] += 1
            stats['train' if is_train else 'val'] += 1
            stats['labels_created'] += len(yolo_labels)
            
        except Exception as e:
            print(f"Error processing {json_file}: {e}")
            stats['skipped'] += 1
    
    # 클래스 파일 저장
    with open(output_dir / "classes.txt", 'w', encoding='utf-8') as f:
        for cls in selected_classes:
            f.write(f"{cls}\n")
    
    # data.yaml 생성
    yaml_content = f"""# YOLO 데이터셋 설정 (자동 생성)
path: {output_dir.absolute()}
train: images/train
val: images/val

nc: {len(selected_classes)}

names:
"""
    for idx, cls in enumerate(selected_classes):
        yaml_content += f"  {idx}: {cls}\n"
    
    with open(output_dir / "data.yaml", 'w', encoding='utf-8') as f:
        f.write(yaml_content)
    
    return stats


def main():
    parser = argparse.ArgumentParser(
        description="AI Hub 음식 이미지 데이터를 YOLO 형식으로 변환"
    )
    
    parser.add_argument(
        "--input", "-i",
        type=str,
        required=True,
        help="AI Hub 데이터셋 입력 디렉토리"
    )
    parser.add_argument(
        "--output", "-o",
        type=str,
        required=True,
        help="YOLO 형식 출력 디렉토리"
    )
    parser.add_argument(
        "--max-classes",
        type=int,
        default=154,
        help="최대 클래스 수 (기본: 154)"
    )
    parser.add_argument(
        "--train-ratio",
        type=float,
        default=0.8,
        help="학습 데이터 비율 (기본: 0.8)"
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="랜덤 시드 (기본: 42)"
    )
    
    args = parser.parse_args()
    
    random.seed(args.seed)
    
    input_dir = Path(args.input)
    output_dir = Path(args.output)
    
    if not input_dir.exists():
        print(f"Error: 입력 디렉토리가 존재하지 않습니다: {input_dir}")
        return
    
    print("=" * 60)
    print("AI Hub → YOLO 데이터 변환")
    print("=" * 60)
    print(f"입력: {input_dir}")
    print(f"출력: {output_dir}")
    print(f"최대 클래스: {args.max_classes}")
    print(f"학습 비율: {args.train_ratio}")
    print()
    
    # 1. 카테고리 분석
    print("1. 카테고리 분석 중...")
    annotation_dir = None
    for possible_dir in ['annotations', 'Annotations', 'labels', 'Labels', '라벨링데이터']:
        if (input_dir / possible_dir).exists():
            annotation_dir = input_dir / possible_dir
            break
    if annotation_dir is None:
        annotation_dir = input_dir
    
    category_counts = get_all_categories(annotation_dir)
    print(f"   발견된 카테고리: {len(category_counts)}개")
    
    # 2. 상위 클래스 선택
    print(f"\n2. 상위 {args.max_classes}개 클래스 선택...")
    selected_classes = select_top_classes(category_counts, args.max_classes)
    print(f"   선택된 클래스: {len(selected_classes)}개")
    
    # 상위 10개 클래스 표시
    print("   상위 10개 클래스:")
    for cls in selected_classes[:10]:
        print(f"      - {cls}: {category_counts[cls]}개")
    
    # 3. 데이터 변환
    print("\n3. 데이터 변환 중...")
    stats = process_dataset(
        input_dir=input_dir,
        output_dir=output_dir,
        selected_classes=selected_classes,
        train_ratio=args.train_ratio
    )
    
    # 결과 출력
    print("\n" + "=" * 60)
    print("변환 완료!")
    print("=" * 60)
    print(f"처리된 이미지: {stats['processed']:,}개")
    print(f"  - 학습용: {stats['train']:,}개")
    print(f"  - 검증용: {stats['val']:,}개")
    print(f"건너뛴 이미지: {stats['skipped']:,}개")
    print(f"생성된 레이블: {stats['labels_created']:,}개")
    print()
    print(f"출력 디렉토리: {output_dir}")
    print(f"data.yaml: {output_dir / 'data.yaml'}")
    print(f"classes.txt: {output_dir / 'classes.txt'}")


if __name__ == "__main__":
    main()
