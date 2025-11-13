import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal_analytics.dart';
import 'auth_service.dart';

class AnalyticsService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// 주간 식단 분석 데이터 가져오기
  static Future<MealAnalytics> getWeeklyAnalytics() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/analytics/weekly'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MealAnalytics.fromJson(data);
      } else {
        throw Exception('주간 분석 데이터 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      // 개발 중에는 더미 데이터 반환
      return _getDummyWeeklyAnalytics();
    }
  }

  /// 월간 식단 분석 데이터 가져오기
  static Future<MealAnalytics> getMonthlyAnalytics() async {
    try {
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/analytics/monthly'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MealAnalytics.fromJson(data);
      } else {
        throw Exception('월간 분석 데이터 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      // 개발 중에는 더미 데이터 반환
      return _getDummyMonthlyAnalytics();
    }
  }

  /// 개발/테스트용 더미 주간 데이터
  static MealAnalytics _getDummyWeeklyAnalytics() {
    return MealAnalytics(
      totalCalories: 14500,
      totalProtein: 580,
      totalCarbs: 1450,
      totalFat: 435,
      dailyCalories: {
        '월': 2100,
        '화': 2050,
        '수': 2200,
        '목': 2000,
        '금': 2150,
        '토': 2300,
        '일': 1700,
      },
      topFoods: [
        FoodRank(name: '흰쌀밥', count: 14),
        FoodRank(name: '김치찌개', count: 8),
        FoodRank(name: '닭가슴살', count: 7),
        FoodRank(name: '된장찌개', count: 6),
        FoodRank(name: '고등어 구이', count: 5),
      ],
    );
  }

  /// 개발/테스트용 더미 월간 데이터
  static MealAnalytics _getDummyMonthlyAnalytics() {
    return MealAnalytics(
      totalCalories: 62000,
      totalProtein: 2480,
      totalCarbs: 6200,
      totalFat: 1860,
      dailyCalories: {
        '1주': 14500,
        '2주': 15200,
        '3주': 14800,
        '4주': 15500,
        '5주': 2000,
      },
      topFoods: [
        FoodRank(name: '흰쌀밥', count: 60),
        FoodRank(name: '김치찌개', count: 35),
        FoodRank(name: '닭가슴살', count: 28),
        FoodRank(name: '된장찌개', count: 25),
        FoodRank(name: '고등어 구이', count: 22),
      ],
    );
  }
}
