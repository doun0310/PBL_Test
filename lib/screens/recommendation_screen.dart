import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../services/recommendation_service.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _remainingMealsController = TextEditingController(text: '3');
  final _targetCaloriesController = TextEditingController(text: '500');

  List<Meal>? _recommendedFoods;
  bool _isLoading = false;

  int _remainingCalories = 0;
  int _remainingProtein = 0;
  int _remainingCarbs = 0;
  int _remainingFat = 0;

  @override
  void dispose() {
    _remainingMealsController.dispose();
    _targetCaloriesController.dispose();
    super.dispose();
  }

  Future<void> _getRecommendations() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final remainingMeals = int.parse(_remainingMealsController.text);
      final targetCalories = int.parse(_targetCaloriesController.text);

      final recommendations = await RecommendationService.getRecommendedFoods(
        remainingMeals: remainingMeals,
        targetCaloriesPerMeal: targetCalories,
      );

      // 남은 영양소 계산 (예시)
      _remainingCalories = targetCalories * remainingMeals;
      _remainingProtein = (_remainingCalories * 0.3 / 4).round();
      _remainingCarbs = (_remainingCalories * 0.5 / 4).round();
      _remainingFat = (_remainingCalories * 0.2 / 9).round();

      setState(() {
        _recommendedFoods = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('추천 받기 오류: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('섭취 가능 음식 추천'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 입력 폼
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오늘의 목표 설정',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _remainingMealsController,
                        decoration: const InputDecoration(
                          labelText: '남은 끼니 수',
                          border: OutlineInputBorder(),
                          suffixText: '끼',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '남은 끼니 수를 입력해주세요';
                          }
                          final number = int.tryParse(value);
                          if (number == null || number < 1 || number > 10) {
                            return '1-10 사이의 숫자를 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _targetCaloriesController,
                        decoration: const InputDecoration(
                          labelText: '한 끼 목표 칼로리',
                          border: OutlineInputBorder(),
                          suffixText: 'kcal',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '목표 칼로리를 입력해주세요';
                          }
                          final number = int.tryParse(value);
                          if (number == null || number < 100 || number > 2000) {
                            return '100-2000 사이의 숫자를 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _getRecommendations,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                '추천 받기',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 남은 영양소 정보
            if (_recommendedFoods != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '남은 영양소 목표',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutrientInfo('칼로리', '$_remainingCalories kcal'),
                          _buildNutrientInfo('단백질', '${_remainingProtein}g'),
                          _buildNutrientInfo('탄수화물', '${_remainingCarbs}g'),
                          _buildNutrientInfo('지방', '${_remainingFat}g'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 추천 음식 목록
            if (_recommendedFoods != null) ...[
              const SizedBox(height: 24),
              Text(
                '추천 음식',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (_recommendedFoods!.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('추천할 음식이 없습니다'),
                    ),
                  ),
                )
              else
                ..._recommendedFoods!.map((food) => _buildFoodCard(food)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFoodCard(Meal meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          meal.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                _buildNutrientChip('${meal.calories} kcal'),
                const SizedBox(width: 4),
                _buildNutrientChip('단백질 ${meal.protein}g'),
                const SizedBox(width: 4),
                _buildNutrientChip('탄수화물 ${meal.carbs}g'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildNutrientChip('지방 ${meal.fat}g'),
              ],
            ),
            if (meal.allergens.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: meal.allergens.map((allergen) {
                  return Chip(
                    label: Text(
                      allergen,
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.orange[100],
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: Theme.of(context).primaryColor,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${meal.name}을(를) 식단에 추가했습니다'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String text) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: Colors.blue[50],
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
