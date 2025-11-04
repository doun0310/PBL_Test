import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal.dart';
import '../services/meal_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();
  DailyMeal? _dailyMeal;
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage; // ✅ 에러 메시지 추가

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📊 데이터 로드 시작');

      // 사용자 정보 로드
      _currentUser = await AuthService.getCurrentUser();
      if (_currentUser != null) {
        print('👤 사용자 로드됨: \${_currentUser!.name}');
      } else {
        print('⚠️ 사용자 정보 없음');
      }

      // 식단 데이터 로드
      print('🍽️ 식단 데이터 로드 시작...');
      _dailyMeal = await MealService.getTodayMeals();

      if (_dailyMeal != null) {
        print('✅ 식단 로드 성공');
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        print('❌ 식단 로드 실패');
        setState(() {
          _isLoading = false;
          _errorMessage = '식단을 불러올 수 없습니다. 서버 연결을 확인하세요.';
        });
      }
    } catch (e) {
      print('❌ 데이터 로드 중 오류: \${e.toString()}');
      setState(() {
        _isLoading = false;
        _errorMessage = '오류 발생: \${e.toString()}';
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMealForDate(picked);
    }
  }

  Future<void> _loadMealForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      print('📅 날짜 선택: $formattedDate');

      final dateString = DateFormat('yyyy-MM-dd').format(date);
      _dailyMeal = await MealService.getMealsByDate(dateString);

      setState(() {
        _isLoading = false;
        if (_dailyMeal == null) {
          _errorMessage = '해당 날짜의 식단 정보가 없습니다.';
        } else {
          _errorMessage = null;
        }
      });
    } catch (e) {
      print('❌ 식단 로드 오류: \${e.toString()}');
      setState(() {
        _isLoading = false;
        _errorMessage = '식단 로드 실패: \${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식단 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ).then((_) => _loadData());
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ✅ 에러 메시지 표시
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_dailyMeal == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('식단 정보를 불러올 수 없습니다'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 날짜 표시
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDate),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_currentUser != null)
                    Text(
                      _currentUser!.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 아침
          if (_dailyMeal!.breakfast.isNotEmpty)
            _buildMealSection('아침', _dailyMeal!.breakfast, Icons.wb_sunny)
          else
            _buildEmptyMealSection('아침'),
          const SizedBox(height: 16),

          // 점심
          if (_dailyMeal!.lunch.isNotEmpty)
            _buildMealSection('점심', _dailyMeal!.lunch, Icons.wb_sunny_outlined)
          else
            _buildEmptyMealSection('점심'),
          const SizedBox(height: 16),

          // 저녁
          if (_dailyMeal!.dinner.isNotEmpty)
            _buildMealSection('저녁', _dailyMeal!.dinner, Icons.nights_stay)
          else
            _buildEmptyMealSection('저녁'),
        ],
      ),
    );
  }

  Widget _buildMealSection(String title, List<Meal> meals, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...meals.map((meal) => _buildMealItem(meal)),
            const SizedBox(height: 8),
            _buildNutritionSummary(meals),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMealSection(String title) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            Center(
              child: Text(
                '식단 정보 없음',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem(Meal meal) {
    final hasUserAllergen = _currentUser?.allergies.any(
      (allergen) => meal.allergens.contains(allergen),
    ) ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: hasUserAllergen ? Colors.red : null,
                      ),
                ),
                if (meal.allergens.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: meal.allergens.map((allergen) {
                      final isUserAllergen = 
                          _currentUser?.allergies.contains(allergen) ?? false;
                      return Chip(
                        label: Text(
                          allergen,
                          style: TextStyle(
                            fontSize: 10,
                            color: isUserAllergen ? Colors.white : null,
                          ),
                        ),
                        backgroundColor: isUserAllergen 
                            ? Colors.red 
                            : Colors.grey[200],
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '\${meal.calories} kcal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary(List<Meal> meals) {
    final totalCalories = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    final totalProtein = meals.fold<int>(0, (sum, meal) => sum + meal.protein);
    final totalCarbs = meals.fold<int>(0, (sum, meal) => sum + meal.carbs);
    final totalFat = meals.fold<int>(0, (sum, meal) => sum + meal.fat);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNutritionItem('칼로리', '\$totalCalories kcal'),
          _buildNutritionItem('단백질', '\${totalProtein}g'),
          _buildNutritionItem('탄수화물', '\${totalCarbs}g'),
          _buildNutritionItem('지방', '\${totalFat}g'),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
