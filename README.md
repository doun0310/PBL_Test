AI 기반 식단 및 칼로리 추적 애플리케이션 (영양소 추적기)

Flutter와 Dart를 이용한 현대적인 식단 및 칼로리 추적 모바일 애플리케이션입니다.

📱 주요 기능

1. 메인 대시보드
- 일일 칼로리 및 영양소(탄수화물, 단백질, 지방) 섭취 요약
- 목표 대비 실시간 진행 상황 표시
- 원형 및 선형 프로그레스 바로 시각화
- 날짜별 식사 기록 조회
- 직관적인 하단 네비게이션 바

2. 음식 기록
- 사진 분석: 카메라 또는 갤러리에서 음식 사진 업로드하여 AI 분석 ✅
- 수동 검색: 음식 데이터베이스에서 검색 및 선택
- 영양성분표 스캔: OCR을 통한 자동 영양 정보 입력 ✅
- 실시간 영양 정보: 섭취량 조절 시 실시간 칼로리 계산
- 식사 시간 분류: 아침, 점심, 저녁, 간식

3. 식사 추천
- 남은 칼로리 기반 맞춤 식사 추천
- 칼로리 슬라이더로 원하는 칼로리 조절
- 단일 음식 및 조합 추천
- 영양 균형을 고려한 추천 알고리즘

4. 통계 및 분석
- 주간/월간 영양소 그래프: 탄수화물, 단백질, 지방 섭취량 시각화
- 음식 랭킹: 가장 자주 먹은 음식 순위 (메달 표시)
- 기간별 분석: 주간/월간 전환 가능

5. 프로필 및 목표 설정
- 일일 칼로리 목표 설정
- 영양소별 목표 설정 (탄수화물, 단백질, 지방)
- 슬라이더를 통한 직관적인 목표 조절

6. 운동 기록 ⭐ NEW
- 8가지 운동 유형 (걷기, 조깅, 자전거, 수영, 요가, 근력운동, 댄스, 등산)
- 운동 시간 및 소모 칼로리 자동 계산
- 일일/주간/월간 운동 통계

7. 커뮤니티 ⭐ NEW
- 사용자 간 정보 공유 게시판
- 카테고리별 게시물 (정보, 레시피, 후기, 질문, 운동, 다이어트)
- 좋아요 및 댓글 기능

8. 레시피 추천 ⭐ NEW
- 사용자 맞춤 레시피 추천
- 카테고리별 레시피 검색
- 영양 정보 및 조리 시간 표시

9. 설정 ⭐ NEW
- 다크 모드 테마 전환
- 다국어 지원 (한국어, 영어, 일본어, 중국어)
- 식사 시간 알림 설정
- Firebase 클라우드 동기화 및 백업

🎨 UI/UX 특징

- 모던한 디자인: Material Design 3 기반
- 그린 컬러 테마: 건강과 웰빙을 상징하는 #4CAF50 메인 컬러
- 다크 모드 지원: 눈의 피로 감소 및 배터리 절약 ⭐ NEW
- 카드 기반 레이아웃: 정보의 명확한 구분과 가독성
- 그라데이션 효과: 시각적 깊이감과 현대적인 느낌
- 반응형 디자인: 다양한 화면 크기 지원
- 부드러운 애니메이션: 자연스러운 화면 전환
- 다국어 인터페이스: 4개 언어 완벽 지원 ⭐ NEW

📂 프로젝트 구조

