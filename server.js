const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const app = express();

// 미들웨어
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// 업로드 디렉토리 설정
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Multer 설정 (이미지 업로드용)
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  }
});
const upload = multer({ storage: storage, limits: { fileSize: 10 * 1024 * 1024 } });

// 정적 파일 서빙
app.use('/uploads', express.static(uploadDir));

// MySQL 커넥션 풀
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'diet101_db',
  port: process.env.DB_PORT || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// 에러 핸들링
pool.on('error', (err) => {
  console.error('MySQL Pool Error:', err);
});

// JWT 인증 미들웨어
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: '토큰이 필요합니다.' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ message: '유효하지 않은 토큰입니다.' });
    }
    req.user = user;
    next();
  });
};

// ==================== 인증 API ====================

// 회원가입
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, name, allergies, preferences } = req.body;

    // 입력값 검증
    if (!email || !password || !name) {
      return res.status(400).json({ message: '이메일, 비밀번호, 이름은 필수입니다.' });
    }

    if (password.length < 6) {
      return res.status(400).json({ message: '비밀번호는 최소 6자 이상이어야 합니다.' });
    }

    const conn = await pool.getConnection();

    try {
      // 이미 등록된 이메일 확인
      const [rows] = await conn.query(
        'SELECT id FROM users WHERE email = ?',
        [email]
      );

      if (rows.length > 0) {
        await conn.release();
        return res.status(409).json({ message: '이미 등록된 이메일입니다.' });
      }

      // 비밀번호 해싱
      const hashedPassword = await bcrypt.hash(password, 10);

      // 사용자 저장
      await conn.query(
        'INSERT INTO users (email, password, name, allergies, preferences) VALUES (?, ?, ?, ?, ?)',
        [
          email,
          hashedPassword,
          name,
          JSON.stringify(allergies || []),
          JSON.stringify(preferences || [])
        ]
      );

      await conn.release();
      res.status(201).json({ message: '회원가입이 완료되었습니다.' });
    } catch (err) {
      await conn.release();
      throw err;
    }
  } catch (error) {
    console.error('회원가입 오류:', error);
    res.status(500).json({ message: '회원가입 중 오류가 발생했습니다.' });
  }
});

// 로그인
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // 입력값 검증
    if (!email || !password) {
      return res.status(400).json({ message: '이메일과 비밀번호는 필수입니다.' });
    }

    const conn = await pool.getConnection();

    try {
      // 사용자 조회
      const [rows] = await conn.query(
        'SELECT id, email, password, name, allergies, preferences FROM users WHERE email = ?',
        [email]
      );

      if (rows.length === 0) {
        await conn.release();
        return res.status(401).json({ message: '이메일 또는 비밀번호가 일치하지 않습니다.' });
      }

      const user = rows[0];

      // 비밀번호 확인
      const passwordMatch = await bcrypt.compare(password, user.password);
      if (!passwordMatch) {
        await conn.release();
        return res.status(401).json({ message: '이메일 또는 비밀번호가 일치하지 않습니다.' });
      }

      // JWT 토큰 생성
      const token = jwt.sign(
        { id: user.id, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
      );

      await conn.release();

      res.json({
        message: '로그인 성공',
        token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          allergies: JSON.parse(user.allergies || '[]'),
          preferences: JSON.parse(user.preferences || '[]')
        }
      });
    } catch (err) {
      await conn.release();
      throw err;
    }
  } catch (error) {
    console.error('로그인 오류:', error);
    res.status(500).json({ message: '로그인 중 오류가 발생했습니다.' });
  }
});

// ==================== 식단 API ====================

// 날짜별 식단 조회
app.get('/api/meals', authenticateToken, async (req, res) => {
  try {
    const { date } = req.query;

    if (!date) {
      return res.status(400).json({ message: '날짜(date) 파라미터가 필요합니다.' });
    }

    const conn = await pool.getConnection();

    try {
      const [rows] = await conn.query(
        'SELECT * FROM meals WHERE date = ?',
        [date]
      );

      if (rows.length === 0) {
        await conn.release();
        return res.status(404).json({
          date,
          breakfast: [],
          lunch: [],
          dinner: []
        });
      }

      const meal = rows[0];
      await conn.release();

      res.json({
        date,
        breakfast: JSON.parse(meal.breakfast || '[]'),
        lunch: JSON.parse(meal.lunch || '[]'),
        dinner: JSON.parse(meal.dinner || '[]')
      });
    } catch (err) {
      await conn.release();
      throw err;
    }
  } catch (error) {
    console.error('식단 조회 오류:', error);
    res.status(500).json({ message: '식단 조회 중 오류가 발생했습니다.' });
  }
});

