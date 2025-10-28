import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import 'auth_service.dart';

class MealService {
  static const String baseUrl = 'http://localhost:3000/api';

  // 특정 날짜의 식단 가져오기
  static Future<DailyMeal?> getMealsByDate(String date) async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/meals?date=$date'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DailyMeal.fromJson(data);
      }
      return null;
    } catch (e) {
      print('식단 조회 오류: \${e.toString()}');
      return null;
    }
  }

  // 오늘의 식단 가져오기
  static Future<DailyMeal?> getTodayMeals() async {
    final today = DateTime.now();
    final dateString = '\${today.year}-\${today.month.toString().padLeft(2, ';0;')}-\${today.day.toString().padLeft(2, ';0;')}';
    return getMealsByDate(dateString);
  }

  // 식단 검색
  static Future<List<Meal>> searchMeals(String query) async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/meals/search?q=$query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((meal) => Meal.fromJson(meal)).toList();
      }
      return [];
    } catch (e) {
      print('식단 검색 오류: \${e.toString()}');
      return [];
    }
  }
}
