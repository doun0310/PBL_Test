-- ====================================
-- 식단 관리 앱 MySQL 데이터베이스 생성
-- ====================================

-- 1. 기존 데이터베이스 삭제 (필요시)
DROP DATABASE IF EXISTS meal_management_db;

-- 2. 데이터베이스 생성
CREATE DATABASE meal_management_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- 3. 데이터베이스 선택
USE meal_management_db;

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
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',
  INDEX idx_email (email),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='사용자 정보 테이블';

-- ====================================
-- 식단 테이블 생성
-- ====================================
CREATE TABLE meals (
  id INT AUTO_INCREMENT PRIMARY KEY COMMENT '식단 고유번호',
  date DATE UNIQUE NOT NULL COMMENT '식단 날짜 (고유)',
  breakfast LONGTEXT COMMENT '아침 식단 (JSON)',
  lunch LONGTEXT COMMENT '점심 식단 (JSON)',
  dinner LONGTEXT COMMENT '저녁 식단 (JSON)',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',
  INDEX idx_date (date),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='식단 정보 테이블';

-- ====================================
-- 샘플 데이터 삽입
-- ====================================

-- 아침 식단 데이터
SET @breakfast_2025_11_03 = '[
  {
    "name": "흰쌀밥",
    "calories": 310,
    "protein": 6,
    "carbs": 68,
    "fat": 0.5,
    "allergens": []
  },
  {
    "name": "된장찌개",
    "calories": 120,
    "protein": 8,
    "carbs": 12,
    "fat": 4,
    "allergens": ["대두"]
  },
  {
    "name": "김치",
    "calories": 30,
    "protein": 2,
    "carbs": 5,
    "fat": 0.5,
    "allergens": ["새우젓"]
  }
]';

-- 점심 식단 데이터
SET @lunch_2025_11_03 = '[
  {
    "name": "흰쌀밥",
    "calories": 310,
    "protein": 6,
    "carbs": 68,
    "fat": 0.5,
    "allergens": []
  },
  {
    "name": "김치찌개",
    "calories": 180,
    "protein": 12,
    "carbs": 15,
    "fat": 8,
    "allergens": ["돼지고기", "대두"]
  },
  {
    "name": "불고기",
    "calories": 250,
    "protein": 20,
    "carbs": 10,
    "fat": 15,
    "allergens": ["쇠고기", "대두"]
  },
  {
    "name": "시금치나물",
    "calories": 45,
    "protein": 3,
    "carbs": 6,
    "fat": 1,
    "allergens": []
  },
  {
    "name": "배추김치",
    "calories": 30,
    "protein": 2,
    "carbs": 5,
    "fat": 0.5,
    "allergens": ["새우젓"]
  }
]';

-- 저녁 식단 데이터
SET @dinner_2025_11_03 = '[
  {
    "name": "흰쌀밥",
    "calories": 310,
    "protein": 6,
    "carbs": 68,
    "fat": 0.5,
    "allergens": []
  },
  {
    "name": "미역국",
    "calories": 80,
    "protein": 5,
    "carbs": 8,
    "fat": 3,
    "allergens": ["조개"]
  },
  {
    "name": "제육볶음",
    "calories": 280,
    "protein": 22,
    "carbs": 12,
    "fat": 18,
    "allergens": ["돼지고기", "대두"]
  },
  {
    "name": "계란찜",
    "calories": 120,
    "protein": 10,
    "carbs": 2,
    "fat": 8,
    "allergens": ["계란"]
  },
  {
    "name": "깍두기",
    "calories": 25,
    "protein": 1,
    "carbs": 5,
    "fat": 0.3,
    "allergens": ["새우젓"]
  }
]';

-- 2025년 11월 3일 식단 삽입
INSERT INTO meals (date, breakfast, lunch, dinner) 
VALUES ('2025-11-03', @breakfast_2025_11_03, @lunch_2025_11_03, @dinner_2025_11_03);

