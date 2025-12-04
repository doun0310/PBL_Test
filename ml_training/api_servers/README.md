# ML Model REST API Servers

Production-ready REST API servers for EasyOCR and Collaborative Filtering models.

## 서버 구성 (Server Structure)

```
api_servers/
├── easyocr_server.py           # EasyOCR 영양 성분표 인식 API
├── recommendation_server.py     # 협업 필터링 추천 API
├── requirements.txt            # 서버 의존성
└── README.md                   # 이 파일
```

## 설치 (Installation)

```bash
cd api_servers

# 의존성 설치
pip install -r requirements.txt

# 또는 전체 ml_training requirements 사용
pip install -r ../requirements.txt
```

## 1. EasyOCR 서버 (Nutrition Label OCR)

### 기능 (Features)
- ✅ 영양 성분표 이미지에서 텍스트 추출
- ✅ 한글/영어 OCR 지원
- ✅ 자동 오류 수정 (브랜스→트랜스, 탄백질→단백질 등)
- ✅ 칼로리, 탄단지 자동 파싱
- ✅ GPU/CPU 자동 전환
- ✅ CORS 활성화 (Flutter 앱 연동)

### 실행 (Running)

```bash
# 기본 실행 (GPU 자동 사용)
python easyocr_server.py

# 포트 변경
python easyocr_server.py --port 5000

# CPU 강제 사용
python easyocr_server.py --gpu false

# 디버그 모드
python easyocr_server.py --debug
```

### API 엔드포인트 (Endpoints)

#### Health Check
```bash
GET /health

Response:
{
  "status": "healthy",
  "service": "EasyOCR Nutrition Label API",
  "model_loaded": true
}
```

#### OCR 처리
```bash
POST /ocr
Content-Type: multipart/form-data

Parameters:
  - image: 이미지 파일 (PNG, JPG, JPEG, GIF, BMP)
  - extract_nutrition: Boolean (선택, 기본값 true)
```

#### 영양 정보 추출
```bash
POST /extract_nutrition
Content-Type: multipart/form-data

Parameters:
  - image: 이미지 파일
```

### 사용 예제

#### Python
```python
import requests

with open('nutrition_label.jpg', 'rb') as f:
    files = {'image': f}
    response = requests.post('http://localhost:5000/extract_nutrition', files=files)
    result = response.json()
    
    if result['success']:
        print(f"Calories: {result['nutrition']['calories']} kcal")
```

#### Flutter
```dart
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> extractNutrition(File imageFile) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://your-server:5000/extract_nutrition'),
  );
  
  request.files.add(
    await http.MultipartFile.fromPath('image', imageFile.path),
  );
  
  var response = await request.send();
  var responseData = await response.stream.bytesToString();
  return json.decode(responseData);
}
```

## 2. 추천 서버 (Collaborative Filtering)

### 기능 (Features)
- ✅ 협업 필터링 기반 음식 추천
- ✅ 영양 성분 기반 추천
- ✅ 인기 음식 추천
- ✅ 사용자 평가 저장

### 실행 (Running)

```bash
# 기본 실행
python recommendation_server.py

# 포트 변경
python recommendation_server.py --port 5001
```

### API 엔드포인트 (Endpoints)

#### 영양 기반 추천
```bash
POST /recommend/nutrition
Content-Type: application/json

{
  "target_calories": 500,
  "target_carbs": 50,
  "target_protein": 30,
  "target_fat": 15
}
```

#### 협업 필터링 추천
```bash
POST /recommend/collaborative
Content-Type: application/json

{
  "user_id": "user_001",
  "n_recommendations": 10
}
```

#### 인기 추천
```bash
GET /recommend/popular?n_recommendations=10
```

### 사용 예제

#### Python
```python
import requests

data = {
    "target_calories": 500,
    "target_carbs": 50,
    "target_protein": 30,
    "target_fat": 15
}

response = requests.post(
    'http://localhost:5001/recommend/nutrition',
    json=data
)

recommendations = response.json()['recommendations']
```

#### Flutter
```dart
Future<List<dynamic>> getNutritionRecommendations() async {
  final response = await http.post(
    Uri.parse('http://your-server:5001/recommend/nutrition'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'target_calories': 500,
      'target_carbs': 50,
      'target_protein': 30,
      'target_fat': 15,
    }),
  );
  
  final data = json.decode(response.body);
  return data['recommendations'];
}
```

## 프로덕션 배포 (Production)

### Gunicorn 사용

```bash
# EasyOCR 서버
gunicorn -w 4 -b 0.0.0.0:5000 --timeout 120 easyocr_server:app

# 추천 서버
gunicorn -w 4 -b 0.0.0.0:5001 recommendation_server:app
```

### Docker 배포

```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY *.py .

CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "--timeout", "120", "easyocr_server:app"]
```

## 문제 해결 (Troubleshooting)

### EasyOCR
- **"easyocr not installed"**: `pip install easyocr`
- **CUDA out of memory**: CPU 모드 사용 `--gpu false`

### 추천 시스템
- **빈 추천 결과**: 사용자 평가 데이터 추가 필요

## 라이선스

MIT License