// 식단 검색 (관리자용)
app.get('/api/meals/search', authenticateToken, async (req, res) => {
  try {
    const { q } = req.query;

    if (!q) {
      return res.status(400).json({ message: '검색어(q) 파라미터가 필요합니다.' });
    }

    const conn = await pool.getConnection();

    try {
      // 모든 식단 가져오기
      const [rows] = await conn.query('SELECT * FROM meals');

      const results = [];
      rows.forEach(row => {
        const breakfast = JSON.parse(row.breakfast || '[]');
        const lunch = JSON.parse(row.lunch || '[]');
        const dinner = JSON.parse(row.dinner || '[]');

        const allMeals = [...breakfast, ...lunch, ...dinner];
        allMeals.forEach(meal => {
          if (meal.name.includes(q)) {
            results.push(meal);
          }
        });
      });

      await conn.release();
      res.json(results);
    } catch (err) {
      await conn.release();
      throw err;
    }
  } catch (error) {
    console.error('식단 검색 오류:', error);
    res.status(500).json({ message: '식단 검색 중 오류가 발생했습니다.' });
  }
});

// ==================== 사용자 프로필 API ====================

// 프로필 조회
app.get('/api/profile', authenticateToken, async (req, res) => {
  try {
    const conn = await pool.getConnection();

    try {
      const [rows] = await conn.query(
        'SELECT id, email, name, allergies, preferences FROM users WHERE id = ?',
        [req.user.id]
      );

      if (rows.length === 0) {
        await conn.release();
        return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
      }

      const user = rows[0];
      await conn.release();

      res.json({
        id: user.id,
        email: user.email,
        name: user.name,
        allergies: JSON.parse(user.allergies || '[]'),
        preferences: JSON.parse(user.preferences || '[]')
      });
    } catch (err) {
      await conn.release();
      throw err;
    }
  } catch (error) {
    console.error('프로필 조회 오류:', error);
    res.status(500).json({ message: '프로필 조회 중 오류가 발생했습니다.' });
  }
});

// 프로필 업데이트
app.put('/api/profile', authenticateToken, async (req, res) => {
  try {
    const { name, allergies, preferences } = req.body;

    if (!name) {
      return res.status(400).json({ message: '이름은 필수입니다.' });
    }

    const conn = await pool.getConnection();

    try {
      await conn.query(
        'UPDATE users SET name = ?, allergies = ?, preferences = ? WHERE id = ?',
        [
          name,
          JSON.stringify(allergies || []),
          JSON.stringify(preferences || []),
          req.user.id
        ]
      );

      await conn.release();

      res.json({ message: '프로필이 업데이트되었습니다.' });
    } catch (err) {
      await conn.release();
      throw err;
    }
  } catch (error) {
    console.error('프로필 업데이트 오류:', error);
    res.status(500).json({ message: '프로필 업데이트 중 오류가 발생했습니다.' });
  }
});

// ==================== 사용자 목표 API ====================

// 사용자 목표 조회
app.get('/api/goals', authenticateToken, async (req, res) => {
  try {
    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.query(
        'SELECT * FROM user_goals WHERE user_id = ?',
        [req.user.id]
      );

      if (rows.length === 0) {
        // 기본 목표 반환
        return res.json({
          dailyCalorieGoal: 2000,
          proteinGoal: 50,
          carbsGoal: 250,
          fatGoal: 65,
          mealsPerDay: 3
        });
      }

      const goals = rows[0];
      res.json({
        dailyCalorieGoal: goals.daily_calorie_goal,
        proteinGoal: goals.protein_goal,
        carbsGoal: goals.carbs_goal,
        fatGoal: goals.fat_goal,
        mealsPerDay: goals.meals_per_day
      });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('목표 조회 오류:', error);
    res.status(500).json({ message: '목표 조회 중 오류가 발생했습니다.' });
  }
});

