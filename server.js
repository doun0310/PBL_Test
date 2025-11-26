const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();

// 미들웨어
app.use(cors());
app.use(express.json());

// MySQL 커넥션 풀
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'meal_management_db',
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

// ==================== 헬스 체크 ====================

app.get('/api/health', (req, res) => {
  res.json({ message: '서버가 정상적으로 작동 중입니다.' });
});

// ==================== 404 핸들러 ====================

app.use((req, res) => {
  res.status(404).json({ message: '요청한 경로를 찾을 수 없습니다.' });
});

// ==================== 서버 시작 ====================

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`========================================`);
  console.log(`식단 관리 앱 백엔드 서버 시작`);
  console.log(`포트: ${PORT}`);
  console.log(`환경: ${process.env.NODE_ENV}`);
  console.log(`========================================`);
  console.log(`API 주소: http://localhost:${PORT}/api`);
  console.log(`========================================`);
});