```
lib/
├── main.dart                           메인 앱 및 테마 설정
├── models/
│   ├── food_item.dart                  음식 항목 모델
│   ├── meal_entry.dart                 식사 기록 모델
│   ├── user_goals.dart                 사용자 목표 모델
│   ├── exercise_entry.dart             운동 기록 모델 ⭐ NEW
│   ├── community_post.dart             커뮤니티 게시물 모델 ⭐ NEW
│   └── recipe.dart                     레시피 모델 ⭐ NEW
├── services/
│   ├── food_database_service.dart      음식 데이터베이스 서비스
│   ├── meal_tracking_service.dart      식사 추적 서비스
│   ├── auth_service.dart               인증 서비스
│   ├── ai_food_recognition_service.dart AI 음식 인식 서비스 ⭐ NEW
│   ├── ocr_service.dart                OCR 서비스 ⭐ NEW
│   ├── firebase_sync_service.dart      Firebase 동기화 서비스 ⭐ NEW
│   ├── exercise_tracking_service.dart  운동 추적 서비스 ⭐ NEW
│   ├── community_service.dart          커뮤니티 서비스 ⭐ NEW
│   ├── recipe_service.dart             레시피 서비스 ⭐ NEW
│   ├── notification_service.dart       알림 서비스 ⭐ NEW
│   ├── localization_service.dart       다국어 서비스 ⭐ NEW
│   ├── theme_service.dart              테마 서비스 ⭐ NEW
│   └── sharing_service.dart            공유 서비스 ⭐ NEW
├── screens/
│   ├── dashboard_screen.dart           메인 대시보드 화면
│   ├── add_meal_screen.dart            식사 추가 화면
│   ├── food_search_screen.dart         음식 검색 화면
│   ├── photo_analysis_screen.dart      사진 분석 화면
│   ├── food_recommendation_screen.dart 식사 추천 화면
│   ├── statistics_screen.dart          통계 화면
│   ├── profile_screen.dart             프로필 화면
│   ├── exercise_tracking_screen.dart   운동 기록 화면 ⭐ NEW
│   ├── community_screen.dart           커뮤니티 화면 ⭐ NEW
│   ├── recipe_screen.dart              레시피 화면 ⭐ NEW
│   ├── ocr_scan_screen.dart            OCR 스캔 화면 ⭐ NEW
│   └── settings_screen.dart            설정 화면 ⭐ NEW
└── widgets/
    ├── nutrition_progress_card.dart    영양 진행 카드 위젯
    └── meal_card.dart                  식사 카드 위젯
```

🚀 설치 및 실행

1. Flutter 설치
Flutter SDK를 설치해주세요: https://flutter.dev/docs/get-started/install

2. 의존성 설치
```bash
flutter pub get
```

3. 앱 실행
```bash
# Android/iOS
flutter run

# 특정 디바이스 선택
flutter devices
flutter run -d device_id
```

📦 사용된 패키지

**핵심 패키지:**
- flutter: Flutter 프레임워크
- intl: 날짜 포맷팅 및 국제화
- shared_preferences: 로컬 데이터 저장
- provider: 상태 관리
- uuid: 고유 ID 생성
- path_provider: 파일 경로 관리
- http: HTTP 요청

**UI 및 차트:**
- fl_chart: 차트 및 그래프 시각화
- cupertino_icons: iOS 스타일 아이콘

**이미지 및 미디어:**
- image_picker: 이미지 선택 및 카메라 접근

**AI 및 ML ⭐ NEW:**
- tflite_flutter: TensorFlow Lite 모델 실행
- google_ml_kit: ML Kit 이미지 라벨링
- google_mlkit_text_recognition: OCR 텍스트 인식

**Firebase ⭐ NEW:**
- firebase_core: Firebase 핵심 기능
- firebase_auth: Firebase 인증
- cloud_firestore: Firestore 데이터베이스
- firebase_storage: Firebase 스토리지

**알림 및 타임존 ⭐ NEW:**
- flutter_local_notifications: 로컬 푸시 알림
- timezone: 시간대 지원

**다국어 지원 ⭐ NEW:**
- flutter_localizations: Flutter 다국어 지원

**공유 및 URL ⭐ NEW:**
- share_plus: 콘텐츠 공유
- url_launcher: URL 실행

🔧 주요 기술 스택

- Frontend: Flutter (Dart)
- State Management: Provider pattern
- Data Storage: SharedPreferences (로컬) + Firebase (클라우드)
- Charts: FL Chart
- Image Processing: Image Picker + ML Kit
- AI/ML: Google ML Kit + TensorFlow Lite
- OCR: Google ML Kit Text Recognition
- Notifications: Flutter Local Notifications
- Cloud: Firebase (Auth, Firestore, Storage)
- Localization: Flutter Localizations
- UI Components: Material Design 3

