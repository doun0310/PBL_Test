# Firebase 설정 가이드

## Firebase 프로젝트 설정

이 앱은 Firebase를 사용하여 클라우드 동기화, 인증, 스토리지 기능을 제공합니다.

### 1. Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름 입력 (예: diet-tracking-app)
4. Google 애널리틱스 설정 (선택사항)
5. 프로젝트 생성 완료

### 2. Android 앱 추가

1. Firebase 콘솔에서 Android 아이콘 클릭
2. Android 패키지 이름 입력
   - `android/app/build.gradle` 파일에서 `applicationId` 확인
   - 예: `com.example.diet_tracking_app`
3. 앱 닉네임 입력 (선택사항)
4. SHA-1 키 입력 (선택사항, 나중에 추가 가능)
5. `google-services.json` 다운로드
6. `android/app/` 디렉토리에 파일 복사

### 3. iOS 앱 추가

1. Firebase 콘솔에서 iOS 아이콘 클릭
2. iOS 번들 ID 입력
   - Xcode에서 Runner 프로젝트의 번들 ID 확인
3. 앱 닉네임 입력 (선택사항)
4. `GoogleService-Info.plist` 다운로드
5. Xcode에서 `ios/Runner/` 디렉토리에 파일 추가

### 4. Firebase 서비스 활성화

#### Firestore Database
1. Firebase 콘솔에서 "Firestore Database" 선택
2. "데이터베이스 만들기" 클릭
3. 보안 규칙 선택:
   - 개발: 테스트 모드로 시작
   - 프로덕션: 프로덕션 모드로 시작
4. 위치 선택 (asia-northeast3 권장 - 서울)

#### Authentication
1. Firebase 콘솔에서 "Authentication" 선택
2. "시작하기" 클릭
3. 로그인 방법 탭에서 "이메일/비밀번호" 활성화

#### Storage
1. Firebase 콘솔에서 "Storage" 선택
2. "시작하기" 클릭
3. 보안 규칙 설정
4. 위치 선택

### 5. Firestore 보안 규칙

Firestore Database > 규칙 탭에서 다음 규칙 설정:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자 데이터는 본인만 읽기/쓰기 가능
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 커뮤니티 게시물은 모두 읽기 가능, 작성자만 수정 가능
    match /community_posts/{postId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                               request.auth.uid == resource.data.userId;
    }
  }
}
```

### 6. Storage 보안 규칙

Storage > 규칙 탭에서 다음 규칙 설정:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /community/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 7. FlutterFire CLI 사용 (권장)

FlutterFire CLI를 사용하면 자동으로 Firebase 설정을 생성할 수 있습니다.

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 로그인
firebase login

# FlutterFire 설정
flutterfire configure
```

### 8. 환경 변수 설정

`.env` 파일 생성 (선택사항):

```
FIREBASE_API_KEY=your_api_key
FIREBASE_APP_ID=your_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
```

### 9. 테스트

앱을 실행하고 다음 기능 테스트:

1. 회원가입/로그인
2. 식사 기록 추가 후 동기화 버튼 클릭
3. 다른 기기에서 로그인하여 데이터 확인
4. 커뮤니티 게시물 작성

### 문제 해결

#### "google-services.json not found" 오류
- `android/app/` 디렉토리에 `google-services.json` 파일이 있는지 확인
- 파일 이름이 정확한지 확인

#### "GoogleService-Info.plist not found" 오류
- Xcode에서 파일을 프로젝트에 올바르게 추가했는지 확인
- 파일이 Runner 타겟에 포함되어 있는지 확인

#### Firestore 권한 오류
- 보안 규칙이 올바르게 설정되어 있는지 확인
- 사용자가 인증되어 있는지 확인

## 참고 자료

- [FlutterFire 공식 문서](https://firebase.flutter.dev/)
- [Firebase 콘솔](https://console.firebase.google.com/)
- [Firebase 가격 정책](https://firebase.google.com/pricing)
