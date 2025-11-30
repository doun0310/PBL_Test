import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal_entry.dart';
import '../models/user_goals.dart';
import '../services/meal_tracking_service.dart';
import 'add_meal_screen.dart';

class WeeklyMealPlanScreen extends StatefulWidget {
  const WeeklyMealPlanScreen({super.key});

  @override
  State<WeeklyMealPlanScreen> createState() => _WeeklyMealPlanScreenState();
}

class _WeeklyMealPlanScreenState extends State<WeeklyMealPlanScreen> {
  DateTime _selectedWeekStart = DateTime.now();
  Map<DateTime, List<MealEntry>> _weeklyMeals = {};
  UserGoals _userGoals = UserGoals();
  bool _isLoading = true;
  bool _isTableView = true;

  @override
  void initState() {
    super.initState();
    _selectedWeekStart = _getWeekStart(DateTime.now());
    _loadWeeklyData();
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  Future<void> _loadWeeklyData() async {
    setState(() => _isLoading = true);

    try {
      final goals = await MealTrackingService.getUserGoals();
      final weeklyMeals = <DateTime, List<MealEntry>>{};

      for (int i = 0; i < 7; i++) {
        final date = _selectedWeekStart.add(Duration(days: i));
        final meals = await MealTrackingService.getMealsByDate(date);
        weeklyMeals[date] = meals;
      }

      setState(() {
        _userGoals = goals;
        _weeklyMeals = weeklyMeals;
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

  void _navigateToPreviousWeek() {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    });
    _loadWeeklyData();
  }

  void _navigateToNextWeek() {
    final nextWeek = _selectedWeekStart.add(const Duration(days: 7));
    final now = DateTime.now();
    if (nextWeek.isBefore(now) || _isSameWeek(nextWeek, now)) {
      setState(() {
        _selectedWeekStart = nextWeek;
      });
      _loadWeeklyData();
    }
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    final week1Start = _getWeekStart(date1);
    final week2Start = _getWeekStart(date2);
    return week1Start.year == week2Start.year &&
        week1Start.month == week2Start.month &&
        week1Start.day == week2Start.day;
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
          '주간 식단표',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isTableView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() => _isTableView = !_isTableView);
            },
            tooltip: _isTableView ? '리스트 보기' : '표 보기',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _buildWeekSelector(),
                  Expanded(
                    child: _isTableView 
                        ? _buildWeeklyMealTable() 
                        : _buildWeeklyMealList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWeekSelector() {
    final weekEnd = _selectedWeekStart.add(const Duration(days: 6));
    final isCurrentWeek = _isSameWeek(_selectedWeekStart, DateTime.now());

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
            onPressed: _navigateToPreviousWeek,
          ),
          Text(
            '${DateFormat('MM월 dd일', 'ko_KR').format(_selectedWeekStart)} - ${DateFormat('MM월 dd일', 'ko_KR').format(weekEnd)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isCurrentWeek ? Colors.grey[300] : Colors.black,
            ),
            onPressed: isCurrentWeek ? null : _navigateToNextWeek,
          ),
        ],
      ),
    );
  }

  // Calendar-like table view showing days as columns and meal types as rows
  Widget _buildWeeklyMealTable() {
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    final mealTypes = MealType.values;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header row with days
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  _buildHeaderCell('', isFirst: true),
                  for (int i = 0; i < 7; i++)
                    _buildDayHeader(i, days[i]),
                ],
              ),
            ),
            // Meal type rows
            for (var mealType in mealTypes)
              _buildMealTypeRow(mealType),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {bool isFirst = false}) {
    return Container(
      width: isFirst ? 60 : null,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDayHeader(int dayIndex, String dayName) {
    final date = _selectedWeekStart.add(Duration(days: dayIndex));
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFF388E3C) : null,
        ),
        child: Column(
          children: [
            Text(
              dayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('d').format(date),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeRow(MealType mealType) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Meal type label
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: _getMealTypeColor(mealType).withOpacity(0.1),
                border: Border(
                  right: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Center(
                child: Text(
                  mealType.displayName,
                  style: TextStyle(
                    color: _getMealTypeColor(mealType),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            // Day cells for this meal type
            for (int i = 0; i < 7; i++)
              Expanded(
                child: _buildMealCell(i, mealType),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCell(int dayIndex, MealType mealType) {
    final date = _selectedWeekStart.add(Duration(days: dayIndex));
    final meals = _weeklyMeals[date] ?? [];
    final mealsOfType = meals.where((m) => m.mealType == mealType).toList();
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return GestureDetector(
      onTap: () => _onCellTap(date, mealType),
      child: Container(
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minHeight: 80),
        decoration: BoxDecoration(
          color: isToday ? Colors.green.withOpacity(0.05) : null,
          border: Border(
            right: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: mealsOfType.isEmpty
            ? Center(
                child: Icon(
                  Icons.add_circle_outline,
                  color: Colors.grey[300],
                  size: 20,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var meal in mealsOfType)
                    for (var foodEntry in meal.foodItems.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          foodEntry.foodItem.name,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  if (_getFoodCount(mealsOfType) > 2)
                    Text(
                      '+${_getFoodCount(mealsOfType) - 2}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  int _getFoodCount(List<MealEntry> meals) {
    int count = 0;
    for (var meal in meals) {
      count += meal.foodItems.length;
    }
    return count;
  }

  void _onCellTap(DateTime date, MealType mealType) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMealScreen(
          initialDate: date,
          onMealAdded: () {
            _loadWeeklyData();
          },
        ),
      ),
    );
  }

  Color _getMealTypeColor(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return Colors.orange;
      case MealType.lunch:
        return Colors.blue;
      case MealType.dinner:
        return Colors.purple;
      case MealType.snack:
        return Colors.pink;
    }
  }

  // Original list view
  Widget _buildWeeklyMealList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 7,
      itemBuilder: (context, index) {
        final date = _selectedWeekStart.add(Duration(days: index));
        final meals = _weeklyMeals[date] ?? [];
        return _buildDayCard(date, meals);
      },
    );
  }

  Widget _buildDayCard(DateTime date, List<MealEntry> meals) {
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var meal in meals) {
      totalCalories += meal.totalCalories;
      totalProtein += meal.totalProtein;
      totalCarbs += meal.totalCarbs;
      totalFat += meal.totalFat;
    }

    final mealsByType = <MealType, List<MealEntry>>{};
    for (var meal in meals) {
      mealsByType.putIfAbsent(meal.mealType, () => []).add(meal);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('E', 'ko_KR').format(date),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isToday ? const Color(0xFF4CAF50) : const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MM.dd', 'ko_KR').format(date),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '오늘',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (meals.isNotEmpty)
                  Text(
                    '${totalCalories.toInt()} kcal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: totalCalories > _userGoals.dailyCalorieGoal
                          ? Colors.red[400]
                          : const Color(0xFF4CAF50),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (meals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '식사 기록이 없습니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var mealType in MealType.values)
                    if (mealsByType.containsKey(mealType))
                      _buildMealTypeSection(mealType, mealsByType[mealType]!),
                  const Divider(height: 24),
                  _buildNutritionSummary(totalCalories, totalProtein, totalCarbs, totalFat),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeSection(MealType mealType, List<MealEntry> meals) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: _getMealTypeColor(mealType),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                mealType.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getMealTypeColor(mealType),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (var meal in meals)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var foodEntry in meal.foodItems)
                    Text(
                      '• ${foodEntry.foodItem.name} (${foodEntry.totalCalories.toInt()} kcal)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary(
    double calories,
    double protein,
    double carbs,
    double fat,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNutrientItem('칼로리', '${calories.toInt()} kcal'),
          _buildNutrientItem('탄수화물', '${carbs.toInt()}g'),
          _buildNutrientItem('단백질', '${protein.toInt()}g'),
          _buildNutrientItem('지방', '${fat.toInt()}g'),
        ],
      ),
    );
  }

  Widget _buildNutrientItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }
}
