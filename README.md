# 식단 관리 앱 (Meal Management App)

#### 1. 개요
#### 2. 프로젝트 목표
#### 3. 주요 기능
#### 4. 기술 스택 정리
#### 5. 서비스 아키텍처
#### 6. 프로젝트 구조도
#### 7. 팀원 소개

## 1. 개요

Flutter와 Dart를 이용한 학교 식단 관리 모바일 애플리케이션입니다.

본 프로젝트는 학생들이 학교 식단 정보를 편리하게 조회하고, 개인의 알레르기 정보를 관리하며, 영양 정보를 확인할 수 있는 모바일 애플리케이션입니다. 사용자 친화적인 인터페이스를 통해 일별 식단을 확인하고, 개인 건강 관리에 필요한 정보를 제공합니다.

## 2. 프로젝트 목표

### 편리한 식단 정보 제공
학교 식단을 모바일에서 쉽게 확인할 수 있도록 하여, 학생들이 언제 어디서나 식단 정보에 접근할 수 있게 합니다. 날짜별로 아침, 점심, 저녁 식단을 제공하며, 각 메뉴의 상세 영양 정보를 함께 표시합니다.

### 개인 맞춤형 알레르기 관리
개인의 알레르기 정보를 등록하고, 식단에 포함된 알레르기 유발 성분을 자동으로 하이라이트하여 표시합니다. 이를 통해 알레르기가 있는 학생들이 안전하게 식사를 선택할 수 있도록 돕습니다.

### 영양 정보 기반 건강 관리
각 식단의 칼로리, 단백질, 탄수화물, 지방 등의 영양 정보를 제공하여, 사용자가 자신의 영양 섭취를 관리하고 건강한 식습관을 형성할 수 있도록 지원합니다.

## 3. 주요 기능

### 1. 사용자 인증
- 회원가입 및 로그인
- JWT 기반 인증
- 사용자 프로필 관리
- 개인 정보 수정 기능

### 2. 식단 조회
- 일별 식단 정보 표시 (아침, 점심, 저녁)
- 영양 정보 표시 (칼로리, 단백질, 탄수화물, 지방)
- 알레르기 정보 표시
- 날짜 선택 기능
- 직관적인 UI/UX 디자인

### 3. 알레르기 관리
- 개인별 알레르기 정보 등록
- 알레르기 성분이 포함된 식단 하이라이트 표시
- 알레르기 정보 수정 및 관리

## 4. 기술 스택 정리

### Frontend
- **Flutter** : Google이 개발한 크로스 플랫폼 모바일 앱 개발 프레임워크입니다. 하나의 코드베이스로 Android와 iOS 앱을 동시에 개발할 수 있으며, 빠른 개발과 아름다운 UI를 제공합니다.
- **Dart** : Flutter 앱 개발에 사용되는 프로그래밍 언어입니다. 객체 지향적이고 강타입 언어로, 빠른 성능과 생산적인 개발 환경을 제공합니다.

### Backend
- **Node.js** : JavaScript 런타임으로, 서버 사이드 애플리케이션 개발에 사용됩니다.
- **RESTful API** : HTTP 기반의 웹 API로, 클라이언트와 서버 간의 통신을 담당합니다.

### Database
- **MySQL / MariaDB** : 안정적이고 확장성 있는 데이터 관리를 위해 사용되는 오픈소스 관계형 데이터베이스 관리 시스템입니다.

### 주요 패키지
- **http** (^1.1.0): REST API 통신
- **shared_preferences** (^2.2.2): 로컬 데이터 저장 (JWT 토큰)
- **intl** (^0.20.2): 날짜 포맷팅 및 한국어 지원

## 5. 서비스 아키텍처

```
┌─────────────────┐
│  Flutter App    │
│  (Mobile)       │
└────────┬────────┘
         │
         │ HTTP/REST
         │
┌────────▼────────┐
│  Backend API    │
│  (Node.js)      │
└────────┬────────┘
         │
         │ SQL
         │
┌────────▼────────┐
│  Database       │
│  (MySQL/MariaDB)│
└─────────────────┘
```

