# D(iet) 101 - 식단 관리 앱

Flutter와 Dart를 이용한 식단 관리 모바일 애플리케이션입니다.
`JangMinSeong/Diet101` Kotlin 기반 앱을 Flutter로 재구현한 프로젝트입니다.

## 📱 주요 기능

### 1. 사용자 인증
- 회원가입 및 로그인
- JWT 기반 인증
- 사용자 프로필 관리
- 알레르기 정보 관리

### 2. 식단 조회
- 일별 식단 정보 표시 (아침, 점심, 저녁)
- 영양 정보 표시 (칼로리, 단백질, 탄수화물, 지방)
- 알레르기 정보 표시 및 하이라이트
- 날짜 선택 기능
- 새로고침으로 최신 정보 업데이트

### 3. 음식 사진 인식 (YOLO 기반)
- 카메라로 음식 사진 촬영
- 갤러리에서 음식 사진 선택
- AI를 통한 음식 자동 인식
- 인식된 음식의 영양 정보 표시
- 식단에 바로 추가 가능

### 4. 영양성분표 OCR 스캔
- 가공 식품 영양성분표 촬영
- OCR을 통한 텍스트 자동 추출
- 영양소 정보 자동 입력
- 데이터 저장 및 관리

### 5. 섭취 가능 음식 추천 (Collaborative Filtering)
- 남은 끼니 수 및 목표 칼로리 설정
- 개인 맞춤형 음식 추천
- 남은 영양소 목표 표시
- 알레르기 고려한 추천

### 6. 주별/월별 식단 분석
- 주간/월간 총 칼로리 통계
- 영양소 비율 파이 차트
- 일별 칼로리 막대 그래프
- 자주 먹은 음식 TOP 5 랭킹

## 📂 프로젝트 구조

```
lib/
├── main.dart                           # 앱 진입점
├── models/                             # 데이터 모델
│   ├── meal.dart                       # 식단 데이터 모델
│   ├── user.dart                       # 사용자 데이터 모델
│   ├── nutrition_label.dart            # 영양성분표 모델
│   └── meal_analytics.dart             # 식단 분석 모델
├── services/                           # 서비스 레이어
│   ├── auth_service.dart               # 인증 서비스
│   ├── meal_service.dart               # 식단 서비스
│   ├── food_recognition_service.dart   # 음식 인식 AI 서비스
│   ├── ocr_service.dart                # OCR 서비스
│   ├── recommendation_service.dart     # 음식 추천 서비스
│   └── analytics_service.dart          # 분석 서비스
└── screens/                            # UI 화면
    ├── login_screen.dart               # 로그인 화면
    ├── register_screen.dart            # 회원가입 화면
    ├── home_screen.dart                # 홈 화면 (식단 표시)
    ├── profile_screen.dart             # 프로필 화면
    ├── food_recognition_screen.dart    # 음식 인식 화면
    ├── nutrition_label_scan_screen.dart # 성분표 스캔 화면
    ├── recommendation_screen.dart      # 음식 추천 화면
    └── analytics_screen.dart           # 식단 분석 화면
```

## 🚀 설치 및 실행

### 1. Flutter 설치
Flutter SDK를 설치해주세요: https://flutter.dev/docs/get-started/install

### 2. 의존성 설치
```bash
flutter pub get
```

### 3. 백엔드 서버 설정
Node.js 백엔드 서버 및 AI 서버를 실행해야 합니다.
각 서비스 파일의 `baseUrl`을 실제 서버 주소로 변경하세요.

**개발 환경 주소:**
- Android 에뮬레이터: `http://10.0.2.2:3000/api`
- iOS 시뮬레이터: `http://localhost:3000/api`
- 실제 디바이스: `http://your-local-ip:3000/api`

### 4. 앱 실행
```bash
# Android
flutter run

# iOS (macOS에서만)
flutter run

# 특정 디바이스 선택
flutter devices
flutter run -d device_id
```

## 🔌 백엔드 API 명세

### 인증 API

#### 로그인
```
POST /api/auth/login
Content-Type: application/json

Request:
{
  "email": "user@example.com",
  "password": "password123"
}

Response:
{
  "token": "jwt_token_here",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "홍길동",
    "allergies": ["우유", "계란"],
    "preferences": []
  }
}
```

#### 회원가입
```
POST /api/auth/register
Content-Type: application/json

Request:
{
  "email": "user@example.com",
  "password": "password123",
  "name": "홍길동",
  "allergies": ["우유", "계란"],
  "preferences": []
}

Response:
{
  "message": "회원가입이 완료되었습니다."
}
```

### 식단 API

#### 날짜별 식단 조회
```
GET /api/meals?date=2025-10-28
Authorization: Bearer {token}

Response:
{
  "date": "2025-10-28",
  "breakfast": [...],
  "lunch": [...],
  "dinner": [...]
}
```

