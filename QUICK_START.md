# Quick Start Guide

이 가이드는 개발자가 프로젝트를 빠르게 시작할 수 있도록 돕습니다.

## ⚡ 5분 안에 시작하기

### 1. 사전 요구사항 확인

```bash
# Flutter 설치 확인
flutter --version

# Flutter 3.0.0 이상이 필요합니다
# 없다면: https://flutter.dev/docs/get-started/install
```

### 2. 프로젝트 클론 및 의존성 설치

```bash
# 저장소 클론
git clone https://github.com/doun0310/PBL_Test.git
cd PBL_Test

# 의존성 설치
flutter pub get

# 한국어 로케일 초기화
flutter pub run intl_translation:extract_to_arb --output-dir=lib/l10n lib/main.dart
```

### 3. 플랫폼 설정 (선택사항)

#### Android (android 폴더가 있는 경우)

`android/app/src/main/AndroidManifest.xml`에 권한 추가:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

#### iOS (ios 폴더가 있는 경우)

`ios/Runner/Info.plist`에 권한 설명 추가:

```xml
<key>NSCameraUsageDescription</key>
<string>음식 사진을 찍기 위해 카메라 접근이 필요합니다.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>갤러리에서 사진을 선택하기 위해 접근이 필요합니다.</string>
```

### 4. 앱 실행

```bash
# 연결된 기기 확인
flutter devices

# 앱 실행 (자동으로 선택된 기기에서)
flutter run

# 특정 기기에서 실행
flutter run -d <device-id>
```

## 🎯 개발 모드

### Hot Reload 활용

앱이 실행 중일 때:
- `r` : Hot reload (UI 변경사항 즉시 반영)
- `R` : Hot restart (앱 전체 재시작)
- `q` : 종료

### 디버그 모드에서 실행

```bash
flutter run --debug
```

### 프로파일 모드 (성능 테스트)

```bash
flutter run --profile
```

## 🧪 테스트 실행

```bash
# 모든 테스트 실행
flutter test

# 특정 테스트 파일
flutter test test/models_test.dart

# 커버리지 포함
flutter test --coverage
```

## 🔍 코드 분석

```bash
# 린팅 규칙 검사
flutter analyze

# 자동 포맷팅
flutter format lib/

# 특정 파일 포맷팅
flutter format lib/screens/dashboard_screen.dart
```

## 🏗️ 빌드

### Android APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APK (크기 최적화)
flutter build apk --split-per-abi
```

### iOS

```bash
# iOS 앱 빌드 (macOS에서만)
flutter build ios --release

# 시뮬레이터용
flutter build ios --debug --simulator
```

### Web

```bash
# Web 빌드
flutter build web

# 로컬 서버로 테스트
cd build/web
python3 -m http.server 8000
# 브라우저에서 http://localhost:8000 접속
```

## 📁 프로젝트 구조 이해하기

```
lib/
├── main.dart                 # 👈 시작점! 여기서부터 읽기
├── models/                   # 데이터 모델
│   ├── meal.dart            # 음식 데이터
│   ├── user.dart            # 사용자 데이터
│   └── nutrition_goals.dart # 영양 목표
├── services/                 # 비즈니스 로직
│   ├── auth_service.dart    # 인증
│   ├── meal_service.dart    # 식단 관리
│   └── food_service.dart    # 음식 관리
└── screens/                  # UI 화면
    ├── dashboard_screen.dart      # 메인 화면
    ├── add_food_screen.dart       # AI 음식 추가
    ├── manual_food_entry_screen.dart  # 수동 입력
    ├── food_list_screen.dart      # 음식 목록
    └── profile_screen.dart        # 프로필
```

## 🔧 자주 발생하는 문제

### 문제 1: "flutter: command not found"

**해결**:
```bash
# Flutter 경로 확인
which flutter

# 없다면 PATH에 추가
export PATH="$PATH:`pwd`/flutter/bin"
```

### 문제 2: "Waiting for another flutter command to release the startup lock"

**해결**:
```bash
# Lock 파일 삭제
rm -rf /path/to/flutter/bin/cache/lockfile
```

### 문제 3: 의존성 오류

**해결**:
```bash
flutter clean
flutter pub get
```

### 문제 4: Android 라이선스 미동의

**해결**:
```bash
flutter doctor --android-licenses
# 모든 라이선스에 'y' 입력
```

### 문제 5: iOS 빌드 오류

**해결**:
```bash
cd ios
pod install
cd ..
flutter run
```

## 💡 개발 팁

### 1. VS Code 확장 프로그램

필수:
- Flutter (Dart Code 포함)
- Dart

추천:
- Flutter Widget Snippets
- Awesome Flutter Snippets
- Error Lens

### 2. 유용한 단축키 (VS Code)

- `Ctrl + Space`: 자동 완성
- `Shift + Alt + F`: 코드 포맷팅
- `F12`: 정의로 이동
- `Shift + F12`: 모든 참조 찾기

### 3. Flutter DevTools

```bash
# DevTools 열기
flutter pub global activate devtools
flutter pub global run devtools
```

### 4. 위젯 인스펙터 사용

앱 실행 중 `p` 키를 눌러 위젯 인스펙터 토글

## 🚀 다음 단계

1. **코드 읽기**: `lib/main.dart`부터 시작
2. **화면 수정**: `lib/screens/dashboard_screen.dart` 열어보기
3. **테스트 실행**: `flutter test` 실행
4. **실제 기기 테스트**: 카메라/갤러리 기능 확인

## 📚 학습 리소스

- [Flutter 공식 문서](https://flutter.dev/docs)
- [Dart 언어 투어](https://dart.dev/guides/language/language-tour)
- [Flutter 쿡북](https://flutter.dev/docs/cookbook)
- [Flutter 위젯 카탈로그](https://flutter.dev/docs/development/ui/widgets)

## 🤝 기여하기

1. 이슈 생성
2. 브랜치 생성 (`git checkout -b feature/amazing-feature`)
3. 커밋 (`git commit -m 'Add amazing feature'`)
4. 푸시 (`git push origin feature/amazing-feature`)
5. Pull Request 생성

## 📞 도움이 필요하신가요?

- 이슈 트래커: GitHub Issues
- 문서: README.md, PLATFORM_SETUP.md, TESTING.md
- 구현 요약: IMPLEMENTATION_SUMMARY.md

---

**Happy Coding! 🎉**
