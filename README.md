# AI 기반 식단 및 칼로리 추적 애플리케이션

Flutter와 Dart를 이용한 현대적인 식단 및 칼로리 추적 모바일 애플리케이션입니다.

## 📱 주요 기능

### 1. 메인 대시보드
- 일일 칼로리 및 영양소(탄수화물, 단백질, 지방) 섭취 요약
- 목표 대비 실시간 진행 상황 표시
- 원형 및 선형 프로그레스 바로 시각화
- 날짜별 식사 기록 조회
- 직관적인 하단 네비게이션 바

### 2. 음식 기록
- **사진 분석**: 카메라 또는 갤러리에서 음식 사진 업로드하여 AI 분석 (시뮬레이션)
- **수동 검색**: 음식 데이터베이스에서 검색 및 선택
- **영양성분표 스캔**: OCR을 통한 자동 영양 정보 입력 (예정)
- **실시간 영양 정보**: 섭취량 조절 시 실시간 칼로리 계산
- **식사 시간 분류**: 아침, 점심, 저녁, 간식

### 3. 식사 추천
- 남은 칼로리 기반 맞춤 식사 추천
- 칼로리 슬라이더로 원하는 칼로리 조절
- 단일 음식 및 조합 추천
- 영양 균형을 고려한 추천 알고리즘

### 4. 통계 및 분석
- **주간/월간 영양소 그래프**: 탄수화물, 단백질, 지방 섭취량 시각화
- **음식 랭킹**: 가장 자주 먹은 음식 순위 (메달 표시)
- **기간별 분석**: 주간/월간 전환 가능

### 5. 프로필 및 목표 설정
- 일일 칼로리 목표 설정
- 영양소별 목표 설정 (탄수화물, 단백질, 지방)
- 슬라이더를 통한 직관적인 목표 조절

## 🎨 UI/UX 특징

- **모던한 디자인**: Material Design 3 기반
- **그린 컬러 테마**: 건강과 웰빙을 상징하는 #4CAF50 메인 컬러
- **카드 기반 레이아웃**: 정보의 명확한 구분과 가독성
- **그라데이션 효과**: 시각적 깊이감과 현대적인 느낌
- **반응형 디자인**: 다양한 화면 크기 지원
- **부드러운 애니메이션**: 자연스러운 화면 전환

## 📂 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점
├── models/
│   ├── food_item.dart                # 음식 항목 모델
│   ├── meal_entry.dart               # 식사 기록 모델
│   └── user_goals.dart               # 사용자 목표 모델
├── services/
│   ├── food_database_service.dart    # 음식 데이터베이스 서비스
│   └── meal_tracking_service.dart    # 식사 추적 서비스
├── screens/
│   ├── dashboard_screen.dart         # 메인 대시보드
│   ├── add_meal_screen.dart          # 식사 추가 화면
│   ├── food_search_screen.dart       # 음식 검색 화면
│   ├── photo_analysis_screen.dart    # 사진 분석 화면
│   ├── food_recommendation_screen.dart # 식사 추천 화면
│   ├── statistics_screen.dart        # 통계 화면
│   └── profile_screen.dart           # 프로필 화면
└── widgets/
    ├── nutrition_progress_card.dart  # 영양 진행 카드
    └── meal_card.dart                # 식사 카드
```

## 🚀 설치 및 실행

### 1. Flutter 설치
Flutter SDK를 설치해주세요: https://flutter.dev/docs/get-started/install

### 2. 의존성 설치
```bash
flutter pub get
```

### 3. 앱 실행
```bash
# Android/iOS
flutter run

# 특정 디바이스 선택
flutter devices
flutter run -d device_id
```

## 📦 사용된 패키지

- **flutter**: Flutter 프레임워크
- **intl**: 날짜 포맷팅 및 국제화
- **shared_preferences**: 로컬 데이터 저장
- **image_picker**: 이미지 선택 및 카메라 접근
- **fl_chart**: 차트 및 그래프 시각화
- **provider**: 상태 관리
- **uuid**: 고유 ID 생성
- **path_provider**: 파일 경로 관리

## 🔧 주요 기술 스택

- **Frontend**: Flutter (Dart)
- **State Management**: Provider pattern
- **Data Storage**: SharedPreferences (로컬)
- **Charts**: FL Chart
- **Image Processing**: Image Picker
- **UI Components**: Material Design 3

## 📊 데이터 구조

### FoodItem (음식 항목)
- 이름, 칼로리, 단백질, 탄수화물, 지방
- 1회 제공량, 단위, 카테고리
- 이미지 URL (선택사항)

### MealEntry (식사 기록)
- 고유 ID, 타임스탬프
- 식사 유형 (아침, 점심, 저녁, 간식)
- 음식 목록, 사진 경로, 메모

### UserGoals (사용자 목표)
- 일일 칼로리 목표
- 탄수화물, 단백질, 지방 목표
- 하루 식사 횟수

## 🌟 향후 개선 사항

1. **AI 통합**: 실제 ML 모델을 통한 음식 인식
2. **OCR 구현**: 영양성분표 자동 스캔 기능
3. **클라우드 동기화**: Firebase를 통한 데이터 백업
4. **소셜 기능**: 친구와 식단 공유
5. **운동 기록**: 운동 칼로리 소모 추적
6. **알림 기능**: 식사 시간 리마인더
7. **다국어 지원**: 여러 언어 지원
8. **다크 모드**: 테마 전환 기능
9. **레시피 추천**: 건강한 레시피 제안
10. **커뮤니티**: 사용자 간 정보 공유

## 📸 스크린샷

(스크린샷은 앱 실행 후 추가 예정)

## 📄 라이선스

이 프로젝트는 학습 목적으로 제작되었습니다.

## 👥 개발자

- **개발**: Flutter/Dart를 사용한 크로스 플랫폼 모바일 앱
- **디자인**: Material Design 3 가이드라인 준수
- **참고**: JangMinSeong/Diet101 프로젝트

## 🤝 기여

버그 리포트나 기능 제안은 GitHub Issues를 통해 제출해주세요.

## 📞 문의

프로젝트 관련 문의사항이 있으시면 GitHub Issues를 통해 연락주세요.

