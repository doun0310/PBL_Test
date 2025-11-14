# 식단 관리 앱 (Diet & Calorie Tracking App)

Flutter와 Dart를 이용한 종합 식단 및 칼로리 추적 애플리케이션입니다.

## 📱 주요 기능

### 1. 메인 대시보드
- **날짜 네비게이션**: 이전/다음 날짜로 쉽게 이동
- **칼로리 추적**: 원형 프로그레스로 목표 대비 섭취 칼로리 시각화
- **영양소 분석**: 탄수화물, 단백질, 지방 섭취량을 진행률 바로 표시
- **식사 관리**: 아침, 점심, 저녁 식사를 카테고리별로 관리
- **상세 영양 정보**: 각 식사별 음식 항목과 영양소 정보 표시

### 2. AI 기반 음식 등록
- **카메라/갤러리 지원**: 카메라로 촬영하거나 갤러리에서 선택
- **AI 자동 인식**: 음식 사진을 분석하여 자동으로 영양 정보 계산
- **실시간 분석**: 음식명, 칼로리, 탄수화물, 단백질, 지방 정보 제공
- **결과 관리**: 분석 결과를 수정, 삭제 또는 저장

### 3. 수동 음식 추가
- **직접 입력**: 음식 정보를 직접 입력하여 추가
- **식사 시간 선택**: 아침, 점심, 저녁 중 선택
- **영양 정보 입력**: 칼로리, 탄수화물, 단백질, 지방 정보 입력

### 4. 저장된 음식 관리
- **음식 검색**: 이전에 추가한 음식을 검색
- **빠른 추가**: 저장된 음식을 식사에 빠르게 추가
- **편집/삭제**: 저장된 음식 정보 수정 및 삭제

### 5. 사용자 프로필
- **영양 목표 설정**: 일일 칼로리 및 영양소 목표 설정
- **알레르기 관리**: 개인 알레르기 정보 관리
- **선호도 설정**: 식사 선호도 관리

## 📂 프로젝트 구조

```
lib/
├── main.dart                           # 앱 진입점
├── models/
│   ├── meal.dart                      # 식단 데이터 모델
│   ├── user.dart                      # 사용자 데이터 모델
│   └── nutrition_goals.dart           # 영양 목표 모델
├── services/
│   ├── auth_service.dart              # 인증 서비스
│   ├── meal_service.dart              # 식단 서비스
│   └── food_service.dart              # 음식 관리 및 AI 분석 서비스
└── screens/
    ├── login_screen.dart              # 로그인 화면
    ├── register_screen.dart           # 회원가입 화면
    ├── dashboard_screen.dart          # 메인 대시보드
    ├── add_food_screen.dart           # AI 음식 등록 화면
    ├── manual_food_entry_screen.dart  # 수동 음식 입력 화면
    ├── food_list_screen.dart          # 저장된 음식 목록
    └── profile_screen.dart            # 프로필 화면
```

## 🚀 설치 및 실행

### 1. Flutter 설치
Flutter SDK를 설치해주세요: https://flutter.dev/docs/get-started/install

### 2. 의존성 설치
```bash
flutter pub get
```

### 3. 플랫폼별 설정

카메라 및 갤러리 접근을 위한 플랫폼별 설정이 필요합니다.
자세한 내용은 [PLATFORM_SETUP.md](PLATFORM_SETUP.md)를 참조하세요.

**간단 요약:**

#### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

#### iOS (ios/Runner/Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>음식 사진을 찍어 영양 정보를 분석하기 위해 카메라 접근이 필요합니다.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>갤러리에서 음식 사진을 선택하기 위해 사진 라이브러리 접근이 필요합니다.</string>
```

### 3. 백엔드 서버 설정
Node.js 백엔드 서버를 실행해야 합니다.
`lib/services/auth_service.dart`, `lib/services/meal_service.dart`, `lib/services/food_service.dart`의 `baseUrl`을 실제 서버 주소로 변경하세요.

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

## 📦 주요 패키지

- **http** (^1.1.0): REST API 통신
- **shared_preferences** (^2.2.2): 로컬 데이터 저장 (JWT 토큰, 음식 데이터)
- **intl** (^0.20.2): 날짜 포맷팅 및 한국어 지원
- **image_picker** (^1.0.4): 카메라 및 갤러리 이미지 선택
- **fl_chart** (^0.65.0): 차트 및 그래프 표시
- **percent_indicator** (^4.2.3): 프로그레스 인디케이터

## 💡 사용 가이드

### 음식 등록 방법

1. **AI 자동 인식 사용**
   - 하단 네비게이션에서 "음식 추가" 탭 선택
   - "카메라" 또는 "갤러리" 버튼 클릭
   - 음식 사진 촬영 또는 선택
   - AI 분석 결과 확인 및 수정
   - "저장" 버튼으로 식사에 추가

2. **직접 입력**
   - "직접 입력" 카드 선택
   - 음식명과 영양 정보 입력
   - 식사 시간 선택 (아침/점심/저녁)
   - "저장" 버튼 클릭

3. **저장된 음식 사용**
   - "저장된 음식" 카드 선택
   - 음식 검색 또는 목록에서 선택
   - 음식 카드의 메뉴(⋮) 버튼 클릭
   - "식사에 추가" 선택 후 식사 시간 선택

### 영양 목표 관리

1. 프로필 화면에서 영양 목표 설정
2. 대시보드에서 실시간 진행률 확인
3. 목표 대비 섭취량을 색상으로 구분하여 표시

## 🔧 문제 해결

### 의존성 오류
```bash
flutter clean
flutter pub get
```

### 카메라/갤러리 접근 오류
- Android: 앱 설정에서 카메라 및 저장소 권한 확인
- iOS: 설정 > 개인정보 보호에서 카메라 및 사진 권한 확인
- 자세한 내용은 [PLATFORM_SETUP.md](PLATFORM_SETUP.md) 참조

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

1. **AI 서비스 통합**: 실제 AI 음식 인식 API 연동
2. **상태 관리**: Provider, Riverpod, Bloc 도입
3. **오프라인 지원**: SQLite, Hive 데이터베이스로 완전한 오프라인 모드
4. **푸시 알림**: 식사 시간 알림, 영양 목표 달성 알림
5. **통계 및 리포트**: 주간/월간 영양 섭취 통계 및 트렌드 분석
6. **소셜 기능**: 식단 공유, 친구와 함께 목표 달성
7. **레시피 추천**: 영양 목표에 맞는 레시피 제안
8. **바코드 스캔**: 포장 식품 바코드로 빠른 등록
9. **음성 입력**: 음성으로 음식 정보 입력
10. **다국어 지원**: 영어, 일본어 등 다국어 지원

## 📄 라이선스

학사 프로젝트용 

## 👥 개발자

- 이도은: Flutter UI 및 프론트엔드
- 강성민: 백엔드 API 및 데이터베이스
