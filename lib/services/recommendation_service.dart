import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_recommendation.dart';
import '../models/user_goals.dart'; // UserGoals 모델 임포트

class RecommendationService {
  // ❗️ 중요: 이 주소를 자신의 PC IP 주소로 변경하세요.
  // 터미널/CMD에서 ipconfig 또는 ifconfig 명령어로 확인 가능
  final String _baseUrl = 'http://192.168.219.113:8000';

  // 서버 상태 확인
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  // 영양 기반 추천 요청
  Future<List<FoodRecommendation>> getNutritionRecommendations({
    required double targetCalories,
    required double targetCarbs,
    required double targetProtein,
    required double targetFat,
  }) async {
    final url = Uri.parse('$_baseUrl/recommend/nutrition');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'target_calories': targetCalories,
          'target_carbs': targetCarbs,
          'target_protein': targetProtein,
          'target_fat': targetFat,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => FoodRecommendation.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getNutritionRecommendations: $e');
      return [];
    }
  }

  // 협업 필터링 추천 요청
  Future<List<FoodRecommendation>> getCollaborativeRecommendations({
    required String userId,
  }) async {
    final url = Uri.parse('$_baseUrl/recommend/collaborative');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => FoodRecommendation.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getCollaborativeRecommendations: $e');
      return [];
    }
  }

  // 인기 음식 추천 요청
  Future<List<FoodRecommendation>> getPopularRecommendations() async {
    final url = Uri.parse('$_baseUrl/recommend/popular');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => FoodRecommendation.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error in getPopularRecommendations: $e');
      return [];
    }
  }

  // 평점 추가 요청
  Future<bool> addRating({
    required String userId,
    required String foodId,
    required double rating,
  }) async {
    final url = Uri.parse('$_baseUrl/rating');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'food_id': foodId,
          'rating': rating,
        }),
      );
      return response.statusCode == 201; // 201 Created
    } catch (e) {
      print('Error in addRating: $e');
      return false;
    }
  }

  void dispose() {
    // http 클라이언트 등을 여기서 닫을 수 있습니다.
  }
}