-- ====================================
-- Diet101 데이터베이스 스키마
-- Diet101 프로젝트 기반으로 수정
-- ====================================

-- 1. 기존 데이터베이스 삭제 (필요시)
DROP DATABASE IF EXISTS diet101_db;

-- 2. 데이터베이스 생성
CREATE DATABASE diet101_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- 3. 데이터베이스 선택
USE diet101_db;

-- ====================================
-- 사용자 테이블 생성
-- ====================================
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY COMMENT '사용자 고유번호',
  email VARCHAR(255) UNIQUE NOT NULL COMMENT '이메일 (고유)',
  password VARCHAR(255) NOT NULL COMMENT '암호화된 비밀번호',
  name VARCHAR(100) NOT NULL COMMENT '사용자 이름',
  allergies LONGTEXT COMMENT '알레르기 정보 (JSON)',
  preferences LONGTEXT COMMENT '식단 선호도 (JSON)',
  height DOUBLE COMMENT '키 (cm)',
  weight DOUBLE COMMENT '몸무게 (kg)',
  gender VARCHAR(10) COMMENT '성별',
  birth_date DATE COMMENT '생년월일',
  activity_level VARCHAR(50) COMMENT '활동 수준',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',
  INDEX idx_email (email),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='사용자 정보 테이블';

