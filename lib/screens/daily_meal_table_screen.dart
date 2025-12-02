import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal_entry.dart';
import '../models/user_goals.dart';
import '../services/meal_tracking_service.dart';

class DailyMealTableScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DailyMealTableScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<DailyMealTableScreen> createState() => _DailyMealTableScreenState();
}

class _DailyMealTableScreenState extends State<DailyMealTableScreen> {
  List<MealEntry> _meals = [];
  UserGoals _userGoals = UserGoals();
  bool _isLoading = true;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate;
    _loadMealData();
  }

  Future<void> _loadMealData() async {
    setState(() => _isLoading = true);

    try {
      final goals = await MealTrackingService.getUserGoals();
      final meals = await MealTrackingService.getMealsByDate(_currentDate);

      setState(() {
        _userGoals = goals;
        _meals = meals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    }
  }

  void _navigateToPreviousDay() {
    setState(() {
      _currentDate = _currentDate.subtract(const Duration(days: 1));
    });
    _loadMealData();
  }

  void _navigateToNextDay() {
    final today = DateTime.now();
    final isToday = _currentDate.year == today.year &&
        _currentDate.month == today.month &&
        _currentDate.day == today.day;

    if (!isToday) {
      setState(() {
        _currentDate = _currentDate.add(const Duration(days: 1));
      });
      _loadMealData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        title: const Text(
          '식단표',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _buildDateSelector(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildMealTable(),
                          const SizedBox(height: 16),
                          _buildNutritionAnalysis(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDateSelector() {
    final today = DateTime.now();
    final isToday = _currentDate.year == today.year &&
        _currentDate.month == today.month &&
        _currentDate.day == today.day;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _navigateToPreviousDay,
          ),
          Text(
            DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_currentDate),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isToday ? Colors.grey[300] : Colors.black,
            ),
            onPressed: isToday ? null : _navigateToNextDay,
          ),
        ],
      ),
    );
  }

  Widget _buildMealTable() {
    final mealsByType = <MealType, List<MealEntry>>{};
    for (var meal in _meals) {
      mealsByType.putIfAbsent(meal.mealType, () => []).add(meal);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    '구분',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 4,
                  child: Text(
                    '음식',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    '칼로리',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_meals.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                '등록된 식사가 없습니다',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            )
          else
            ...MealType.values.map((mealType) {
              final mealsOfType = mealsByType[mealType] ?? [];
              if (mealsOfType.isEmpty) {
                return _buildMealTypeRow(mealType, []);
              }
              return _buildMealTypeRow(mealType, mealsOfType);
            }),
        ],
      ),
    );
  }

  Widget _buildMealTypeRow(MealType mealType, List<MealEntry> meals) {
    final totalCalories = meals.fold<double>(
      0,
      (sum, meal) => sum + meal.totalCalories,
    );

    final foodNames = meals.expand((meal) => meal.foodItems).map((foodEntry) {
      return '${foodEntry.foodItem.name} (${foodEntry.totalCalories.toInt()}kcal)';
    }).join(', ');

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                mealType.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                meals.isEmpty ? '-' : foodNames,
                style: TextStyle(
                  fontSize: 14,
                  color: meals.isEmpty ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                meals.isEmpty ? '-' : '${totalCalories.toInt()}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: meals.isEmpty ? Colors.grey[400] : const Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionAnalysis() {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var meal in _meals) {
      totalCalories += meal.totalCalories;
      totalProtein += meal.totalProtein;
      totalCarbs += meal.totalCarbs;
      totalFat += meal.totalFat;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '영양 성분 분석',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            _buildNutritionRow(
              '총 칼로리',
              '${totalCalories.toInt()} kcal',
              '목표: ${_userGoals.dailyCalorieGoal.toInt()} kcal',
              totalCalories / _userGoals.dailyCalorieGoal,
            ),
            const SizedBox(height: 12),
            _buildNutritionRow(
              '탄수화물',
              '${totalCarbs.toInt()} g',
              '목표: ${_userGoals.carbsGoal.toInt()} g',
              totalCarbs / _userGoals.carbsGoal,
            ),
            const SizedBox(height: 12),
            _buildNutritionRow(
              '단백질',
              '${totalProtein.toInt()} g',
              '목표: ${_userGoals.proteinGoal.toInt()} g',
              totalProtein / _userGoals.proteinGoal,
            ),
            const SizedBox(height: 12),
            _buildNutritionRow(
              '지방',
              '${totalFat.toInt()} g',
              '목표: ${_userGoals.fatGoal.toInt()} g',
              totalFat / _userGoals.fatGoal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(
    String label,
    String value,
    String goal,
    double progress,
  ) {
    final percentage = (progress * 100).clamp(0, 100);
    final isOverGoal = progress > 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isOverGoal ? Colors.red[400] : const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${percentage.toInt()}%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isOverGoal ? Colors.red[400]! : const Color(0xFF4CAF50),
            ),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          goal,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