-- 2025년 11월 4일 식단 데이터
SET @breakfast_2025_11_04 = '[
  {
    "name": "흰쌀밥",
    "calories": 310,
    "protein": 6,
    "carbs": 68,
    "fat": 0.5,
    "allergens": []
  },
  {
    "name": "계란국",
    "calories": 100,
    "protein": 8,
    "carbs": 5,
    "fat": 6,
    "allergens": ["계란"]
  },
  {
    "name": "김",
    "calories": 20,
    "protein": 2,
    "carbs": 2,
    "fat": 1,
    "allergens": []
  }
]';

SET @lunch_2025_11_04 = '[
  {
    "name": "카레라이스",
    "calories": 450,
    "protein": 15,
    "carbs": 75,
    "fat": 12,
    "allergens": ["밀", "우유", "대두"]
  },
  {
    "name": "치킨까스",
    "calories": 320,
    "protein": 25,
    "carbs": 28,
    "fat": 15,
    "allergens": ["밀", "계란", "대두"]
  },
  {
    "name": "샐러드",
    "calories": 60,
    "protein": 2,
    "carbs": 10,
    "fat": 2,
    "allergens": []
  },
  {
    "name": "단무지",
    "calories": 15,
    "protein": 0.5,
    "carbs": 3,
    "fat": 0.1,
    "allergens": []
  }
]';

SET @dinner_2025_11_04 = '[
  {
    "name": "비빔밥",
    "calories": 480,
    "protein": 18,
    "carbs": 72,
    "fat": 14,
    "allergens": ["계란", "대두", "쇠고기"]
  },
  {
    "name": "팽이버섯무침",
    "calories": 35,
    "protein": 2,
    "carbs": 5,
    "fat": 1,
    "allergens": ["대두"]
  },
  {
    "name": "김치",
    "calories": 30,
    "protein": 2,
    "carbs": 5,
    "fat": 0.5,
    "allergens": ["새우젓"]
  }
]';

-- 2025년 11월 4일 식단 삽입
INSERT INTO meals (date, breakfast, lunch, dinner) 
VALUES ('2025-11-04', @breakfast_2025_11_04, @lunch_2025_11_04, @dinner_2025_11_04);

-- ====================================
-- 테스트 사용자 데이터 삽입
-- ====================================

-- 사용자 1: student@school.com
-- 비밀번호: password123 (bcryptjs 해시값)
INSERT INTO users (email, password, name, allergies, preferences) 
VALUES (
  'student@school.com',
  '$2a$10$O9QmsPdeA/cjVu4FvMeue.Fw109f086PE8PY3dR2dDeVVQWee2IqO',
  '이도은',
  '["우유", "계란"]',
  '["채식 선호"]'
);

-- 사용자 2: user@school.com
-- 비밀번호: test1234 (bcryptjs 해시값)
INSERT INTO users (email, password, name, allergies, preferences) 
VALUES (
  'user@school.com',
  '$2a$10$vKxPnVJF8pONRrwY.oRUTOGc7v/R1qnTpvkL3ZhcCL5g3CbMyxPZi',
  '강성민',
  '["새우젓"]',
  '["매운 음식 선호"]'
);

-- ====================================
-- 최종 확인 쿼리
-- ====================================

-- 테이블 구조 확인
SHOW TABLES;

-- 사용자 데이터 확인
SELECT id, email, name, allergies, preferences FROM users;

-- 식단 데이터 확인
SELECT DATE_FORMAT(date, '%Y-%m-%d') as date, 
       (SELECT JSON_EXTRACT(breakfast, '$[0].name')) as first_breakfast,
       (SELECT JSON_EXTRACT(lunch, '$[0].name')) as first_lunch,
       (SELECT JSON_EXTRACT(dinner, '$[0].name')) as first_dinner
FROM meals;

-- ====================================
-- 데이터베이스 생성 완료
-- ====================================
COMMIT;