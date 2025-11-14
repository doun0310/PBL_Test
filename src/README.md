# 식단 관리 앱 백엔드 서버

Flutter 식단 관리 앱용 Node.js + Express + MySQL 백엔드 서버입니다.

## 📋 설치 및 실행 가이드

### 1. 필수 요구사항
- Node.js (v14 이상)
- MySQL (v5.7 이상)
- npm

### 2. 프로젝트 초기 설정

#### 2.1 Node.js 의존성 설치
```bash
npm install
```

#### 2.2 MySQL 데이터베이스 설정
1. MySQL 실행
   ```bash
   # Windows
   mysql -u root -p

   # macOS/Linux
   sudo mysql -u root
   ```

2. database.sql 파일 실행하여 DB 및 테이블 생성
   ```sql
   mysql> source database.sql;
   ```

   또는 한 줄로:
   ```bash
   mysql -u root -p < database.sql
   ```

#### 2.3 환경 변수 설정 (.env)
`.env` 파일에서 다음을 설정합니다:

```env
# 데이터베이스 설정
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=meal_management_db

# JWT 설정 (강력한 암호로 변경 권장)
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production

# 서버 설정
PORT=3000
NODE_ENV=development
```

**주의**: `DB_PASSWORD`를 본인의 MySQL root 비밀번호로 변경하세요!

### 3. 서버 실행

#### 개발 모드 (자동 재시작)
```bash
npm run dev
```

#### 프로덕션 모드
```bash
npm start
```

서버 시작 후 다음과 같은 메시지가 보이면 성공:
```
========================================
식단 관리 앱 백엔드 서버 시작
포트: 3000
환경: development
========================================
API 주소: http://localhost:3000/api
========================================
```

### 4. 서버 정상 작동 확인

브라우저 또는 curl로 다음 주소 접속:
```bash
curl http://localhost:3000/api/health
```

응답:
```json
{"message":"서버가 정상적으로 작동 중입니다."}
```

---

## 📱 API 명세

### 1. 회원가입
**엔드포인트**: `POST /api/auth/register`

**요청 본문**:
```json
{
  "email": "student@school.com",
  "password": "password123",
  "name": "이도은",
  "allergies": ["우유", "계란"],
  "preferences": ["채식"]
}
```

**응답 (201 성공)**:
```json
{
  "message": "회원가입이 완료되었습니다."
}
```

**응답 (400 오류)**:
```json
{
  "message": "이미 등록된 이메일입니다."
}
```

---

### 2. 로그인
**엔드포인트**: `POST /api/auth/login`

**요청 본문**:
```json
{
  "email": "student@school.com",
  "password": "password123"
}
```

**응답 (200 성공)**:
```json
{
  "message": "로그인 성공",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "student@school.com",
    "name": "이도은",
    "allergies": ["우유", "계란"],
    "preferences": ["채식"]
  }
}
```

---

### 3. 식단 조회 (날짜별)
**엔드포인트**: `GET /api/meals?date=2025-11-03`

**헤더**:
```
Authorization: Bearer {token}
```

**응답 (200 성공)**:
```json
{
  "date": "2025-11-03",
  "breakfast": [
    {
      "name": "흰쌀밥",
      "calories": 310,
      "protein": 6,
      "carbs": 68,
      "fat": 0.5,
      "allergens": []
    }
  ],
  "lunch": [...],
  "dinner": [...]
}
```

---

### 4. 식단 검색
**엔드포인트**: `GET /api/meals/search?q=김치`

**헤더**:
```
Authorization: Bearer {token}
```

**응답 (200 성공)**:
```json
[
  {
    "name": "김치찌개",
    "calories": 180,
    "protein": 12,
    "carbs": 15,
    "fat": 8,
    "allergens": ["돼지고기", "대두"]
  }
]
```

---

### 5. 프로필 조회
**엔드포인트**: `GET /api/profile`

**헤더**:
```
Authorization: Bearer {token}
```

**응답 (200 성공)**:
```json
{
  "id": 1,
  "email": "student@school.com",
  "name": "이도은",
  "allergies": ["우유", "계란"],
  "preferences": ["채식"]
}
```

---

### 6. 프로필 업데이트
**엔드포인트**: `PUT /api/profile`

**헤더**:
```
Authorization: Bearer {token}
Content-Type: application/json
```

**요청 본문**:
```json
{
  "name": "이도은 (수정)",
  "allergies": ["우유", "계란", "땅콩"],
  "preferences": ["매운 음식 싫음"]
}
```

**응답 (200 성공)**:
```json
{
  "message": "프로필이 업데이트되었습니다."
}
```

---

## 🛠️ 문제 해결

### 포트 이미 사용 중 오류
```
Error: listen EADDRINUSE: address already in use :::3000
```

**해결책**:
```bash
# Windows - 포트 3000 사용 중인 프로세스 찾기
netstat -ano | findstr :3000
taskkill /PID {PID} /F

# macOS/Linux
lsof -i :3000
kill -9 {PID}
```

### MySQL 연결 오류
```
Error: connect ECONNREFUSED 127.0.0.1:3306
```

**해결책**:
1. MySQL 서버 실행 확인
2. `.env` 파일의 DB_HOST, DB_USER, DB_PASSWORD 확인
3. MySQL 사용자 권한 확인

### 토큰 오류 (403)
```
"message": "유효하지 않은 토큰입니다."
```

**해결책**:
- 요청 헤더의 Authorization 값 확인
- 정확한 형식: `Authorization: Bearer {token}`
- 토큰 만료 여부 확인 (유효기간: 7일)

---

## 📊 데이터베이스 테이블 구조

### users 테이블
| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| id | INT | 사용자 고유번호 |
| email | VARCHAR | 이메일 (unique) |
| password | VARCHAR | 암호화된 비밀번호 |
| name | VARCHAR | 사용자 이름 |
| allergies | JSON | 알레르기 목록 |
| preferences | JSON | 식단 선호도 |
| created_at | TIMESTAMP | 생성일시 |
| updated_at | TIMESTAMP | 수정일시 |

### meals 테이블
| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| id | INT | 식단 고유번호 |
| date | DATE | 식단 날짜 (unique) |
| breakfast | JSON | 아침 식단 |
| lunch | JSON | 점심 식단 |
| dinner | JSON | 저녁 식단 |
| created_at | TIMESTAMP | 생성일시 |
| updated_at | TIMESTAMP | 수정일시 |

---

## 🔐 보안 참고사항

1. **JWT_SECRET** 변경 필요
   - 기본값은 개발용으로만 사용
   - 프로덕션에서는 반드시 강력한 값으로 변경

2. **CORS 설정**
   - 현재는 모든 도메인 허용
   - 프로덕션에서는 허용할 도메인만 지정 권장

3. **환경 변수 보호**
   - `.env` 파일을 `git`에 커밋하지 마세요
   - `.gitignore`에 `.env` 추가

---

## 🚀 배포 준비

1. NODE_ENV를 production으로 변경
2. JWT_SECRET을 강력한 값으로 변경
3. DB 비밀번호 변경
4. CORS 설정을 필요한 도메인만 허용으로 변경
5. 서버 로그 모니터링 설정
6. 자동 백업 설정

---

## 📞 지원

문제가 발생하면:
1. 서버 콘솔 로그 확인
2. Flutter 앱 개발자도구 네트워크 탭 확인
3. MySQL 로그 확인
4. `.env` 파일 설정 재확인