-- ====================================
-- 사용자 목표 테이블
-- ====================================
CREATE TABLE user_goals (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL COMMENT '사용자 ID',
  daily_calorie_goal DOUBLE DEFAULT 2000 COMMENT '일일 칼로리 목표',
  protein_goal DOUBLE DEFAULT 50 COMMENT '단백질 목표 (g)',
  carbs_goal DOUBLE DEFAULT 250 COMMENT '탄수화물 목표 (g)',
  fat_goal DOUBLE DEFAULT 65 COMMENT '지방 목표 (g)',
  meals_per_day INT DEFAULT 3 COMMENT '하루 식사 횟수',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_user (user_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='사용자 목표 테이블';

-- ====================================
-- 음식 데이터베이스 테이블
-- ====================================
CREATE TABLE foods (
  id INT AUTO_INCREMENT PRIMARY KEY COMMENT '음식 고유번호',
  name VARCHAR(255) NOT NULL COMMENT '음식 이름',
  calories DOUBLE NOT NULL COMMENT '칼로리 (kcal)',
  protein DOUBLE DEFAULT 0 COMMENT '단백질 (g)',
  carbs DOUBLE DEFAULT 0 COMMENT '탄수화물 (g)',
  fat DOUBLE DEFAULT 0 COMMENT '지방 (g)',
  sodium DOUBLE DEFAULT 0 COMMENT '나트륨 (mg)',
  sugar DOUBLE DEFAULT 0 COMMENT '당류 (g)',
  fiber DOUBLE DEFAULT 0 COMMENT '식이섬유 (g)',
  serving_size DOUBLE DEFAULT 100 COMMENT '1회 제공량',
  unit VARCHAR(20) DEFAULT 'g' COMMENT '단위',
  category VARCHAR(100) COMMENT '카테고리',
  image_url VARCHAR(500) COMMENT '이미지 URL',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_name (name),
  INDEX idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='음식 데이터베이스';

-- ====================================
-- 식사 기록 테이블
-- ====================================
CREATE TABLE meal_records (
  id INT AUTO_INCREMENT PRIMARY KEY COMMENT '식사 기록 고유번호',
  user_id INT NOT NULL COMMENT '사용자 ID',
  meal_type VARCHAR(50) NOT NULL COMMENT '식사 유형 (breakfast, lunch, dinner, snack)',
  meal_time DATETIME NOT NULL COMMENT '식사 시간',
  total_calories DOUBLE DEFAULT 0 COMMENT '총 칼로리',
  total_protein DOUBLE DEFAULT 0 COMMENT '총 단백질',
  total_carbs DOUBLE DEFAULT 0 COMMENT '총 탄수화물',
  total_fat DOUBLE DEFAULT 0 COMMENT '총 지방',
  photo_path VARCHAR(500) COMMENT '사진 경로',
  notes TEXT COMMENT '메모',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_date (user_id, meal_time),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='식사 기록 테이블';

-- ====================================
-- 식사-음식 연결 테이블
-- ====================================
CREATE TABLE meal_foods (
  id INT AUTO_INCREMENT PRIMARY KEY,
  meal_id INT NOT NULL COMMENT '식사 기록 ID',
  food_id INT NOT NULL COMMENT '음식 ID',
  serving_size DOUBLE DEFAULT 100 COMMENT '섭취량',
  quantity DOUBLE DEFAULT 1 COMMENT '수량',
  FOREIGN KEY (meal_id) REFERENCES meal_records(id) ON DELETE CASCADE,
  FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='식사-음식 연결 테이블';

-- ====================================
-- OCR 결과 테이블
-- ====================================
CREATE TABLE ocr_results (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL COMMENT '사용자 ID',
  image_path VARCHAR(500) COMMENT '이미지 경로',
  raw_text TEXT COMMENT '인식된 원본 텍스트',
  calories DOUBLE COMMENT '칼로리',
  protein DOUBLE COMMENT '단백질',
  carbs DOUBLE COMMENT '탄수화물',
  fat DOUBLE COMMENT '지방',
  sodium DOUBLE COMMENT '나트륨',
  sugar DOUBLE COMMENT '당류',
  serving_size DOUBLE COMMENT '1회 제공량',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='OCR 결과 테이블';

-- ====================================
-- 기존 식단 테이블 (호환성 유지)
-- ====================================
CREATE TABLE meals (
  id INT AUTO_INCREMENT PRIMARY KEY COMMENT '식단 고유번호',
  date DATE UNIQUE NOT NULL COMMENT '식단 날짜 (고유)',
  breakfast LONGTEXT COMMENT '아침 식단 (JSON)',
  lunch LONGTEXT COMMENT '점심 식단 (JSON)',
  dinner LONGTEXT COMMENT '저녁 식단 (JSON)',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',
  INDEX idx_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='식단 정보 테이블';

-- ====================================
-- 한식 음식 데이터 삽입
-- ====================================

-- 밥류
INSERT INTO foods (name, calories, protein, carbs, fat, serving_size, unit, category) VALUES
('흰쌀밥', 310, 6, 68, 0.5, 210, 'g', '밥류'),
('현미밥', 280, 6, 60, 2, 210, 'g', '밥류'),
('잡곡밥', 290, 7, 62, 1.5, 210, 'g', '밥류'),
('김밥', 450, 12, 75, 8, 300, 'g', '밥류'),
('비빔밥', 550, 18, 78, 15, 400, 'g', '밥류'),
('볶음밥', 480, 12, 72, 14, 350, 'g', '밥류'),
('오므라이스', 520, 15, 68, 18, 380, 'g', '밥류'),
('카레라이스', 480, 12, 75, 12, 400, 'g', '밥류'),
('김치볶음밥', 450, 10, 70, 12, 350, 'g', '밥류'),
('돌솥비빔밥', 580, 20, 80, 16, 450, 'g', '밥류');

-- 국/찌개류
INSERT INTO foods (name, calories, protein, carbs, fat, serving_size, unit, category) VALUES
('된장찌개', 150, 10, 12, 6, 250, 'ml', '국/찌개'),
('김치찌개', 180, 12, 10, 8, 250, 'ml', '국/찌개'),
('순두부찌개', 200, 14, 8, 12, 300, 'ml', '국/찌개'),
('부대찌개', 350, 18, 25, 20, 400, 'ml', '국/찌개'),
('미역국', 80, 5, 8, 3, 250, 'ml', '국/찌개'),
('콩나물국', 50, 4, 5, 2, 250, 'ml', '국/찌개'),
('계란국', 100, 8, 5, 6, 250, 'ml', '국/찌개'),
('갈비탕', 350, 25, 5, 25, 400, 'ml', '국/찌개'),
('설렁탕', 300, 20, 8, 20, 400, 'ml', '국/찌개'),
('삼계탕', 450, 30, 20, 28, 500, 'ml', '국/찌개'),
('청국장', 180, 12, 15, 8, 250, 'ml', '국/찌개'),
('매운탕', 200, 22, 8, 8, 350, 'ml', '국/찌개');

-- 육류
INSERT INTO foods (name, calories, protein, carbs, fat, serving_size, unit, category) VALUES
('삼겹살', 518, 17, 0, 50, 100, 'g', '육류'),
('목살', 280, 18, 0, 22, 100, 'g', '육류'),
('소고기(등심)', 250, 20, 0, 18, 100, 'g', '육류'),
('닭가슴살', 165, 31, 0, 3.6, 100, 'g', '육류'),
('닭다리', 220, 20, 0, 15, 100, 'g', '육류'),
('불고기', 250, 20, 10, 15, 150, 'g', '육류'),
('갈비', 380, 22, 8, 28, 150, 'g', '육류'),
('제육볶음', 280, 22, 12, 18, 150, 'g', '육류'),
('닭갈비', 300, 25, 15, 15, 200, 'g', '육류'),
('닭볶음탕', 280, 22, 12, 16, 200, 'g', '육류'),
('족발', 350, 25, 5, 26, 150, 'g', '육류'),
('보쌈', 320, 22, 3, 24, 150, 'g', '육류');

-- 생선류
INSERT INTO foods (name, calories, protein, carbs, fat, serving_size, unit, category) VALUES
('고등어구이', 262, 22, 0, 19, 100, 'g', '생선'),
('연어', 208, 20, 0, 13, 100, 'g', '생선'),
('참치', 130, 28, 0, 1, 100, 'g', '생선'),
('갈치구이', 180, 20, 0, 10, 100, 'g', '생선'),
('삼치구이', 200, 22, 0, 12, 100, 'g', '생선'),
('조기구이', 150, 18, 0, 8, 100, 'g', '생선'),
('광어회', 120, 25, 0, 2, 100, 'g', '생선'),
('연어회', 180, 20, 0, 10, 100, 'g', '생선'),
('생선까스', 280, 18, 20, 15, 150, 'g', '생선');

-- 채소/반찬류
INSERT INTO foods (name, calories, protein, carbs, fat, serving_size, unit, category) VALUES
('배추김치', 18, 1, 3, 0.2, 100, 'g', '반찬'),
('깍두기', 25, 1, 5, 0.3, 100, 'g', '반찬'),
('나박김치', 15, 1, 3, 0.1, 100, 'g', '반찬'),
('시금치나물', 35, 3, 4, 1, 100, 'g', '반찬'),
('콩나물무침', 30, 3, 4, 0.5, 100, 'g', '반찬'),
('숙주나물', 25, 3, 3, 0.3, 100, 'g', '반찬'),
('미역초무침', 20, 2, 3, 0.2, 100, 'g', '반찬'),
('오이무침', 15, 1, 3, 0.1, 100, 'g', '반찬'),
('계란찜', 120, 10, 2, 8, 100, 'g', '반찬'),
('계란말이', 150, 12, 3, 10, 100, 'g', '반찬'),
('멸치볶음', 120, 15, 5, 5, 50, 'g', '반찬'),
('어묵볶음', 100, 8, 10, 4, 80, 'g', '반찬'),
('감자조림', 120, 2, 25, 2, 100, 'g', '반찬'),
('연근조림', 100, 2, 22, 1, 100, 'g', '반찬'),
('잡채', 180, 5, 30, 5, 150, 'g', '반찬');

-- 면류
INSERT INTO foods (name, calories, protein, carbs, fat, serving_size, unit, category) VALUES
('라면', 510, 10, 80, 16, 120, 'g', '면류'),
('짜장면', 580, 18, 95, 12, 400, 'g', '면류'),
('짬뽕', 500, 20, 70, 15, 450, 'g', '면류'),
('칼국수', 400, 12, 70, 8, 400, 'g', '면류'),
('비빔국수', 450, 10, 80, 10, 350, 'g', '면류'),
('냉면', 480, 12, 85, 8, 400, 'g', '면류'),
('잔치국수', 380, 10, 65, 8, 350, 'g', '면류'),
('쫄면', 500, 12, 90, 10, 400, 'g', '면류'),
('우동', 420, 12, 75, 8, 400, 'g', '면류'),
('파스타', 450, 15, 70, 12, 350, 'g', '면류'),
('스파게티', 480, 14, 75, 14, 380, 'g', '면류');

-- 분식류
INSERT INTO foods (name, calories, protein, carbs, fat, serving_size, unit, category) VALUES
('떡볶이', 380, 8, 70, 8, 300, 'g', '분식'),
('순대', 250, 15, 20, 12, 150, 'g', '분식'),
('튀김', 280, 5, 30, 15, 100, 'g', '분식'),
('어묵', 80, 8, 8, 2, 100, 'g', '분식'),
('만두', 250, 10, 30, 10, 100, 'g', '분식'),
('라볶이', 450, 10, 75, 12, 350, 'g', '분식'),
('치즈떡볶이', 450, 12, 70, 15, 350, 'g', '분식'),
('핫도그', 350, 10, 35, 18, 120, 'g', '분식');

-- 빵/과자류
INSERT INTO foods (name, calories, protein, carbs, fat, serving_size, unit, category) VALUES
('식빵', 270, 8, 50, 4, 100, 'g', '빵/과자'),
('크로와상', 406, 8, 46, 21, 100, 'g', '빵/과자'),
('베이글', 280, 10, 55, 2, 100, 'g', '빵/과자'),
('도넛', 420, 5, 50, 22, 100, 'g', '빵/과자'),
('케이크', 350, 5, 45, 18, 100, 'g', '빵/과자'),
('쿠키', 500, 6, 60, 25, 100, 'g', '빵/과자'),
('마카롱', 450, 5, 55, 20, 100, 'g', '빵/과자');

-- 음료류
INSERT INTO foods (name, calories, protein, carbs, fat, serving_size, unit, category) VALUES
('아메리카노', 5, 0.3, 1, 0, 240, 'ml', '음료'),
('카페라떼', 150, 8, 15, 6, 240, 'ml', '음료'),
('카푸치노', 120, 6, 12, 5, 240, 'ml', '음료'),
('콜라', 42, 0, 10.6, 0, 100, 'ml', '음료'),
('사이다', 40, 0, 10, 0, 100, 'ml', '음료'),
('오렌지주스', 45, 0.5, 11, 0, 100, 'ml', '음료'),
('우유', 60, 3, 5, 3, 100, 'ml', '음료'),
('두유', 50, 4, 4, 2.5, 100, 'ml', '음료'),
('녹차', 2, 0, 0, 0, 240, 'ml', '음료'),
('홍차', 2, 0, 0.5, 0, 240, 'ml', '음료');

-- 과일류
INSERT INTO foods (name, calories, protein, carbs, fat, serving_size, unit, category) VALUES
('사과', 52, 0.3, 14, 0.2, 100, 'g', '과일'),
('바나나', 89, 1.1, 23, 0.3, 100, 'g', '과일'),
('포도', 69, 0.7, 18, 0.2, 100, 'g', '과일'),
('딸기', 32, 0.7, 8, 0.3, 100, 'g', '과일'),
('오렌지', 47, 0.9, 12, 0.1, 100, 'g', '과일'),
('수박', 30, 0.6, 8, 0.1, 100, 'g', '과일'),
('참외', 35, 1, 8, 0.1, 100, 'g', '과일'),
('복숭아', 39, 0.9, 10, 0.3, 100, 'g', '과일'),
('키위', 61, 1.1, 15, 0.5, 100, 'g', '과일'),
('망고', 60, 0.8, 15, 0.4, 100, 'g', '과일');

-- 패스트푸드
INSERT INTO foods (name, calories, protein, carbs, fat, serving_size, unit, category) VALUES
('햄버거', 550, 25, 45, 30, 200, 'g', '패스트푸드'),
('치즈버거', 600, 28, 48, 35, 220, 'g', '패스트푸드'),
('치킨버거', 500, 22, 45, 25, 200, 'g', '패스트푸드'),
('감자튀김', 312, 3, 41, 15, 100, 'g', '패스트푸드'),
('피자', 270, 12, 33, 10, 100, 'g', '패스트푸드'),
('치킨너겟', 280, 15, 18, 18, 100, 'g', '패스트푸드'),
('치킨텐더', 260, 20, 15, 14, 100, 'g', '패스트푸드');

-- 치킨류
INSERT INTO foods (name, calories, protein, carbs, fat, serving_size, unit, category) VALUES
('후라이드치킨', 280, 25, 10, 18, 100, 'g', '치킨'),
('양념치킨', 320, 24, 20, 16, 100, 'g', '치킨'),
('간장치킨', 310, 24, 18, 15, 100, 'g', '치킨'),
('마늘치킨', 300, 24, 15, 16, 100, 'g', '치킨'),
('순살치킨', 290, 28, 12, 15, 100, 'g', '치킨');

-- 간식류
INSERT INTO foods (name, calories, protein, carbs, fat, serving_size, unit, category) VALUES
('아이스크림', 200, 3, 24, 10, 100, 'g', '간식'),
('초콜릿', 550, 6, 60, 32, 100, 'g', '간식'),
('과자', 500, 5, 65, 25, 100, 'g', '간식'),
('젤리', 340, 5, 80, 0, 100, 'g', '간식'),
('요거트', 100, 4, 15, 2, 100, 'g', '간식'),
('그릭요거트', 120, 10, 8, 5, 100, 'g', '간식'),
('견과류', 600, 15, 20, 55, 100, 'g', '간식'),
('아몬드', 580, 21, 22, 50, 100, 'g', '간식');

-- ====================================
-- 테스트 사용자 데이터 삽입
-- ====================================

-- 사용자 1: test@test.com (비밀번호: password123)
INSERT INTO users (email, password, name, allergies, preferences, height, weight, gender, activity_level) 
VALUES (
  'test@test.com',
  '$2a$10$O9QmsPdeA/cjVu4FvMeue.Fw109f086PE8PY3dR2dDeVVQWee2IqO',
  '테스트 사용자',
  '["우유", "계란"]',
  '["한식 선호"]',
  170,
  65,
  'male',
  'moderate'
);

-- 사용자 2: user@example.com (비밀번호: test1234)
INSERT INTO users (email, password, name, allergies, preferences, height, weight, gender, activity_level) 
VALUES (
  'user@example.com',
  '$2a$10$vKxPnVJF8pONRrwY.oRUTOGc7v/R1qnTpvkL3ZhcCL5g3CbMyxPZi',
  '일반 사용자',
  '["새우젓"]',
  '["매운 음식 선호"]',
  165,
  55,
  'female',
  'active'
);

-- 사용자 목표 설정
INSERT INTO user_goals (user_id, daily_calorie_goal, protein_goal, carbs_goal, fat_goal, meals_per_day)
VALUES 
  (1, 2000, 60, 250, 55, 3),
  (2, 1800, 50, 220, 50, 3);

-- ====================================
-- 샘플 식사 기록 (테스트용)
-- ====================================

-- 오늘 날짜의 샘플 식사 기록
INSERT INTO meal_records (user_id, meal_type, meal_time, total_calories, total_protein, total_carbs, total_fat, notes)
VALUES 
  (1, 'breakfast', NOW(), 460, 16, 73, 6.5, '아침 식사'),
  (1, 'lunch', DATE_ADD(NOW(), INTERVAL 4 HOUR), 730, 32, 88, 26.5, '점심 식사');

-- 식사에 포함된 음식
INSERT INTO meal_foods (meal_id, food_id, serving_size, quantity) VALUES
  (1, 1, 210, 1),  -- 흰쌀밥
  (1, 11, 250, 1), -- 된장찌개
  (2, 1, 210, 1),  -- 흰쌀밥
  (2, 12, 250, 1), -- 김치찌개
  (2, 26, 150, 1); -- 불고기

-- ====================================
-- 최종 확인 쿼리
-- ====================================

-- 테이블 구조 확인
SHOW TABLES;

-- 사용자 데이터 확인
SELECT id, email, name FROM users;

-- 음식 데이터 개수 확인
SELECT category, COUNT(*) as count FROM foods GROUP BY category;

-- ====================================
-- 데이터베이스 생성 완료
-- ====================================
COMMIT;