# Diet101 - AI 기반 식단 관리 애플리케이션

Diet101을 기반으로 한 Flutter + Node.js 식단 관리 애플리케이션입니다.

## 🚀 주요 기능

### 1. 음식 인식 (YOLO v11 기반)
- 사진에서 음식 자동 인식
- 다중 음식 동시 감지
- 한식 특화 클래스 지원 (김치, 불고기, 비빔밥 등)

### 2. 영양성분표 OCR (EasyOCR)
- 가공식품 영양정보 자동 인식
- 한국어/영어 다국어 OCR 지원
- 자동 영양 정보 추출

### 3. 식단 추천 (Collaborative Filtering)
- 남은 칼로리 기반 맞춤 식사 추천
- 사용자 맞춤 CF 추천
- 단일 음식 및 조합 추천

### 4. 대시보드
- 일일 칼로리 및 영양소 섭취 요약
- 목표 대비 진행 상황 시각화
- 날짜별 식사 기록 조회

### 5. 통계 및 분석
- 주간/월간 영양소 그래프
- 자주 먹은 음식 랭킹
- 영양소 섭취 트렌드 분석

### 6. 사용자 프로필
- 일일 칼로리/영양소 목표 설정
- 알레르기 정보 관리
- 식단 선호도 설정

## 🛠 기술 스택

### Frontend (Flutter)
- Flutter 3.x
- Provider (상태 관리)
- FL Chart (차트 시각화)
- Image Picker (이미지 선택)
- TFLite Flutter (YOLO 추론)
- Firebase (인증, 저장소)

### Backend (Node.js)
- Express.js
- MySQL2
- JWT 인증
- Bcrypt.js (비밀번호 해싱)
- Multer (파일 업로드)

### Database (MySQL/MariaDB)
- users: 사용자 정보
- user_goals: 사용자 목표
- foods: 음식 데이터베이스
- meal_records: 식사 기록
- meal_foods: 식사-음식 연결
- ocr_results: OCR 결과

## 📱 화면 구성

1. **로그인/회원가입** - 사용자 인증
2. **대시보드** - 일일 영양 섭취 현황
3. **식사 추가** - 음식 사진 분석, OCR 스캔, 검색
4. **음식 분석** - AI 음식 인식 결과
5. **통계** - 주간/월간 영양 분석
6. **프로필** - 사용자 설정 및 목표 관리
7. **운동 기록** - 운동량 및 소모 칼로리
8. **커뮤니티** - 사용자 정보 공유
9. **레시피** - 맞춤 레시피 추천

## 🚀 설치 및 실행

### 1. 사전 요구사항
- Flutter SDK 3.0 이상
- Node.js 18 이상
- MySQL 또는 MariaDB

### 2. 데이터베이스 설정
```bash
# MySQL에 접속하여 database.sql 실행
mysql -u root -p < database.sql
```

### 3. 백엔드 실행
```bash
# 의존성 설치
npm install

# .env 파일 설정 (DB 정보, JWT 시크릿 등)
cp .env.example .env
# .env 파일 수정

# 서버 실행
npm start
# 또는 개발 모드
npm run dev
```

### 4. Flutter 앱 실행
```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

## 📁 프로젝트 구조

```
├── lib/                      # Flutter 앱 소스
│   ├── main.dart             # 앱 진입점
│   ├── models/               # 데이터 모델
│   ├── screens/              # 화면 위젯
│   ├── services/             # 비즈니스 로직
│   └── widgets/              # 재사용 가능한 위젯
├── server.js                 # Node.js 백엔드
├── database.sql              # 데이터베이스 스키마
├── package.json              # Node.js 의존성
├── pubspec.yaml              # Flutter 의존성
└── assets/                   # 이미지, 모델 파일
```

## 🔧 API 엔드포인트

### 인증
- `POST /api/auth/register` - 회원가입
- `POST /api/auth/login` - 로그인

### 사용자
- `GET /api/profile` - 프로필 조회
- `PUT /api/profile` - 프로필 수정
- `GET /api/goals` - 목표 조회
- `PUT /api/goals` - 목표 수정

### 음식
- `GET /api/foods` - 음식 목록
- `GET /api/foods/search` - 음식 검색
- `GET /api/categories` - 카테고리 목록

### 식사 기록
- `GET /api/diet` - 식사 기록 조회
- `POST /api/diet` - 식사 기록 추가
- `DELETE /api/diet/:id` - 식사 기록 삭제

### 통계
- `GET /api/nutrition/daily` - 일일 영양 통계
- `GET /api/nutrition/weekly` - 주간 영양 통계
- `GET /api/nutrition/monthly` - 월간 영양 통계
- `GET /api/nutrition/ranking` - 음식 랭킹

### AI/OCR
- `POST /api/ai/recognize` - 음식 인식
- `POST /api/ocr/nutrition` - 영양성분표 인식
- `GET /api/recommend` - 음식 추천

## 📄 라이선스

이 프로젝트는 학업용으로 제작되었습니다.

## 👥 개발자

- 강성민: 백엔드 API 및 암호화
- 이도은: 프론트엔드 개발 및 데이터 분석 모델링 & AI 연구