📊 데이터 구조

FoodItem (음식 항목)
- 이름, 칼로리, 단백질, 탄수화물, 지방
- 1회 제공량, 단위, 카테고리
- 이미지 URL (선택사항)

MealEntry (식사 기록)
- 고유 ID, 타임스탬프
- 식사 유형 (아침, 점심, 저녁, 간식)
- 음식 목록, 사진 경로, 메모

UserGoals (사용자 목표)
- 일일 칼로리 목표
- 탄수화물, 단백질, 지방 목표
- 하루 식사 횟수

## ✨ 새롭게 추가된 기능 (v2.0.0)

### 핵심 기능

1. **AI 음식 인식** 🤖
   - Google ML Kit를 활용한 이미지 기반 음식 인식
   - 사진에서 자동으로 음식 종류 감지
   - 칼로리 및 영양소 자동 추정

2. **영양성분표 OCR** 📸
   - 영양성분표 사진을 찍어 자동으로 정보 입력
   - 칼로리, 단백질, 탄수화물, 지방 자동 추출
   - 수동 입력 시간 절약

3. **Firebase 클라우드 동기화** ☁️
   - 모든 데이터 클라우드 백업
   - 여러 기기에서 데이터 동기화
   - 실시간 데이터 스트리밍

### 소셜 및 사용자 참여

4. **식단 공유** 🔗
   - 식사 기록을 친구와 공유
   - SNS 공유 기능
   - 일일/주간 통계 공유

5. **운동 기록** 🏃
   - 8가지 운동 유형 지원
   - 소모 칼로리 자동 계산
   - 일일/주간/월간 통계

6. **커뮤니티** 💬
   - 사용자 간 정보 교류 게시판
   - 카테고리별 게시물 분류
   - 좋아요 및 댓글 기능

### 사용자 경험 개선

7. **식사 시간 알림** ⏰
   - 아침, 점심, 저녁 알림 설정
   - 사용자 정의 알림 시간
   - 로컬 푸시 알림

8. **다국어 지원** 🌍
   - 한국어, 영어, 일본어, 중국어
   - 언어 간 자동 전환
   - 완전한 UI 번역

9. **다크 모드** 🌙
   - 라이트/다크 테마 전환
   - 눈의 피로 감소
   - 배터리 절약

10. **레시피 추천** 🍳
    - 맞춤형 레시피 추천
    - 남은 칼로리 기반 제안
    - 영양 균형 고려
    - 카테고리별 검색

## 📦 추가된 패키지

- `firebase_core`: Firebase 핵심 기능
- `firebase_auth`: Firebase 인증
- `cloud_firestore`: Firestore 데이터베이스
- `firebase_storage`: Firebase 스토리지
- `tflite_flutter`: TensorFlow Lite 모델 실행
- `google_ml_kit`: ML Kit 이미지 라벨링
- `google_mlkit_text_recognition`: OCR 텍스트 인식
- `flutter_local_notifications`: 로컬 알림
- `timezone`: 시간대 지원
- `flutter_localizations`: 다국어 지원
- `share_plus`: 공유 기능
- `url_launcher`: URL 실행

## 🎨 새로운 화면

1. **운동 기록 화면**: 운동 추가 및 관리
2. **커뮤니티 화면**: 게시물 작성 및 조회
3. **레시피 화면**: 레시피 검색 및 상세 정보
4. **OCR 스캔 화면**: 영양성분표 스캔
5. **설정 화면**: 앱 설정 및 환경 설정

## 🔧 개선된 기능

- Provider 패턴을 통한 상태 관리 강화
- 테마 서비스로 다크 모드 지원
- 로컬라이제이션 서비스로 다국어 지원
- 알림 서비스로 스케줄링 기능
- AI 서비스로 음식 인식 정확도 향상

📸 스크린샷

(스크린샷은 앱 실행 후 추가 예정)

📄 라이선스

이 프로젝트는 학업용으로 제작되었습니다.

👥 개발자

- 강성민: 백엔드 API 및 암호화 
- 이도은: 프론트엔드 개발 및 데이터 분석 모델링 & AI 연구

