import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import 'auth_service.dart';

class MealService {
  static const String baseUrl = 'http://localhost:3000/api';
  // 웹 테스트: static const String baseUrl = 'http://192.168.0.100:3000/api';

  // ✅ 날짜 포맷팅 함수
  static String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '\$year-\$month-\$day';
  }

  // 특정 날짜의 식단 가져오기 (디버깅 강화)
  static Future<DailyMeal?> getMealsByDate(String date) async {
    try {
      print('🔍 식단 조회 시작');
      print('📅 요청 날짜: \$date');

      // 1단계: 토큰 확인
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ 토큰 없음: 로그인이 필요합니다.');
        return null;
      }
      print('✅ 토큰 확인됨');

      // 2단계: API 요청
      final url = '\$baseUrl/meals?date=\$date';
      print('📍 요청 URL: \$url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer \$token',
        },
      );

      print('📞 응답 상태 코드: \${response.statusCode}');
      print('📨 응답 본문: \${response.body}');

      // 3단계: 상태 코드별 처리
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('✅ JSON 파싱 성공');
          print('🍽️ 식단 데이터: \$data');

          final dailyMeal = DailyMeal.fromJson(data);
          print('✅ DailyMeal 객체 생성 성공');
          print('   - 아침 식단: \${dailyMeal.breakfast.length}개');
          print('   - 점심 식단: \${dailyMeal.lunch.length}개');
          print('   - 저녁 식단: \${dailyMeal.dinner.length}개');

          return dailyMeal;
        } catch (parseError) {
          print('❌ JSON 파싱 오류: \${parseError.toString()}');
          return null;
        }
      } else if (response.statusCode == 401) {
        print('❌ 인증 오류: 토큰이 유효하지 않거나 만료됨');
        print('   해결책: 다시 로그인하세요');
        return null;
      } else if (response.statusCode == 404) {
        print('❌ 식단 데이터 없음: 해당 날짜(\$date)의 식단이 DB에 없습니다');
        print('   해결책: 샘플 데이터를 추가하거나 다른 날짜 선택');
        return null;
      } else {
        print('❌ 서버 오류: \${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ 예외 발생: \${e.toString()}');
      print('🔧 가능한 원인:');
      print('   1. 서버가 실행 중이 아님');
      print('   2. baseUrl이 잘못됨 (\$baseUrl)');
      print('   3. 네트워크 연결 안 됨');
      return null;
    }
  }

  // 오늘의 식단 가져오기
  static Future<DailyMeal?> getTodayMeals() async {
    final today = DateTime.now();
    final dateString = _formatDate(today);
    print('📆 오늘 날짜: \$dateString');
    return getMealsByDate(dateString);
  }

  // 식단 검색
  static Future<List<Meal>> searchMeals(String query) async {
    try {
      print('🔍 식단 검색 시작: \$query');

      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ 토큰 없음');
        return [];
      }

      final url = '\$baseUrl/meals/search?q=\$query';
      print('📍 요청 URL: \$url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer \$token',
        },
      );

      print('📞 응답 상태 코드: \${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ 검색 결과: \${data.length}개');
        return data.map((meal) => Meal.fromJson(meal)).toList();
      }

      print('❌ 검색 실패: \${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ 검색 중 오류: \${e.toString()}');
      return [];
    }
  }
}
