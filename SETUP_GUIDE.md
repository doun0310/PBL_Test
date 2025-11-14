# Flutter 식단 관리 앱 - 설치 및 실행 가이드

## 📋 목차
1. [개발 환경 설정](#1-개발-환경-설정)
2. [프로젝트 생성 및 파일 배치](#2-프로젝트-생성-및-파일-배치)
3. [의존성 설치](#3-의존성-설치)
4. [백엔드 서버 설정](#4-백엔드-서버-설정)
5. [앱 실행](#5-앱-실행)
6. [테스트 계정](#6-테스트-계정)
7. [빌드](#7-빌드)
8. [문제 해결](#8-문제-해결)

---

## 1. 개발 환경 설정

### Flutter SDK 설치

#### Windows
1. https://docs.flutter.dev/get-started/install/windows 접속
2. Flutter SDK 다운로드 및 압축 해제
3. 시스템 환경 변수에 Flutter bin 폴더 경로 추가
4. 명령 프롬프트에서 `flutter doctor` 실행

#### macOS
```bash
# Homebrew로 설치
brew install flutter

# 또는 공식 사이트에서 다운로드
# https://docs.flutter.dev/get-started/install/macos
```

#### Linux
```bash
# 스냅으로 설치
sudo snap install flutter --classic

# 환경 변수 설정
export PATH="$PATH:`pwd`/flutter/bin"
```

### 개발 도구 설치

#### Android Studio (추천)
1. https://developer.android.com/studio 에서 다운로드
2. Android SDK 설치
3. Flutter 플러그인 설치
4. `flutter doctor` 실행하여 설정 확인

#### VS Code (가벼운 대안)
1. https://code.visualstudio.com/ 에서 다운로드
2. Flutter 확장 프로그램 설치
3. Dart 확장 프로그램 설치

### 설치 확인
```bash
flutter doctor
```
모든 항목이 ✓ 표시되면 준비 완료!

---

## 2. 프로젝트 생성 및 파일 배치

### 새 Flutter 프로젝트 생성
```bash
flutter create meal_management_app
cd meal_management_app
```

### 파일 구조 생성
```bash
# lib 디렉토리 하위 폴더 생성
mkdir -p lib/models
mkdir -p lib/services
mkdir -p lib/screens
```

### 제공된 파일들 복사
다운로드한 ZIP 파일의 내용을 다음과 같이 배치:

```
meal_management_app/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── meal.dart
│   │   └── user.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   └── meal_service.dart
│   └── screens/
│       ├── login_screen.dart
│       ├── register_screen.dart
│       ├── home_screen.dart
│       └── profile_screen.dart
├── pubspec.yaml
├── README.md
└── SETUP_GUIDE.md
```

---

## 3. 의존성 설치

### pubspec.yaml 업데이트
루트 디렉토리의 `pubspec.yaml` 파일을 제공된 내용으로 교체

### 패키지 설치
```bash
flutter pub get
```

### 설치되는 패키지
- **http**: REST API 통신
- **shared_preferences**: 로컬 데이터 저장
- **intl**: 날짜 포맷팅 및 국제화

---

## 4. 백엔드 서버 설정

### 서버 주소 변경
`lib/services/auth_service.dart`와 `lib/services/meal_service.dart`에서 `baseUrl` 수정:

#### 로컬 개발 환경

**Android 에뮬레이터:**
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

**iOS 시뮬레이터:**
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

**실제 디바이스 (같은 네트워크):**
```dart
static const String baseUrl = 'http://192.168.x.x:3000/api';
```
컴퓨터의 로컬 IP 주소 확인 방법:
- Windows: `ipconfig`
- macOS/Linux: `ifconfig` 또는 `ip addr`

#### 프로덕션 환경
```dart
static const String baseUrl = 'https://your-domain.com/api';
```

### 네트워크 권한 설정

#### Android
`android/app/src/main/AndroidManifest.xml` 파일에 추가:
```xml
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET" />
    <application ...>
        ...
    </application>
</manifest>
```

#### iOS
`ios/Runner/Info.plist` 파일에 추가 (HTTP 통신 허용):
```xml
<dict>
    ...
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    ...
</dict>
```

---

## 5. 앱 실행

### 연결된 디바이스 확인
```bash
flutter devices
```

출력 예시:
```
Chrome (web)                 • chrome   • web-javascript • Google Chrome
iPhone 14 Pro (mobile)       • xxx-xxx  • ios            • iOS 16.0
Android SDK (mobile)         • emulator • android        • Android 13
```

### 앱 실행
```bash
# 기본 디바이스에서 실행
flutter run

# 특정 디바이스에서 실행
flutter run -d chrome
flutter run -d emulator-5554
flutter run -d xxx-xxx
```

### 개발 중 유용한 단축키
- **r**: Hot Reload (즉시 UI 업데이트)
- **R**: Hot Restart (앱 재시작)
- **p**: 그리드 오버레이 표시
- **o**: 플랫폼 전환 (iOS/Android)
- **q**: 종료

---

## 6. 테스트 계정

백엔드 서버에 다음 테스트 계정이 있어야 합니다:

```
이메일: student@school.com
비밀번호: password123
이름: 이도은
알레르기: 우유, 계란
```

```
이메일: user@school.com
비밀번호: test1234
이름: 강성민
알레르기: 새우젓
```

또는 앱의 회원가입 기능으로 새 계정 생성 가능

---

## 7. 빌드

### Android APK 빌드
```bash
# 디버그 APK (개발용)
flutter build apk --debug

# 릴리즈 APK (배포용)
flutter build apk --release

# APK 위치
# build/app/outputs/flutter-apk/app-release.apk
```

### iOS IPA 빌드 (macOS에서만)
```bash
# 릴리즈 빌드
flutter build ios --release

# Xcode로 열어서 서명 및 배포
open ios/Runner.xcworkspace
```

### 앱 번들 (Google Play 배포용)
```bash
flutter build appbundle
```

---

## 8. 문제 해결

### 의존성 오류
```bash
flutter clean
flutter pub get
```

### 빌드 캐시 문제
```bash
flutter clean
rm -rf build/
flutter pub get
flutter run
```

### Gradle 오류 (Android)
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### CocoaPods 오류 (iOS)
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

### Hot Reload가 작동하지 않을 때
1. **R** 키로 Hot Restart 시도
2. 앱 완전히 종료 후 재실행
3. `flutter clean` 후 재빌드

### 네트워크 연결 오류
1. 백엔드 서버가 실행 중인지 확인
2. `baseUrl`이 올바른지 확인
3. 방화벽 설정 확인
4. 실제 디바이스의 경우 같은 네트워크에 연결되어 있는지 확인

### Android 에뮬레이터가 느릴 때
1. HAXM 설치 (Intel CPU)
2. 에뮬레이터 RAM 증가 (AVD Manager)
3. 하드웨어 가속 활성화

---

## 🎯 다음 단계

1. **상태 관리 개선**: Provider 또는 Riverpod 적용
2. **테스트 작성**: Widget 테스트, 통합 테스트
3. **CI/CD 구축**: GitHub Actions 또는 Codemagic
4. **스토어 배포**: Google Play Store, Apple App Store

---

## 📞 지원

문제가 발생하면:
1. `flutter doctor` 실행하여 환경 확인
2. 에러 로그 확인
3. Flutter 공식 문서 참조: https://docs.flutter.dev
4. Stack Overflow 검색

행운을 빕니다! 🚀