// 사용자 목표 업데이트
app.put('/api/goals', authenticateToken, async (req, res) => {
  try {
    const { dailyCalorieGoal, proteinGoal, carbsGoal, fatGoal, mealsPerDay } = req.body;
    const conn = await pool.getConnection();
    try {
      await conn.query(`
        INSERT INTO user_goals (user_id, daily_calorie_goal, protein_goal, carbs_goal, fat_goal, meals_per_day)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
          daily_calorie_goal = VALUES(daily_calorie_goal),
          protein_goal = VALUES(protein_goal),
          carbs_goal = VALUES(carbs_goal),
          fat_goal = VALUES(fat_goal),
          meals_per_day = VALUES(meals_per_day)
      `, [req.user.id, dailyCalorieGoal || 2000, proteinGoal || 50, carbsGoal || 250, fatGoal || 65, mealsPerDay || 3]);

      res.json({ message: '목표가 업데이트되었습니다.' });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('목표 업데이트 오류:', error);
    res.status(500).json({ message: '목표 업데이트 중 오류가 발생했습니다.' });
  }
});

// ==================== 음식 데이터베이스 API ====================

// 모든 음식 조회
app.get('/api/foods', async (req, res) => {
  try {
    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.query('SELECT * FROM foods ORDER BY name');
      res.json(rows);
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('음식 조회 오류:', error);
    res.status(500).json({ message: '음식 조회 중 오류가 발생했습니다.' });
  }
});

// 음식 검색
app.get('/api/foods/search', async (req, res) => {
  try {
    const { q, category } = req.query;
    const conn = await pool.getConnection();
    try {
      let query = 'SELECT * FROM foods WHERE 1=1';
      const params = [];

      if (q) {
        query += ' AND name LIKE ?';
        params.push(`%${q}%`);
      }
      if (category) {
        query += ' AND category = ?';
        params.push(category);
      }

      query += ' ORDER BY name LIMIT 50';
      const [rows] = await conn.query(query, params);
      res.json(rows);
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('음식 검색 오류:', error);
    res.status(500).json({ message: '음식 검색 중 오류가 발생했습니다.' });
  }
});

// 음식 상세 조회
app.get('/api/foods/:id', async (req, res) => {
  try {
    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.query('SELECT * FROM foods WHERE id = ?', [req.params.id]);
      if (rows.length === 0) {
        return res.status(404).json({ message: '음식을 찾을 수 없습니다.' });
      }
      res.json(rows[0]);
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('음식 조회 오류:', error);
    res.status(500).json({ message: '음식 조회 중 오류가 발생했습니다.' });
  }
});

// 카테고리 목록 조회
app.get('/api/categories', async (req, res) => {
  try {
    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.query('SELECT DISTINCT category FROM foods WHERE category IS NOT NULL ORDER BY category');
      res.json(rows.map(row => row.category));
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('카테고리 조회 오류:', error);
    res.status(500).json({ message: '카테고리 조회 중 오류가 발생했습니다.' });
  }
});

// ==================== 식사 기록 API (Diet101 스타일) ====================

// 사용자별 식사 기록 조회
app.get('/api/diet', authenticateToken, async (req, res) => {
  try {
    const { date } = req.query;
    const conn = await pool.getConnection();
    try {
      let query = `
        SELECT m.*, 
          GROUP_CONCAT(CONCAT(mf.food_id, ':', mf.serving_size, ':', mf.quantity) SEPARATOR ',') as food_entries
        FROM meal_records m
        LEFT JOIN meal_foods mf ON m.id = mf.meal_id
        WHERE m.user_id = ?
      `;
      const params = [req.user.id];

      if (date) {
        query += ' AND DATE(m.meal_time) = ?';
        params.push(date);
      }

      query += ' GROUP BY m.id ORDER BY m.meal_time DESC';
      const [rows] = await conn.query(query, params);

      // 음식 정보 조회
      const meals = await Promise.all(rows.map(async (meal) => {
        const foodItems = [];
        if (meal.food_entries) {
          const entries = meal.food_entries.split(',');
          for (const entry of entries) {
            const [foodId, servingSize, quantity] = entry.split(':');
            const [foods] = await conn.query('SELECT * FROM foods WHERE id = ?', [foodId]);
            if (foods.length > 0) {
              foodItems.push({
                foodItem: foods[0],
                servingSize: parseFloat(servingSize),
                quantity: parseFloat(quantity)
              });
            }
          }
        }
        return {
          id: meal.id,
          timestamp: meal.meal_time,
          mealType: meal.meal_type,
          foodItems,
          photoPath: meal.photo_path,
          notes: meal.notes,
          totalCalories: meal.total_calories,
          totalProtein: meal.total_protein,
          totalCarbs: meal.total_carbs,
          totalFat: meal.total_fat
        };
      }));

      res.json(meals);
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('식사 기록 조회 오류:', error);
    res.status(500).json({ message: '식사 기록 조회 중 오류가 발생했습니다.' });
  }
});

// 식사 기록 추가
app.post('/api/diet', authenticateToken, async (req, res) => {
  try {
    const { mealType, timestamp, foodItems, notes } = req.body;
    const conn = await pool.getConnection();

    try {
      await conn.beginTransaction();

      // 총 영양소 계산
      let totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0;
      for (const item of foodItems) {
        const multiplier = item.servingSize / item.foodItem.servingSize;
        totalCalories += item.foodItem.calories * multiplier;
        totalProtein += item.foodItem.protein * multiplier;
        totalCarbs += item.foodItem.carbs * multiplier;
        totalFat += item.foodItem.fat * multiplier;
      }

      // 식사 기록 저장
      const [result] = await conn.query(`
        INSERT INTO meal_records (user_id, meal_type, meal_time, total_calories, total_protein, total_carbs, total_fat, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `, [req.user.id, mealType, timestamp, totalCalories, totalProtein, totalCarbs, totalFat, notes]);

      const mealId = result.insertId;

      // 음식 항목 저장
      for (const item of foodItems) {
        await conn.query(`
          INSERT INTO meal_foods (meal_id, food_id, serving_size, quantity)
          VALUES (?, ?, ?, ?)
        `, [mealId, item.foodItem.id, item.servingSize, item.quantity || 1]);
      }

      await conn.commit();
      res.status(201).json({ message: '식사 기록이 저장되었습니다.', id: mealId });
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('식사 기록 저장 오류:', error);
    res.status(500).json({ message: '식사 기록 저장 중 오류가 발생했습니다.' });
  }
});

// 식사 기록 삭제
app.delete('/api/diet/:id', authenticateToken, async (req, res) => {
  try {
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      await conn.query('DELETE FROM meal_foods WHERE meal_id = ?', [req.params.id]);
      await conn.query('DELETE FROM meal_records WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
      await conn.commit();
      res.json({ message: '식사 기록이 삭제되었습니다.' });
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('식사 기록 삭제 오류:', error);
    res.status(500).json({ message: '식사 기록 삭제 중 오류가 발생했습니다.' });
  }
});

// ==================== 영양 통계 API ====================

// 일일 영양 통계
app.get('/api/nutrition/daily', authenticateToken, async (req, res) => {
  try {
    const { date } = req.query;
    const targetDate = date || new Date().toISOString().split('T')[0];
    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.query(`
        SELECT 
          COALESCE(SUM(total_calories), 0) as calories,
          COALESCE(SUM(total_protein), 0) as protein,
          COALESCE(SUM(total_carbs), 0) as carbs,
          COALESCE(SUM(total_fat), 0) as fat
        FROM meal_records
        WHERE user_id = ? AND DATE(meal_time) = ?
      `, [req.user.id, targetDate]);

      res.json(rows[0]);
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('일일 영양 통계 오류:', error);
    res.status(500).json({ message: '통계 조회 중 오류가 발생했습니다.' });
  }
});

// 주간 영양 통계
app.get('/api/nutrition/weekly', authenticateToken, async (req, res) => {
  try {
    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.query(`
        SELECT 
          DATE(meal_time) as date,
          COALESCE(SUM(total_calories), 0) as calories,
          COALESCE(SUM(total_protein), 0) as protein,
          COALESCE(SUM(total_carbs), 0) as carbs,
          COALESCE(SUM(total_fat), 0) as fat
        FROM meal_records
        WHERE user_id = ? AND meal_time >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        GROUP BY DATE(meal_time)
        ORDER BY date
      `, [req.user.id]);

      res.json(rows);
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('주간 영양 통계 오류:', error);
    res.status(500).json({ message: '통계 조회 중 오류가 발생했습니다.' });
  }
});

// 월간 영양 통계
app.get('/api/nutrition/monthly', authenticateToken, async (req, res) => {
  try {
    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.query(`
        SELECT 
          DATE(meal_time) as date,
          COALESCE(SUM(total_calories), 0) as calories,
          COALESCE(SUM(total_protein), 0) as protein,
          COALESCE(SUM(total_carbs), 0) as carbs,
          COALESCE(SUM(total_fat), 0) as fat
        FROM meal_records
        WHERE user_id = ? AND meal_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        GROUP BY DATE(meal_time)
        ORDER BY date
      `, [req.user.id]);

      res.json(rows);
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('월간 영양 통계 오류:', error);
    res.status(500).json({ message: '통계 조회 중 오류가 발생했습니다.' });
  }
});

// 음식 랭킹 (자주 먹은 음식)
app.get('/api/nutrition/ranking', authenticateToken, async (req, res) => {
  try {
    const { period } = req.query; // 'week' or 'month'
    const days = period === 'month' ? 30 : 7;
    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.query(`
        SELECT 
          f.name,
          f.calories,
          COUNT(*) as count
        FROM meal_foods mf
        JOIN meal_records m ON mf.meal_id = m.id
        JOIN foods f ON mf.food_id = f.id
        WHERE m.user_id = ? AND m.meal_time >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
        GROUP BY f.id
        ORDER BY count DESC
        LIMIT 10
      `, [req.user.id, days]);

      res.json(rows);
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('음식 랭킹 조회 오류:', error);
    res.status(500).json({ message: '랭킹 조회 중 오류가 발생했습니다.' });
  }
});

// ==================== 음식 추천 API (Collaborative Filtering 기반) ====================

// 남은 칼로리 기반 음식 추천
app.get('/api/recommend', authenticateToken, async (req, res) => {
  try {
    const { remainingCalories, remainingMeals } = req.query;
    const targetCalories = parseInt(remainingCalories) / parseInt(remainingMeals || 1);
    
    const conn = await pool.getConnection();
    try {
      // 타겟 칼로리에 맞는 음식 추천 (±20% 범위)
      const [foods] = await conn.query(`
        SELECT * FROM foods 
        WHERE calories BETWEEN ? AND ?
        ORDER BY RAND()
        LIMIT 10
      `, [targetCalories * 0.8, targetCalories * 1.2]);

      // 조합 추천 (여러 음식 조합)
      const [combinationFoods] = await conn.query(`
        SELECT * FROM foods 
        WHERE calories < ?
        ORDER BY RAND()
        LIMIT 20
      `, [targetCalories * 0.7]);

      // 간단한 조합 생성
      const combinations = [];
      for (let i = 0; i < Math.min(5, combinationFoods.length - 1); i++) {
        const food1 = combinationFoods[i];
        const food2 = combinationFoods[i + 1];
        const totalCal = food1.calories + food2.calories;
        if (totalCal >= targetCalories * 0.8 && totalCal <= targetCalories * 1.2) {
          combinations.push({
            foods: [food1, food2],
            totalCalories: totalCal,
            totalProtein: food1.protein + food2.protein,
            totalCarbs: food1.carbs + food2.carbs,
            totalFat: food1.fat + food2.fat
          });
        }
      }

      res.json({
        singleFoods: foods,
        combinations: combinations.slice(0, 5)
      });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('음식 추천 오류:', error);
    res.status(500).json({ message: '추천 조회 중 오류가 발생했습니다.' });
  }
});

// ==================== OCR 영양성분표 인식 API ====================

// 영양성분표 이미지 업로드 및 분석 (시뮬레이션)
app.post('/api/ocr/nutrition', upload.single('image'), async (req, res) => {
  try {
    // 실제 구현에서는 EasyOCR API 호출
    // 여기서는 시뮬레이션 결과 반환
    const simulatedResult = {
      success: true,
      data: {
        calories: Math.floor(Math.random() * 300) + 100,
        protein: Math.floor(Math.random() * 20) + 5,
        carbs: Math.floor(Math.random() * 50) + 20,
        fat: Math.floor(Math.random() * 15) + 3,
        servingSize: 100,
        sodium: Math.floor(Math.random() * 500) + 100,
        sugar: Math.floor(Math.random() * 15) + 2
      },
      rawText: '영양정보 (1회 제공량 기준)\n열량: 250kcal\n탄수화물: 35g\n단백질: 12g\n지방: 8g'
    };

    res.json(simulatedResult);
  } catch (error) {
    console.error('OCR 분석 오류:', error);
    res.status(500).json({ message: 'OCR 분석 중 오류가 발생했습니다.' });
  }
});

// ==================== AI 음식 인식 API ====================

// 음식 이미지 분석 (시뮬레이션)
app.post('/api/ai/recognize', upload.single('image'), async (req, res) => {
  try {
    const conn = await pool.getConnection();
    try {
      // 실제 구현에서는 YOLO 모델 API 호출
      // 여기서는 랜덤 음식 반환 (시뮬레이션)
      const [foods] = await conn.query('SELECT * FROM foods ORDER BY RAND() LIMIT 3');
      
      const detections = foods.map(food => ({
        food: food,
        confidence: (Math.random() * 0.3 + 0.7).toFixed(2),
        boundingBox: {
          x: Math.floor(Math.random() * 100),
          y: Math.floor(Math.random() * 100),
          width: Math.floor(Math.random() * 200) + 100,
          height: Math.floor(Math.random() * 200) + 100
        }
      }));

      res.json({
        success: true,
        detections
      });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('음식 인식 오류:', error);
    res.status(500).json({ message: '음식 인식 중 오류가 발생했습니다.' });
  }
});

// ==================== 헬스 체크 ====================

app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok',
    message: 'Diet101 백엔드 서버가 정상적으로 작동 중입니다.',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// ==================== 데이터베이스 초기화 엔드포인트 ====================

app.post('/api/init-db', async (req, res) => {
  try {
    const conn = await pool.getConnection();
    try {
      // 테이블 생성 쿼리 실행
      await conn.query(`
        CREATE TABLE IF NOT EXISTS user_goals (
          id INT AUTO_INCREMENT PRIMARY KEY,
          user_id INT NOT NULL,
          daily_calorie_goal DOUBLE DEFAULT 2000,
          protein_goal DOUBLE DEFAULT 50,
          carbs_goal DOUBLE DEFAULT 250,
          fat_goal DOUBLE DEFAULT 65,
          meals_per_day INT DEFAULT 3,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          UNIQUE KEY unique_user (user_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
      `);

      await conn.query(`
        CREATE TABLE IF NOT EXISTS foods (
          id INT AUTO_INCREMENT PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          calories DOUBLE NOT NULL,
          protein DOUBLE DEFAULT 0,
          carbs DOUBLE DEFAULT 0,
          fat DOUBLE DEFAULT 0,
          serving_size DOUBLE DEFAULT 100,
          unit VARCHAR(20) DEFAULT 'g',
          category VARCHAR(100),
          image_url VARCHAR(500),
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
      `);

      await conn.query(`
        CREATE TABLE IF NOT EXISTS meal_records (
          id INT AUTO_INCREMENT PRIMARY KEY,
          user_id INT NOT NULL,
          meal_type VARCHAR(50) NOT NULL,
          meal_time DATETIME NOT NULL,
          total_calories DOUBLE DEFAULT 0,
          total_protein DOUBLE DEFAULT 0,
          total_carbs DOUBLE DEFAULT 0,
          total_fat DOUBLE DEFAULT 0,
          photo_path VARCHAR(500),
          notes TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
      `);

      await conn.query(`
        CREATE TABLE IF NOT EXISTS meal_foods (
          id INT AUTO_INCREMENT PRIMARY KEY,
          meal_id INT NOT NULL,
          food_id INT NOT NULL,
          serving_size DOUBLE DEFAULT 100,
          quantity DOUBLE DEFAULT 1,
          FOREIGN KEY (meal_id) REFERENCES meal_records(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
      `);

      res.json({ message: '데이터베이스가 초기화되었습니다.' });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('DB 초기화 오류:', error);
    res.status(500).json({ message: 'DB 초기화 중 오류가 발생했습니다.' });
  }
});

// ==================== 404 핸들러 ====================

app.use((req, res) => {
  res.status(404).json({ message: '요청한 경로를 찾을 수 없습니다.' });
});

// ==================== 에러 핸들러 ====================

app.use((err, req, res, next) => {
  console.error('서버 오류:', err);
  res.status(500).json({ message: '서버 오류가 발생했습니다.' });
});

// ==================== 서버 시작 ====================

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`========================================`);
  console.log(`Diet101 백엔드 서버 시작`);
  console.log(`포트: ${PORT}`);
  console.log(`환경: ${process.env.NODE_ENV || 'development'}`);
  console.log(`========================================`);
  console.log(`API 주소: http://localhost:${PORT}/api`);
  console.log(`헬스체크: http://localhost:${PORT}/api/health`);
  console.log(`========================================`);
});
