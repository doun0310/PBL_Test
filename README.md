AI 기반 식단 및 칼로리 추적 애플리케이션 (영양소 추적기)

Flutter와 Dart를 이용한 현대적인 식단 및 칼로리 추적 모바일 애플리케이션입니다.

새로운 AI/ML 기술 스택

1. YOLO v8 음식 인식 
   - 최신 YOLO v8 객체 감지 모델 적용
   - 실시간 다중 음식 동시 인식
   - 한식 특화 클래스 지원 (김치, 불고기, 비빔밥 등)
   - Non-Maximum Suppression (NMS) 알고리즘
   - TensorFlow Lite 모바일 최적화

2. EasyOCR 영양성분표 스캔 
   - EasyOCR 기반 텍스트 인식
   - 한국어/영어 다국어 OCR 지원
   - Bounding Box 정보 제공

3. Collaborative Filtering 레시피 추천 
   - 사용자-아이템 평점 행렬 기반 추천
   - 피어슨 상관계수를 통한 유사 사용자 탐색
   - K-최근접 이웃 (K-NN) 알고리즘
   - 하이브리드 추천 (CF + 콘텐츠 기반)
   - 레시피 평점 및 히스토리 관리

주요 기능

1. 메인 대시보드
- 일일 칼로리 및 영양소(탄수화물, 단백질, 지방) 섭취 요약
- 목표 대비 실시간 진행 상황 표시
- 원형 및 선형 프로그레스 바로 시각화
- 날짜별 식사 기록 조회
- 직관적인 하단 네비게이션 바

2. 음식 기록
- YOLO v8 음식 인식: 사진에서 여러 음식 동시 감지 
- EasyOCR 스캔: 영양성분표 자동 인식 및 정보 추출 
- 수동 검색: 음식 데이터베이스에서 검색 및 선택
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

6. 운동 기록
- 8가지 운동 유형 (걷기, 조깅, 자전거, 수영, 요가, 근력운동, 댄스, 등산)
- 운동 시간 및 소모 칼로리 자동 계산
- 일일/주간/월간 운동 통계

7. 커뮤니티
- 사용자 간 정보 공유 게시판
- 카테고리별 게시물 (정보, 레시피, 후기, 질문, 운동, 다이어트)
- 좋아요 및 댓글 기능

8. 레시피 추천 (Collaborative Filtering)
- 사용자 맞춤 CF 추천: 유사 사용자 패턴 기반 
- 레시피 평점 시스템: 사용자 피드백 수집 
- 하이브리드 추천: CF + 콘텐츠 기반 + 영양 목표 
- 카테고리별 레시피 검색
- 유사 레시피 추천

UI/UX 특징

- 모던한 디자인: Material Design 3 기반
- 그린 컬러 테마: 건강과 웰빙을 상징하는 #4CAF50 메인 컬러
- 카드 기반 레이아웃: 정보의 명확한 구분과 가독성
- 그라데이션 효과: 시각적 깊이감과 현대적인 느낌
- 반응형 디자인: 다양한 화면 크기 지원
- 부드러운 애니메이션: 자연스러운 화면 전환

프로젝트 구조