### 아키텍처 설명
1. **Flutter App (Frontend)**: 사용자 인터페이스를 담당하며, HTTP 통신을 통해 백엔드 API와 데이터를 주고받습니다.
2. **Backend API**: RESTful API를 제공하며, 인증, 식단 정보 제공, 사용자 관리 등의 비즈니스 로직을 처리합니다.
3. **Database**: 사용자 정보, 식단 데이터, 알레르기 정보 등을 저장하고 관리합니다.

## 6. 프로젝트 구조도

## 6. 프로젝트 구조도

### 📱 Flutter App
```
lib/
├── main.dart                    # 앱 진입점
├── models/                      # 데이터 모델
│   ├── meal.dart               # 식단 데이터 모델
│   └── user.dart               # 사용자 데이터 모델
├── services/                    # 비즈니스 로직 및 API 통신
│   ├── auth_service.dart       # 인증 서비스
│   └── meal_service.dart       # 식단 서비스
└── screens/                     # UI 화면
    ├── login_screen.dart       # 로그인 화면
    ├── register_screen.dart    # 회원가입 화면
    ├── home_screen.dart        # 홈 화면 (식단 표시)
    └── profile_screen.dart     # 프로필 화면
```

### 주요 디렉토리 설명
- **models/**: 앱에서 사용하는 데이터 구조를 정의합니다. User와 Meal 모델을 포함합니다.
- **services/**: API 통신과 비즈니스 로직을 담당합니다. 인증과 식단 관련 서비스를 제공합니다.
- **screens/**: 사용자에게 보여지는 UI 화면들을 구현합니다.

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

- **http** (^1.1.0): REST API 통신
- **shared_preferences** (^2.2.2): 로컬 데이터 저장 (JWT 토큰)
- **intl** (^0.18.1): 날짜 포맷팅 및 한국어 지원

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

## 🎨 주요 기술

- **아키텍처**: MVC 패턴
- **상태 관리**: StatefulWidget + setState
- **네트워킹**: http 패키지
- **로컬 저장소**: shared_preferences
- **UI**: Material Design

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

### 기능 개선
1. **상태 관리**: Provider, Riverpod, Bloc 등 전문적인 상태 관리 라이브러리 도입
2. **오프라인 지원**: SQLite, Hive 데이터베이스를 활용한 오프라인 모드 지원
3. **푸시 알림**: Firebase Cloud Messaging을 통한 식단 알림 기능
4. **검색 기능**: 식단 검색 및 필터링 기능 추가
5. **즐겨찾기**: 선호 식단 저장 및 관리 기능
6. **영양 목표**: 일일 권장 섭취량 설정 및 추적 기능
7. **다크 모드**: 테마 전환 기능 추가

### AI/ML 기능 추가
1. **음식 이미지 인식**: YOLO 모델을 활용한 음식 사진 인식 기능
2. **영양성분표 OCR**: EasyOCR을 활용한 성분표 자동 입력
3. **식단 추천**: Collaborative Filtering 알고리즘 기반 맞춤형 식단 추천

### DevOps 개선
1. **CI/CD 파이프라인**: Jenkins를 활용한 자동화된 빌드 및 배포
2. **컨테이너화**: Docker를 활용한 애플리케이션 패키징 및 배포
3. **모니터링**: 애플리케이션 성능 모니터링 및 로깅 시스템 구축

## 7. 팀원 소개

- **이도은**: 백엔드 API 및 데이터베이스 설계/구현
- **강성민**: Flutter UI 및 프론트엔드 개발

## 📄 라이선스

이 프로젝트는 교육 목적으로 개발되었습니다.

---

### 참고 프로젝트
본 프로젝트는 [JangMinSeong/Diet101](https://github.com/JangMinSeong/Diet101) 프로젝트의 구조와 문서화 방식을 참고하여 개선되었습니다.
