# 식단 관리 앱 (Meal Management App)

Flutter와 Dart를 이용한 학교 식단 관리 모바일 애플리케이션입니다.

## 📱 기능

### 1. 사용자 인증
- 회원가입 및 로그인
- JWT 기반 인증
- 사용자 프로필 관리

### 2. 식단 조회
- 일별 식단 정보 표시 (아침, 점심, 저녁)
- 영양 정보 표시 (칼로리, 단백질, 탄수화물, 지방)
- 알레르기 정보 표시
- 날짜 선택 기능

### 3. 알레르기 관리
- 개인별 알레르기 정보 등록
- 알레르기 성분이 포함된 식단 하이라이트 표시

## 📂 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점
├── models/
│   ├── meal.dart               # 식단 데이터 모델
│   └── user.dart               # 사용자 데이터 모델
├── services/
│   ├── auth_service.dart       # 인증 서비스
│   └── meal_service.dart       # 식단 서비스
└── screens/
    ├── login_screen.dart       # 로그인 화면
    ├── register_screen.dart    # 회원가입 화면
    ├── home_screen.dart        # 홈 화면 (식단 표시)
    └── profile_screen.dart     # 프로필 화면
```

## 🚀 설치 및 실행

### 1. Flutter 설치
Flutter SDK를 설치해주세요: https://flutter.dev/docs/get-started/install

### 2. 의존성 설치
```bash
flutter pub get
```

### 3. 백엔드 서버 설정
Node.js 백엔드 서버를 실행해야 합니다.
`lib/services/auth_service.dart`와 `lib/services/meal_service.dart`의 `baseUrl`을 실제 서버 주소로 변경하세요.

```dart
static const String baseUrl = 'http://your-server-url:3000/api';
```

**로컬 테스트 주소:**
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
  "breakfast": [
    {
      "name": "흰쌀밥",
      "calories": 310,
      "protein": 6,
      "carbs": 68,
      "fat": 0.5,
      "allergens": []
    },
    ...
  ],
  "lunch": [...],
  "dinner": [...]
}
```

## 📦 필요한 패키지

- http (^1.1.0): REST API 통신
- shared_preferences (^2.2.2): 로컬 데이터 저장 (JWT 토큰)
- intl (^0.18.1): 날짜 포맷팅 및 한국어 지원

## 📅 개발 진행 상황

### 3주차
- Flutter 기본 환경 설정
- 데이터 모델 설계
- 백엔드 API 구조 설계

### 4주차
- 로그인/회원가입 UI 구현
- 인증 서비스 개발

### 5주차
- 홈 화면 및 식단 표시 UI 구현
- 백엔드 API 연동

### 6주차
- 프로필 화면 구현
- 알레르기 정보 관리 기능

### 7주차
- JWT 인증 완성
- 사용자 상태 관리

### 8주차
- UI/UX 개선
- 통합 테스트

## 🔧 문제 해결

### 의존성 오류
```bash
flutter clean
flutter pub get
```

### 네트워크 권한 (Android)
`android/app/src/main/AndroidManifest.xml`에 추가:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS 네트워크 설정
`ios/Runner/Info.plist`에 추가:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 📈 향후 개선 사항

1. 상태 관리: Provider, Riverpod, Bloc 도입
2. 오프라인 지원: SQLite, Hive 데이터베이스
3. 푸시 알림: Firebase Cloud Messaging
4. 검색 기능: 식단 검색 및 필터링
5. 즐겨찾기: 선호 식단 저장
6. 영양 목표: 일일 권장 섭취량 설정
7. 다크 모드: 테마 전환 기능
8. AI를 활용한 사용자 별 알레르기 예방 기능

## 📄 라이선스

학사 프로젝트 용 

## 👥 개발자

- 이도은: Flutter UI 및 프론트엔드
- 강성민: 백엔드 API 및 데이터베이스
