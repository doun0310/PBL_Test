# Flutter 프로젝트 구현 요약

## 프로젝트 개요
`JangMinSeong/Diet101` Kotlin 기반 식단 관리 앱을 Flutter/Dart로 재구현한 프로젝트입니다.

## 구현된 주요 기능

### 1. 기본 인증 및 사용자 관리
- ✅ JWT 기반 로그인/회원가입
- ✅ 사용자 프로필 관리
- ✅ 알레르기 정보 등록 및 관리
- ✅ 자동 로그인 상태 유지 (SharedPreferences)

### 2. 식단 조회 및 관리
- ✅ 일별 식단 정보 표시 (아침/점심/저녁)
- ✅ 영양소 정보 표시 (칼로리, 단백질, 탄수화물, 지방)
- ✅ 날짜 선택 기능
- ✅ 알레르기 성분 하이라이트 표시
- ✅ Pull-to-refresh 지원

### 3. 음식 사진 인식 (Diet101 참조)
- ✅ 카메라 촬영 기능
- ✅ 갤러리 이미지 선택
- ✅ AI 기반 음식 인식 서비스 통합 준비
- ✅ 인식된 음식 영양 정보 표시
- ✅ 식단에 추가 기능

### 4. 영양성분표 OCR (Diet101 참조)
- ✅ 성분표 사진 촬영
- ✅ OCR 텍스트 추출 서비스 통합 준비
- ✅ 영양소 정보 자동 입력
- ✅ 데이터 저장 기능

### 5. 음식 추천 시스템 (Diet101 참조)
- ✅ 남은 끼니 및 목표 칼로리 설정
- ✅ Collaborative Filtering 기반 추천
- ✅ 남은 영양소 계산 및 표시
- ✅ 알레르기 고려 추천

### 6. 식단 분석 (Diet101 참조)
- ✅ 주간/월간 탭 전환
- ✅ 총 칼로리 통계
- ✅ 영양소 비율 파이 차트 (fl_chart)
- ✅ 일별 칼로리 막대 그래프
- ✅ 자주 먹은 음식 TOP 5 랭킹

## 기술 스택

### 언어 및 프레임워크
- **Dart**: 프로그래밍 언어
- **Flutter**: 크로스 플랫폼 모바일 앱 프레임워크

### 주요 패키지
- `http`: REST API 통신
- `shared_preferences`: 로컬 데이터 저장
- `intl`: 날짜 포맷팅 및 다국어 지원
- `image_picker`: 이미지 선택
- `camera`: 카메라 기능
- `fl_chart`: 차트 시각화
- `path_provider`: 파일 경로 관리
- `permission_handler`: 권한 관리

### 아키텍처
- **패턴**: MVC (Model-View-Controller)
- **상태 관리**: StatefulWidget + setState
- **네트워킹**: http 패키지
- **로컬 저장소**: SharedPreferences

## 프로젝트 구조

```
lib/
├── main.dart                              # 앱 진입점 및 라우팅
├── models/                                # 데이터 모델
│   ├── meal.dart                         # 식단 모델
│   ├── user.dart                         # 사용자 모델
│   ├── nutrition_label.dart              # 영양성분표 모델
│   └── meal_analytics.dart               # 분석 데이터 모델
├── services/                              # 비즈니스 로직
│   ├── auth_service.dart                 # 인증 처리
│   ├── meal_service.dart                 # 식단 데이터
│   ├── food_recognition_service.dart     # 음식 인식
│   ├── ocr_service.dart                  # OCR 처리
│   ├── recommendation_service.dart       # 추천 알고리즘
│   └── analytics_service.dart            # 분석 데이터
└── screens/                               # UI 화면
    ├── login_screen.dart                 # 로그인
    ├── register_screen.dart              # 회원가입
    ├── home_screen.dart                  # 메인 화면
    ├── profile_screen.dart               # 프로필
    ├── food_recognition_screen.dart      # 음식 인식
    ├── nutrition_label_scan_screen.dart  # 성분표 스캔
    ├── recommendation_screen.dart        # 추천
    └── analytics_screen.dart             # 분석
```

## 개발 상태

### 완료된 작업
- ✅ Flutter 프로젝트 구조 설정
- ✅ 모든 화면 UI 구현
- ✅ 모델 클래스 정의
- ✅ 서비스 레이어 구현 (더미 데이터 포함)
- ✅ Android/iOS 플랫폼 설정
- ✅ 권한 설정 (카메라, 저장소, 인터넷)
- ✅ 라우팅 구성
- ✅ 문서화 (README)

### 백엔드 통합 필요 사항
현재 모든 서비스는 더미 데이터를 반환하도록 구현되어 있습니다.
실제 프로덕션 환경에서는 다음 백엔드 API들과 연동이 필요합니다:

1. **인증 API** (`/api/auth/*`)
   - POST `/login` - 로그인
   - POST `/register` - 회원가입

2. **식단 API** (`/api/meals/*`)
   - GET `/meals?date=YYYY-MM-DD` - 날짜별 식단 조회
   - GET `/meals/search?q=query` - 식단 검색

3. **AI API** (`/api/ai/*`)
   - POST `/recognize-food` - 음식 사진 인식 (YOLO)
   - POST `/ocr-nutrition` - 영양성분표 OCR
   - POST `/recommend` - 음식 추천 (Collaborative Filtering)

4. **분석 API** (`/api/analytics/*`)
   - GET `/weekly` - 주간 분석
   - GET `/monthly` - 월간 분석

### 테스트 방법

#### 1. 더미 데이터로 테스트
현재 상태에서도 앱의 모든 기능을 테스트할 수 있습니다.
각 서비스는 백엔드 API 호출 실패 시 자동으로 더미 데이터를 반환합니다.

```bash
flutter run
```

#### 2. 실제 백엔드와 연동
각 서비스 파일의 `baseUrl`을 실제 서버 주소로 변경:
- `lib/services/auth_service.dart`
- `lib/services/meal_service.dart`
- `lib/services/food_recognition_service.dart`
- `lib/services/ocr_service.dart`
- `lib/services/recommendation_service.dart`
- `lib/services/analytics_service.dart`

## 향후 개선 사항

### 우선순위 높음
1. 백엔드 API 연동
2. 에러 처리 강화
3. 로딩 상태 개선
4. 오프라인 지원 (SQLite/Hive)

### 우선순위 중간
5. 상태 관리 라이브러리 도입 (Provider/Riverpod)
6. 단위 테스트 작성
7. UI/UX 개선
8. 다크 모드 지원

### 우선순위 낮음
9. 푸시 알림
10. 소셜 로그인
11. 다국어 지원
12. 애니메이션 추가

## 참고 자료

- **원본 프로젝트**: [JangMinSeong/Diet101](https://github.com/JangMinSeong/Diet101)
- **Flutter 공식 문서**: https://flutter.dev/docs
- **Dart 공식 문서**: https://dart.dev/guides

## 라이선스
교육 목적 프로젝트
