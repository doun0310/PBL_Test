# 시스템 아키텍처 문서

## 전체 시스템 구조

```
┌────────────────────────────────────────────────────────────┐
│                      사용자 계층                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Android    │  │      iOS     │  │      Web     │    │
│  │   디바이스    │  │    디바이스   │  │   브라우저   │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
└────────────────────────────────────────────────────────────┘
                           │
                           │ HTTPS/REST API
                           ▼
┌────────────────────────────────────────────────────────────┐
│                   Flutter 애플리케이션                       │
│  ┌────────────────────────────────────────────────────┐   │
│  │              Presentation Layer                     │   │
│  │    ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐ │   │
│  │    │ Login  │  │  Home  │  │Profile │  │Register│ │   │
│  │    │ Screen │  │ Screen │  │ Screen │  │ Screen │ │   │
│  │    └────────┘  └────────┘  └────────┘  └────────┘ │   │
│  └────────────────────────────────────────────────────┘   │
│  ┌────────────────────────────────────────────────────┐   │
│  │              Business Logic Layer                   │   │
│  │    ┌─────────────┐        ┌─────────────┐         │   │
│  │    │   Auth      │        │    Meal     │         │   │
│  │    │  Service    │        │   Service   │         │   │
│  │    └─────────────┘        └─────────────┘         │   │
│  └────────────────────────────────────────────────────┘   │
│  ┌────────────────────────────────────────────────────┐   │
│  │                 Data Layer                          │   │
│  │    ┌─────────────┐        ┌─────────────┐         │   │
│  │    │    User     │        │    Meal     │         │   │
│  │    │   Model     │        │   Model     │         │   │
│  │    └─────────────┘        └─────────────┘         │   │
│  └────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
                           │
                           │ HTTP/REST
                           ▼
┌────────────────────────────────────────────────────────────┐
│                    Backend API Server                       │
│                      (Node.js/Express)                      │
│  ┌────────────────────────────────────────────────────┐   │
│  │                  API Routes                         │   │
│  │    /api/auth/*  │  /api/meals/*  │  /api/profile/* │   │
│  └────────────────────────────────────────────────────┘   │
│  ┌────────────────────────────────────────────────────┐   │
│  │                 Controllers                         │   │
│  │  AuthController │ MealController │ UserController  │   │
│  └────────────────────────────────────────────────────┘   │
│  ┌────────────────────────────────────────────────────┐   │
│  │                  Middleware                         │   │
│  │     JWT Auth    │   Validation   │   Error Handler │   │
│  └────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
                           │
                           │ SQL
                           ▼
┌────────────────────────────────────────────────────────────┐
│                   Database Layer                            │
│                    (MySQL/MariaDB)                         │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐          │
│  │   Users    │  │   Meals    │  │ Allergies  │          │
│  │   Table    │  │   Table    │  │   Table    │          │
│  └────────────┘  └────────────┘  └────────────┘          │
└────────────────────────────────────────────────────────────┘
```

## 아키텍처 패턴

### Frontend: MVC (Model-View-Controller)
- **Model**: 데이터 구조 정의 (`models/`)
- **View**: UI 화면 (`screens/`)
- **Controller**: 비즈니스 로직 (`services/`)

### Backend: Layered Architecture
- **Presentation Layer**: API Routes
- **Business Logic Layer**: Controllers
- **Data Access Layer**: Database Models
- **Cross-cutting Concerns**: Middleware

## 데이터 흐름

### 1. 사용자 인증 플로우
```
사용자 → LoginScreen → AuthService → Backend API → Database
                                   ↓
                              JWT Token
                                   ↓
                        SharedPreferences 저장
```

### 2. 식단 조회 플로우
```
사용자 → HomeScreen → MealService → Backend API → Database
                                  ↓
                            식단 데이터 (JSON)
                                  ↓
                            Meal 모델 변환
                                  ↓
                            UI 렌더링
```

### 3. 프로필 업데이트 플로우
```
사용자 → ProfileScreen → AuthService → Backend API → Database
                                    ↓
                              업데이트 확인
                                    ↓
                            로컬 상태 갱신
```

## 보안 아키텍처

### 인증 및 권한
- **JWT (JSON Web Token)** 기반 인증
- Token은 SharedPreferences에 안전하게 저장
- 모든 API 요청에 Bearer Token 포함

### 데이터 보호
- HTTPS를 통한 암호화된 통신
- 비밀번호는 bcrypt로 해싱
- SQL Injection 방지를 위한 Prepared Statements
- XSS 방지를 위한 입력 검증

## 확장 가능성

### 수평 확장
- Backend API 서버의 로드 밸런싱
- Database Replication 및 Sharding

### 기능 확장
- AI/ML 서비스 추가 (YOLO, OCR)
- 추천 시스템 (Collaborative Filtering)
- 실시간 알림 (Firebase Cloud Messaging)
- 캐싱 레이어 (Redis)

## 성능 최적화

### Frontend
- 이미지 캐싱
- Lazy Loading
- State Management 최적화

### Backend
- Database Query 최적화
- Connection Pooling
- Response Caching
- API Rate Limiting

## 모니터링 및 로깅

### 애플리케이션 모니터링
- Crash Reporting (Firebase Crashlytics)
- Performance Monitoring
- User Analytics

### 서버 모니터링
- API Response Time
- Error Rate
- Resource Usage (CPU, Memory)
- Database Performance

## CI/CD 파이프라인

```
Code Push → GitHub → Jenkins → Build → Test → Deploy
                        │
                        ├─→ Flutter Build (APK/IPA)
                        ├─→ Backend Docker Image
                        └─→ Database Migration
```

### 자동화된 프로세스
1. 코드 체크아웃
2. 의존성 설치
3. 정적 분석 (Linting)
4. 단위 테스트
5. 통합 테스트
6. 빌드
7. 배포 (Production/Staging)

## 데이터베이스 스키마

### Users 테이블
```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Allergies 테이블
```sql
CREATE TABLE user_allergies (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  allergen VARCHAR(100) NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### Meals 테이블
```sql
CREATE TABLE meals (
  id INT AUTO_INCREMENT PRIMARY KEY,
  date DATE NOT NULL,
  meal_type ENUM('breakfast', 'lunch', 'dinner') NOT NULL,
  name VARCHAR(100) NOT NULL,
  calories INT,
  protein DECIMAL(5,2),
  carbs DECIMAL(5,2),
  fat DECIMAL(5,2),
  allergens TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 환경 구성

### Development
- Local Flutter Development
- Local Backend Server
- Local Database

### Staging
- TestFlight/Internal Testing
- Staging Backend Server
- Staging Database

### Production
- App Store/Play Store
- Production Backend Server (Load Balanced)
- Production Database (Replicated)

## 재해 복구 계획

### 백업 전략
- 일일 데이터베이스 백업
- 코드 버전 관리 (Git)
- Docker 이미지 저장

### 복구 절차
1. 백업 데이터 확인
2. 서버 재구성
3. 데이터 복원
4. 서비스 재시작
5. 검증 및 모니터링
