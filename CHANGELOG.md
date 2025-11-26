# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2024-11-21

### Added

#### 핵심 기능
- **AI 음식 인식**: Google ML Kit를 사용한 이미지 기반 음식 인식
  - 자동 음식 감지 및 영양소 추정
  - 이미지 라벨링 및 카테고리 분류
  
- **영양성분표 OCR**: Google ML Kit Text Recognition을 사용한 자동 영양 정보 입력
  - 영양성분표 사진 스캔
  - 칼로리, 단백질, 탄수화물, 지방 자동 추출
  - OCR 스캔 전용 화면 추가
  
- **Firebase 클라우드 동기화**: 데이터 백업 및 여러 기기 간 동기화
  - Firestore를 통한 실시간 데이터 동기화
  - Firebase Authentication 통합
  - Firebase Storage를 통한 이미지 저장

#### 소셜 및 사용자 참여 기능
- **식단 공유**: Share Plus를 사용한 소셜 공유 기능
  - 식사 기록 텍스트 공유
  - 이미지와 함께 공유
  - 일일/주간 통계 공유
  
- **운동 기록**: 운동 추적 및 칼로리 소모 계산
  - 8가지 운동 유형 지원
  - 자동 칼로리 계산
  - 일일/주간/월간 통계
  - 운동 기록 전용 화면 추가
  
- **커뮤니티**: 사용자 간 정보 공유 플랫폼
  - 게시물 작성, 조회, 수정, 삭제
  - 카테고리별 필터링 (정보, 레시피, 후기, 질문, 운동, 다이어트)
  - 좋아요 및 댓글 기능
  - 커뮤니티 전용 화면 추가

#### 사용자 경험 개선
- **식사 시간 알림**: Flutter Local Notifications를 사용한 푸시 알림
  - 아침, 점심, 저녁 알림 설정
  - 사용자 정의 알림 시간
  - 알림 on/off 토글
  
- **다국어 지원**: 4개 언어 완벽 지원
  - 한국어, 영어, 일본어, 중국어
  - 앱 내 언어 전환
  - 모든 UI 텍스트 번역
  
- **다크 모드**: 테마 전환 기능
  - 라이트/다크 테마
  - Provider를 사용한 상태 관리
  - 설정에서 토글 가능
  
- **레시피 추천**: 사용자 맞춤 레시피 제공
  - 남은 칼로리 기반 추천
  - 영양 균형 고려
  - 카테고리별 검색
  - 레시피 상세 정보 (재료, 조리법, 영양 정보)
  - 레시피 전용 화면 추가

#### 새로운 화면
- `ExerciseTrackingScreen`: 운동 기록 관리
- `CommunityScreen`: 커뮤니티 게시판
- `RecipeRecommendationScreen`: 레시피 검색 및 추천
- `OCRScanScreen`: 영양성분표 스캔
- `SettingsScreen`: 앱 설정 및 환경 설정

#### 새로운 서비스
- `AIFoodRecognitionService`: AI 음식 인식
- `OCRService`: OCR 텍스트 인식
- `FirebaseSyncService`: Firebase 동기화
- `ExerciseTrackingService`: 운동 기록 관리
- `CommunityService`: 커뮤니티 데이터 관리
- `RecipeService`: 레시피 데이터 및 추천
- `NotificationService`: 로컬 알림 관리
- `LocalizationService`: 다국어 지원
- `ThemeService`: 테마 관리
- `SharingService`: 공유 기능

#### 새로운 모델
- `ExerciseEntry`: 운동 기록 데이터
- `CommunityPost`: 커뮤니티 게시물
- `PostComment`: 게시물 댓글
- `Recipe`: 레시피 데이터

### Changed
- `main.dart`: Provider 통합 및 테마, 로컬라이제이션 설정
- `dashboard_screen.dart`: 빠른 접근 버튼 추가 (커뮤니티, 레시피, 설정)
- `photo_analysis_screen.dart`: AI 음식 인식 서비스 통합
- `auth_service.dart`: 사용자 정보 조회 메서드 추가
- `pubspec.yaml`: 필요한 패키지 의존성 추가

### Dependencies
새롭게 추가된 패키지:
- `firebase_core: ^2.24.2`
- `firebase_auth: ^4.15.3`
- `cloud_firestore: ^4.13.6`
- `firebase_storage: ^11.5.6`
- `tflite_flutter: ^0.10.4`
- `google_ml_kit: ^0.16.3`
- `google_mlkit_text_recognition: ^0.11.0`
- `flutter_local_notifications: ^17.0.0`
- `timezone: ^0.9.2`
- `flutter_localizations` (SDK)
- `share_plus: ^7.2.1`
- `url_launcher: ^6.2.2`

### Documentation
- `README.md`: 새로운 기능 문서화
- `FIREBASE_SETUP.md`: Firebase 설정 가이드 추가
- `CHANGELOG.md`: 변경 사항 문서 추가

## [1.0.0] - 2024-XX-XX

### Initial Release
- 기본 식단 추적 기능
- 칼로리 및 영양소 계산
- 통계 및 그래프
- 프로필 및 목표 설정
- 로컬 데이터 저장