```
lib/
├── main.dart                           메인 앱 및 테마 설정
├── models/
│   ├── food_item.dart                  음식 항목 모델
│   ├── meal_entry.dart                 식사 기록 모델
│   ├── user_goals.dart                 사용자 목표 모델
│   ├── exercise_entry.dart             운동 기록 모델
│   ├── community_post.dart             커뮤니티 게시물 모델
│   └── recipe.dart                     레시피 모델
├── services/
│   ├── food_database_service.dart      음식 데이터베이스 서비스
│   ├── meal_tracking_service.dart      식사 추적 서비스
│   ├── auth_service.dart               인증 서비스
│   ├── ai_food_recognition_service.dart YOLO v11 음식 인식 서비스 
│   ├── ocr_service.dart                EasyOCR 서비스 
│   ├── firebase_sync_service.dart      Firebase 동기화 서비스
│   ├── exercise_tracking_service.dart  운동 추적 서비스
│   ├── community_service.dart          커뮤니티 서비스
│   ├── recipe_service.dart             CF 레시피 추천 서비스 
│   ├── notification_service.dart       알림 서비스
│   ├── localization_service.dart       다국어 서비스
│   ├── theme_service.dart              테마 서비스
│   └── sharing_service.dart            공유 서비스
├── screens/
│   ├── dashboard_screen.dart           메인 대시보드 화면
│   ├── add_meal_screen.dart            식사 추가 화면
│   ├── food_search_screen.dart         음식 검색 화면
│   ├── photo_analysis_screen.dart      사진 분석 화면
│   ├── food_reco리
  
UI 및 차트
- fl_chart: 차트 및 그래프 시각화
- cupertino_icons: iOS 스타일 아이콘

이미지 및 미디어
- image_picker: 이미지 선택 및 카메라 접근

AI 및 ML
- tflite_flutter: YOLO v11 TensorFlow Lite 모델 실행

Firebase
- firebase_core: Firebase 핵심 기능
- firebase_auth: Firebase 인증
- cloud_firestore: Firestore 데이터베이스
- firebase_storage: Firebase 스토리지

알림 및 타임존
- flutter_local_notifications: 로컬 푸시 알림
- timezone: 시간대 지원

다국어 지원
- flutter_localizations: Flutter 다국어 지원

공유 및 URL
- share_plus: 콘텐츠 공유
- url_launcher: URL 실행

주요 기술 스택

- Frontend: Flutter (Dart)
- State Management: Provider pattern
- Data Storage: SharedPreferences (로컬) + Firebase (클라우드)
- Charts: FL Chart
- Image Processing: Image Picker
- AI/ML: YOLO v8 (TensorFlow Lite) + EasyOCR
- OCR: EasyOCR (한국어/영어 지원)
- 추천 시스템: Collaborative Filtering (피어슨 상관계수, K-NN)
- Notifications: Flutter Local Notifications
- Cloud: Firebase (Auth, Firestore, Storage)
- Localization: Flutter Localizations
- UI Components: Material Design 3

데이터 구조

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

AI/ML 기술

1. YOLO v8 음식 인식 
   - YOLO v8 적용
   - 한식 특화 클래스 40+ 지원
   - NMS 알고리즘으로 중복 제거
   - IoU 기반 정확한 객체 분류

2. EasyOCR 텍스트 인식 
   - Google ML Kit Text Recognition 대신 EasyOCR 적용
   - 한국어 인식
   - Bounding Box 좌표 정보 제공
   - API 기반 확장 가능한 구조

3. Collaborative Filtering 추천 
   - 단순 칼로리 기반에서 CF 알고리즘으로 업그레이드
   - 사용자 간 유사도 계산 (피어슨 상관계수)
   - K-최근접 이웃 기반 예측 평점
   - 하이브리드 추천 (CF + 콘텐츠 + 영양)
   - 레시피 평점 및 조회/요리 히스토리 관리
   - 아이템 기반 CF로 유사 레시피 추천

알고리즘 상세

YOLO v8 추론 파이프라인
```
이미지 입력 → 전처리 (640x640) → YOLO v8 추론 
→ 후처리 (NMS) → 음식 클래스 매핑 → FoodItem 반환
```

EasyOCR 처리 파이프라인
```
이미지 입력 → Base64 인코딩 → EasyOCR API 호출
→ 텍스트/신뢰도/BBox 추출 → 영양 정보 파싱 → 결과 반환
```

Collaborative Filtering 알고리즘
```
사용자 평점 수집 → 유사도 행렬 구성 → K-NN 이웃 탐색
→ 가중 평점 예측 → 상위 N개 추천 → 하이브리드 보정
```

라이선스

이 프로젝트는 학업용으로 제작되었습니다.

개발자

- 강성민: 백엔드 API 및 암호화 
- 이도은: 프론트엔드 개발 및 데이터 분석 모델링 & AI 연구

PPT 개발 환경
- [- https://www.figma.com/slides/Uly2YmSfRX5JGW3O5Ct3Lt/PBL-%EB%B0%9C%ED%91%9C-%EC%9E%90%EB%A3%8C?node-id=5-36&t=CKYt8prnuzTpuv7L-0](https://docs.google.com/presentation/d/1tVDQRF4rRBBjX7g7e8J1J-DnBOQz0e5_ogCYcxqQW2w/edit?usp=sharing)
- (구글 슬라이드로 진행하였음)
