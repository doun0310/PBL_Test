# 개발 가이드 (Development Guide)

## 목차
1. [개발 환경 설정](#개발-환경-설정)
2. [프로젝트 구조](#프로젝트-구조)
3. [개발 워크플로우](#개발-워크플로우)
4. [코드 스타일 가이드](#코드-스타일-가이드)
5. [테스트](#테스트)
6. [배포](#배포)

## 개발 환경 설정

### 필수 요구사항
- Flutter SDK (3.0.0 이상)
- Dart SDK (3.0.0 이상)
- Android Studio 또는 VS Code
- Git

### Flutter 설치

#### macOS
```bash
# Homebrew를 사용한 설치
brew install flutter

# 또는 공식 사이트에서 다운로드
# https://flutter.dev/docs/get-started/install/macos
```

#### Windows
```bash
# 공식 사이트에서 Flutter SDK 다운로드
# https://flutter.dev/docs/get-started/install/windows
```

#### Linux
```bash
# 공식 사이트에서 Flutter SDK 다운로드
# https://flutter.dev/docs/get-started/install/linux
```

### 프로젝트 설정

1. 저장소 클론
```bash
git clone https://github.com/doun0310/PBL_Test.git
cd PBL_Test
```

2. 의존성 설치
```bash
flutter pub get
```

3. Flutter Doctor 실행 (환경 확인)
```bash
flutter doctor
```

4. 디바이스 확인
```bash
flutter devices
```

5. 앱 실행
```bash
# Android
flutter run

# iOS (macOS에서만)
flutter run

# 특정 디바이스 선택
flutter run -d <device_id>
```

## 프로젝트 구조

```
PBL_Test/
├── lib/                      # 메인 애플리케이션 코드
│   ├── main.dart            # 앱 진입점
│   ├── models/              # 데이터 모델
│   ├── services/            # 비즈니스 로직 및 API
│   └── screens/             # UI 화면
├── backend/                  # 백엔드 서버 (Node.js)
│   ├── server.js
│   ├── routes/
│   ├── controllers/
│   └── models/
├── test/                     # 테스트 코드
├── android/                  # Android 네이티브 코드
├── ios/                      # iOS 네이티브 코드
├── pubspec.yaml             # Flutter 의존성 관리
├── Jenkinsfile              # CI/CD 파이프라인
└── docker-compose.yml       # Docker 구성
```

## 개발 워크플로우

### 브랜치 전략
- `main`: 프로덕션 브랜치
- `develop`: 개발 브랜치
- `feature/*`: 새 기능 개발
- `bugfix/*`: 버그 수정
- `hotfix/*`: 긴급 수정

### 작업 흐름
1. 이슈 생성 및 할당
2. 브랜치 생성
   ```bash
   git checkout -b feature/기능명
   ```
3. 코드 작성 및 커밋
   ```bash
   git add .
   git commit -m "feat: 기능 설명"
   ```
4. 푸시 및 Pull Request 생성
   ```bash
   git push origin feature/기능명
   ```
5. 코드 리뷰
6. 머지

### 커밋 메시지 컨벤션
- `feat`: 새로운 기능 추가
- `fix`: 버그 수정
- `docs`: 문서 수정
- `style`: 코드 포맷팅, 세미콜론 누락 등
- `refactor`: 코드 리팩토링
- `test`: 테스트 코드
- `chore`: 빌드 업무 수정, 패키지 매니저 수정

예시:
```
feat: 식단 조회 기능 추가
fix: 로그인 시 토큰 저장 오류 수정
docs: README 설치 가이드 업데이트
```

## 코드 스타일 가이드

### Dart 코드 스타일
- [Effective Dart](https://dart.dev/guides/language/effective-dart) 가이드 준수
- Flutter Lints 사용

### 린트 실행
```bash
flutter analyze
```

### 코드 포맷팅
```bash
flutter format .
```

## 테스트

### 단위 테스트 작성
```dart
// test/models/meal_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_management_app/models/meal.dart';

void main() {
  test('Meal 모델 생성 테스트', () {
    final meal = Meal(
      name: '김치찌개',
      calories: 250,
      protein: 12,
      carbs: 20,
      fat: 15,
      allergens: ['돼지고기'],
    );
    
    expect(meal.name, '김치찌개');
    expect(meal.calories, 250);
  });
}
```

### 테스트 실행
```bash
# 모든 테스트 실행
flutter test

# 특정 파일 테스트
flutter test test/models/meal_test.dart

# 커버리지 포함
flutter test --coverage
```

### 위젯 테스트
```bash
flutter test --name "widget"
```

### 통합 테스트
```bash
flutter test integration_test/
```

## 배포

### Android 빌드

#### Debug APK
```bash
flutter build apk --debug
```

#### Release APK
```bash
flutter build apk --release
```

#### App Bundle (Google Play)
```bash
flutter build appbundle --release
```

### iOS 빌드 (macOS에서만)

#### Debug
```bash
flutter build ios --debug
```

#### Release
```bash
flutter build ios --release
```

### 백엔드 배포

#### Docker를 사용한 배포
```bash
# 이미지 빌드
docker-compose build

# 컨테이너 실행
docker-compose up -d

# 로그 확인
docker-compose logs -f

# 중지
docker-compose down
```

#### Jenkins CI/CD
Jenkins 파이프라인이 자동으로:
1. 코드 체크아웃
2. 의존성 설치
3. 테스트 실행
4. 코드 분석
5. 빌드
6. 아티팩트 저장
7. 배포 (옵션)

## 문제 해결

### Flutter 관련

#### 의존성 오류
```bash
flutter clean
flutter pub get
```

#### 빌드 오류
```bash
flutter clean
flutter pub upgrade
flutter build apk
```

### Android 관련

#### 네트워크 권한
`android/app/src/main/AndroidManifest.xml`에 추가:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS 관련

#### HTTP 허용
`ios/Runner/Info.plist`에 추가:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 참고 자료

- [Flutter 공식 문서](https://flutter.dev/docs)
- [Dart 공식 문서](https://dart.dev/guides)
- [Flutter 쿡북](https://flutter.dev/docs/cookbook)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