### AI API

#### 음식 인식
```
POST /api/ai/recognize-food
Authorization: Bearer {token}
Content-Type: multipart/form-data

Request:
- image: (binary file)

Response:
{
  "recognizedFoods": [
    {
      "name": "삼겹살",
      "calories": 518,
      "protein": 17,
      "carbs": 0,
      "fat": 50,
      "allergens": ["돼지고기"]
    }
  ]
}
```

#### 영양성분표 OCR
```
POST /api/ai/ocr-nutrition
Authorization: Bearer {token}
Content-Type: multipart/form-data

Request:
- image: (binary file)

Response:
{
  "productName": "제품명",
  "calories": 250,
  "carbohydrate": 35,
  "sugars": 8,
  "protein": 6,
  "fat": 9,
  "saturatedFat": 3,
  "transFat": 0,
  "cholesterol": 15,
  "sodium": 480
}
```

#### 음식 추천
```
POST /api/ai/recommend
Authorization: Bearer {token}
Content-Type: application/json

Request:
{
  "remainingMeals": 3,
  "targetCaloriesPerMeal": 500
}

Response:
{
  "recommendations": [...]
}
```

### 분석 API

#### 주간 분석
```
GET /api/analytics/weekly
Authorization: Bearer {token}

Response:
{
  "totalCalories": 14500,
  "totalProtein": 580,
  "totalCarbs": 1450,
  "totalFat": 435,
  "dailyCalories": {...},
  "topFoods": [...]
}
```

#### 월간 분석
```
GET /api/analytics/monthly
Authorization: Bearer {token}
```

## 📦 필요한 패키지

- **flutter**: SDK
- **http** (^1.1.0): REST API 통신
- **shared_preferences** (^2.2.2): 로컬 데이터 저장 (JWT 토큰)
- **intl** (^0.20.2): 날짜 포맷팅 및 한국어 지원
- **cupertino_icons** (^1.0.2): iOS 스타일 아이콘
- **image_picker** (^1.0.4): 이미지 선택 기능
- **camera** (^0.10.5+5): 카메라 기능
- **fl_chart** (^0.66.0): 차트 표시
- **path_provider** (^2.1.1): 파일 경로 처리
- **permission_handler** (^11.1.0): 권한 관리

## 🎨 주요 기술

- **언어**: Dart
- **프레임워크**: Flutter
- **아키텍처**: MVC 패턴
- **상태 관리**: StatefulWidget + setState
- **네트워킹**: http 패키지
- **로컬 저장소**: shared_preferences
- **UI**: Material Design
- **차트**: fl_chart
- **AI 통합**: YOLO v8 (음식 인식), EasyOCR (영양성분표)
- **추천 알고리즘**: Collaborative Filtering

## 🔧 문제 해결

### 의존성 오류
```bash
flutter clean
flutter pub get
```

### 권한 설정

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
```

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>NSCameraUsageDescription</key>
<string>음식 사진을 촬영하고 영양성분표를 스캔하기 위해 카메라 접근 권한이 필요합니다.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>갤러리에서 음식 사진을 선택하기 위해 사진 라이브러리 접근 권한이 필요합니다.</string>
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 📈 향후 개선 사항

1. **상태 관리**: Provider, Riverpod, Bloc 도입
2. **오프라인 지원**: SQLite, Hive 데이터베이스
3. **푸시 알림**: Firebase Cloud Messaging
4. **검색 기능**: 식단 검색 및 필터링
5. **즐겨찾기**: 선호 식단 저장
6. **영양 목표**: 일일 권장 섭취량 설정 및 추적
7. **다크 모드**: 테마 전환 기능
8. **소셜 기능**: 식단 공유 및 커뮤니티
9. **운동 통합**: 운동 칼로리 소모 추적
10. **다국어 지원**: 영어, 일본어 등

## 🌟 Diet101 참조 기능

이 프로젝트는 `JangMinSeong/Diet101`의 다음 기능들을 Flutter로 재구현했습니다:

- ✅ YOLO v8 기반 음식 인식
- ✅ EasyOCR 기반 영양성분표 인식
- ✅ Collaborative Filtering 음식 추천
- ✅ 주간/월간 식단 분석 및 차트
- ✅ 알레르기 관리
- ✅ JWT 인증
- ✅ 식단 히스토리

## 📄 라이선스

이 프로젝트는 교육 목적으로 개발되었습니다.

## 👥 개발팀

**원본 Diet101 프로젝트 (Kotlin/Android):**
- 김보근, 김동영, 박사랑, 이주미, 장민성, 조현우

**Flutter 재구현:**
- 이도은
- 강성민

