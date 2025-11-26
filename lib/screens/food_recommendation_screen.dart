import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/user_goals.dart';
import '../services/food_database_service.dart';
import '../services/meal_tracking_service.dart';

class FoodRecommendationScreen extends StatefulWidget {
  const FoodRecommendationScreen({super.key});

  @override
  State<FoodRecommendationScreen> createState() => _FoodRecommendationScreenState();
}

class _FoodRecommendationScreenState extends State<FoodRecommendationScreen> {
  double _targetCalories = 500;
  List<List<FoodItem>> _recommendations = [];
  UserGoals _userGoals = UserGoals();
  double _remainingCalories = 0;
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
      final todayNutrition = await MealTrackingService.getDailyNutrition(DateTime.now());
      
      final remaining = goals.dailyCalorieGoal - todayNutrition.calories;

      setState(() {
        _userGoals = goals;
        _remainingCalories = remaining > 0 ? remaining : 500;
        _targetCalories = _remainingCalories.clamp(100, 1000);
        _isLoading = false;
      });

      _generateRecommendations();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _generateRecommendations() {
    final allFoods = FoodDatabaseService.getAllFoods();
    final recommendations = <List<FoodItem>>[];

    // 전략 1: 단일 음식 추천
    final singleFoods = allFoods.where((food) {
      return (food.calories - _targetCalories).abs() < 100;
    }).take(3).toList();

    for (var food in singleFoods) {
      recommendations.add([food]);
    }

    // 전략 2: 2개 조합 추천
    for (int i = 0; i < allFoods.length && recommendations.length < 6; i++) {
      for (int j = i + 1; j < allFoods.length && recommendations.length < 6; j++) {
        final totalCal = allFoods[i].calories + allFoods[j].calories;
        if ((totalCal - _targetCalories).abs() < 150) {
          recommendations.add([allFoods[i], allFoods[j]]);
        }
      }
    }

    // 전략 3: 3개 조합 추천 (간단한 예시)
    if (recommendations.length < 8) {
      final categories = ['밥류', '국/찌개', '채소'];
      final combo = <FoodItem>[];
      
      for (var category in categories) {
        final foods = FoodDatabaseService.getFoodsByCategory(category);
        if (foods.isNotEmpty) {
          combo.add(foods.first);
        }
      }
      
      if (combo.length == 3) {
        recommendations.add(combo);
      }
    }

    setState(() {
      _recommendations = recommendations.take(8).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '식사 추천',
          style: TextStyle(color: Color(0xFF2C3E50)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildCalorieSlider(),
                Expanded(child: _buildRecommendations()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '남은 칼로리',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_remainingCalories.toInt()} kcal',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '목표: ${_userGoals.dailyCalorieGoal.toInt()} kcal',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieSlider() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '원하는 칼로리',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_targetCalories.toInt()} kcal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _targetCalories,
            min: 100,
            max: 1000,
            divisions: 18,
            activeColor: const Color(0xFF4CAF50),
            label: '${_targetCalories.toInt()} kcal',
            onChanged: (value) {
              setState(() {
                _targetCalories = value;
              });
            },
            onChangeEnd: (value) {
              _generateRecommendations();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    if (_recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '추천할 음식이 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '칼로리를 조정해보세요',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        return _buildRecommendationCard(index, _recommendations[index]);
      },
    );
  }

  Widget _buildRecommendationCard(int index, List<FoodItem> foods) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var food in foods) {
      totalCalories += food.calories;
      totalProtein += food.protein;
      totalCarbs += food.carbs;
      totalFat += food.fat;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRecommendationDetails(foods),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '추천 ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, 
                          size: 16, 
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${totalCalories.toInt()} kcal',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...foods.map((food) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        food.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${food.servingSize.toInt()}${food.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutrientChip('탄 ${totalCarbs.toInt()}g', Colors.orange),
                    _buildNutrientChip('단 ${totalProtein.toInt()}g', Colors.blue),
                    _buildNutrientChip('지 ${totalFat.toInt()}g', Colors.pink),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showRecommendationDetails(List<FoodItem> foods) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '추천 상세 정보',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...foods.map((food) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${food.servingSize.toInt()}${food.unit} - ${food.calories.toInt()} kcal',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '탄수화물: ${food.carbs.toInt()}g, 단백질: ${food.protein.toInt()}g, 지방: ${food.fat.toInt()}g',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addRecommendationToMeal(foods);
                },
                child: const Text('이 조합으로 식사 추가'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addRecommendationToMeal(List<FoodItem> foods) {
    // Navigate back and add foods to meal
    Navigator.pop(context, foods);
  }
}
