import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import 'auth_service.dart';

class RecommendationService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// Collaborative Filtering을 사용하여 음식 추천
  static Future<List<Meal>> getRecommendedFoods({
    required int remainingMeals,
    required int targetCaloriesPerMeal,
  }) async {
    try {
      final token = await AuthService.getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/ai/recommend'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'remainingMeals': remainingMeals,
          'targetCaloriesPerMeal': targetCaloriesPerMeal,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> foods = data['recommendations'] ?? [];
        return foods.map((food) => Meal.fromJson(food)).toList();
      } else {
        throw Exception('추천 받기 실패: ${response.statusCode}');
      }
    } catch (e) {
      // 개발 중에는 더미 데이터 반환
      return _getDummyRecommendations(targetCaloriesPerMeal);
    }
  }

  /// 개발/테스트용 더미 데이터
  static List<Meal> _getDummyRecommendations(int targetCalories) {
    final allFoods = [
      Meal(
        name: '닭가슴살 샐러드',
        calories: 320,
        protein: 35,
        carbs: 20,
        fat: 8,
        allergens: [],
      ),
      Meal(
        name: '연어 구이',
        calories: 450,
        protein: 40,
        carbs: 5,
        fat: 28,
        allergens: [],
      ),
      Meal(
        name: '비빔밥',
        calories: 520,
        protein: 18,
        carbs: 75,
        fat: 15,
        allergens: ['계란', '우유'],
      ),
      Meal(
        name: '된장찌개',
        calories: 180,
        protein: 12,
        carbs: 15,
        fat: 8,
        allergens: ['대두'],
      ),
      Meal(
        name: '김치볶음밥',
        calories: 480,
        protein: 12,
        carbs: 68,
        fat: 16,
        allergens: ['새우젓'],
      ),
      Meal(
        name: '고등어 조림',
        calories: 380,
        protein: 28,
        carbs: 12,
        fat: 24,
        allergens: [],
      ),
      Meal(
        name: '두부 스테이크',
        calories: 280,
        protein: 22,
        carbs: 18,
        fat: 14,
        allergens: ['대두'],
      ),
      Meal(
        name: '참치 김밥',
        calories: 420,
        protein: 16,
        carbs: 58,
        fat: 12,
        allergens: [],
      ),
    ];

    // 목표 칼로리에 가까운 음식 필터링 (±100 kcal)
    final recommended = allFoods.where((food) {
      return (food.calories - targetCalories).abs() <= 150;
    }).toList();

    // 최대 5개만 반환
    return recommended.take(5).toList();
  }
}
