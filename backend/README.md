# Backend API Server Example
# This is a placeholder structure for the Node.js backend

## Structure
```
backend/
├── server.js              # Main application entry point
├── package.json           # Node.js dependencies
├── Dockerfile            # Docker configuration
├── .env.example          # Environment variables template
├── config/               # Configuration files
│   └── database.js       # Database configuration
├── routes/               # API routes
│   ├── auth.js          # Authentication routes
│   └── meals.js         # Meal management routes
├── controllers/          # Business logic
│   ├── authController.js
│   └── mealController.js
├── models/              # Database models
│   ├── User.js
│   └── Meal.js
└── middleware/          # Custom middleware
    └── auth.js          # JWT authentication middleware
```

## Setup Instructions

1. Install dependencies:
   ```bash
   npm install
   ```

2. Configure environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. Run the server:
   ```bash
   npm start
   ```

4. Run with Docker:
   ```bash
   docker build -t meal-management-backend .
   docker run -p 3000:3000 meal-management-backend
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login

### Meals
- `GET /api/meals?date=YYYY-MM-DD` - Get meals for a specific date
- `POST /api/meals` - Create a new meal
- `PUT /api/meals/:id` - Update a meal
- `DELETE /api/meals/:id` - Delete a meal

### User Profile
- `GET /api/profile` - Get user profile
- `PUT /api/profile` - Update user profile
- `PUT /api/profile/allergies` - Update user allergies
