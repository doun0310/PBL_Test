import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal_entry.dart';
import '../models/user_goals.dart';
import '../services/meal_tracking_service.dart';
import 'add_meal_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen.dart';
import 'daily_meal_table_screen.dart';
import 'exercise_tracking_screen.dart';
import 'community_screen.dart';
import 'recipe_screen.dart';
import 'recommendation_screen.dart';
import 'settings_screen.dart';
import '../widgets/nutrition_progress_card.dart';
import '../widgets/meal_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();
  List<MealEntry> _todayMeals = [];
  UserGoals _userGoals = UserGoals();
  DailyNutrition _todayNutrition = DailyNutrition();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final goals = await MealTrackingService.getUserGoals();
      final meals = await MealTrackingService.getMealsByDate(_selectedDate);
      final nutrition = await MealTrackingService.getDailyNutrition(_selectedDate);

      setState(() {
        _userGoals = goals;
        _todayMeals = meals;
        _todayNutrition = nutrition;
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

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeView();
      case 1:
        return AddMealScreen(
          initialDate: _selectedDate,
          onMealAdded: () {
            _loadData();
            setState(() => _selectedIndex = 0);
          },
        );
      case 2:
        return const StatisticsScreen();
      case 3:
        return const ExerciseTrackingScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildHomeView();
    }
  }

  Widget _buildHomeView() {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateSelector(),
                          const SizedBox(height: 20),
                          NutritionProgressCard(
                            nutrition: _todayNutrition,
                            goals: _userGoals,
                          ),
                          const SizedBox(height: 24),
                          _buildQuickAccessButtons(),
                          const SizedBox(height: 16),
                          _buildRecommendationButton(),
                          const SizedBox(height: 16),
                          _buildMealsSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Diet Tracker',
        style: TextStyle(
          color: Color(0xFF2C3E50),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Color(0xFF2C3E50)),
          onPressed: () {
            // 알림 관련 액션
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Color(0xFF2C3E50)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Container(
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
          Text(
            isToday
                ? '오늘'
                : DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDate),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  });
                  _loadData();
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DailyMealTableScreen(
                        selectedDate: _selectedDate,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  if (!isToday) {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                    _loadData();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  Widget _buildQuickAccessButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '빠른 접근',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickAccessCard(
                '음식 추천',
                Icons.recommend,
                Colors.purple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecommendationScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickAccessCard(
                '커뮤니티',
                Icons.forum,
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CommunityScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickAccessCard(
                '레시피',
                Icons.restaurant_menu,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecipeRecommendationScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickAccessCard(
                '설정',
                Icons.settings,
                Colors.grey,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationButton() {
    final remainingCalories = _userGoals.dailyCalorieGoal - _todayNutrition.calories;
    
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddMealScreen(
              initialDate: _selectedDate,
              onMealAdded: () {
                _loadData();
              },
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_circle_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '식사 추가하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remainingCalories > 0 
                        ? '남은 칼로리: ${remainingCalories.toInt()} kcal'
                        : '오늘의 목표를 달성했습니다!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 식사',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 16),
        if (_todayMeals.isEmpty)
          _buildEmptyMeals()
        else
          ..._todayMeals.map((meal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MealCard(
                  meal: meal,
                  onTap: () => _showMealDetails(meal),
                  onDelete: () => _deleteMeal(meal.id),
                ),
              )),
      ],
    );
  }

  Widget _buildEmptyMeals() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '아직 기록된 식사가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 식사를 추가해보세요!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMealDetails(MealEntry meal) {
    // TODO: Show meal details dialog
  }

  Future<void> _deleteMeal(String mealId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('식사 삭제'),
        content: const Text('이 식사 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await MealTrackingService.deleteMeal(mealId);
      _loadData();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, '홈', 0),
              _buildNavItem(Icons.add_circle_outline, Icons.add_circle, '추가', 1),
              _buildNavItem(Icons.bar_chart_outlined, Icons.bar_chart, '통계', 2),
              _buildNavItem(Icons.directions_run_outlined, Icons.directions_run, '운동', 3),
              _buildNavItem(Icons.person_outline, Icons.person, '프로필', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    int index,
  ) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onBottomNavTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
