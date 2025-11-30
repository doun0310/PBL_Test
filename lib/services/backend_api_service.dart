import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';
import '../models/meal_entry.dart';
import '../models/user_goals.dart';

/// Diet101 Backend API Service
/// Node.js 백엔드 서버와 통신하는 서비스
class BackendApiService {
  // 서버 기본 URL (실제 배포 시 변경 필요)
  static const String _baseUrl = 'http://localhost:3000/api';
  
  // 토큰 저장 키
  static const String _tokenKey = 'auth_token';
  
  /// HTTP 헤더 생성 (인증 토큰 포함)
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 토큰 저장
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// 토큰 삭제
  static Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ==================== 인증 API ====================

  /// 회원가입
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    List<String>? allergies,
    List<String>? preferences,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'name': name,
          'allergies': allergies ?? [],
          'preferences': preferences ?? [],
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? '회원가입에 실패했습니다.'};
      }
    } catch (e) {
      return {'success': false, 'message': '서버 연결에 실패했습니다: $e'};
    }
  }

  /// 로그인
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        await _saveToken(data['token']);
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
          'token': data['token'],
        };
      } else {
        return {'success': false, 'message': data['message'] ?? '로그인에 실패했습니다.'};
      }
    } catch (e) {
      return {'success': false, 'message': '서버 연결에 실패했습니다: $e'};
    }
  }

  /// 로그아웃
  static Future<void> logout() async {
    await _clearToken();
  }

  /// 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  // ==================== 프로필 API ====================

  /// 프로필 조회
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 프로필 업데이트
  static Future<bool> updateProfile({
    required String name,
    List<String>? allergies,
    List<String>? preferences,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/profile'),
        headers: headers,
        body: json.encode({
          'name': name,
          'allergies': allergies ?? [],
          'preferences': preferences ?? [],
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== 목표 API ====================

  /// 사용자 목표 조회
  static Future<UserGoals> getGoals() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/goals'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserGoals(
          dailyCalorieGoal: (data['dailyCalorieGoal'] as num).toDouble(),
          proteinGoal: (data['proteinGoal'] as num).toDouble(),
          carbsGoal: (data['carbsGoal'] as num).toDouble(),
          fatGoal: (data['fatGoal'] as num).toDouble(),
          mealsPerDay: data['mealsPerDay'] as int,
        );
      }
    } catch (e) {
      // 에러 시 기본값 반환
    }
    return UserGoals();
  }

  /// 사용자 목표 업데이트
  static Future<bool> updateGoals(UserGoals goals) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/goals'),
        headers: headers,
        body: json.encode(goals.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== 음식 데이터베이스 API ====================

  /// 모든 음식 조회
  static Future<List<FoodItem>> getAllFoods() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/foods'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => FoodItem(
          id: item['id'].toString(),
          name: item['name'],
          calories: (item['calories'] as num).toDouble(),
          protein: (item['protein'] as num).toDouble(),
          carbs: (item['carbs'] as num).toDouble(),
          fat: (item['fat'] as num).toDouble(),
          servingSize: (item['serving_size'] as num?)?.toDouble() ?? 100,
          unit: item['unit'] ?? 'g',
          category: item['category'],
          imageUrl: item['image_url'],
        )).toList();
      }
    } catch (e) {
      // 에러 로깅
    }
    return [];
  }

  /// 음식 검색
  static Future<List<FoodItem>> searchFoods(String query, {String? category}) async {
    try {
      final uri = Uri.parse('$_baseUrl/foods/search').replace(queryParameters: {
        if (query.isNotEmpty) 'q': query,
        if (category != null) 'category': category,
      });
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => FoodItem(
          id: item['id'].toString(),
          name: item['name'],
          calories: (item['calories'] as num).toDouble(),
          protein: (item['protein'] as num).toDouble(),
          carbs: (item['carbs'] as num).toDouble(),
          fat: (item['fat'] as num).toDouble(),
          servingSize: (item['serving_size'] as num?)?.toDouble() ?? 100,
          unit: item['unit'] ?? 'g',
          category: item['category'],
          imageUrl: item['image_url'],
        )).toList();
      }
    } catch (e) {
      // 에러 로깅
    }
    return [];
  }

  /// 카테고리 목록 조회
  static Future<List<String>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      }
    } catch (e) {
      // 에러 로깅
    }
    return [];
  }

  // ==================== 식사 기록 API ====================

  /// 날짜별 식사 기록 조회
  static Future<List<MealEntry>> getDietByDate(DateTime date) async {
    try {
      final headers = await _getHeaders();
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$_baseUrl/diet?date=$dateStr'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final List<dynamic> foodItemsData = item['foodItems'] ?? [];
          return MealEntry(
            id: item['id'].toString(),
            timestamp: DateTime.parse(item['timestamp']),
            mealType: MealType.values.firstWhere(
              (e) => e.name == item['mealType'],
              orElse: () => MealType.snack,
            ),
            foodItems: foodItemsData.map((fi) => FoodItemEntry(
              foodItem: FoodItem(
                id: fi['foodItem']['id'].toString(),
                name: fi['foodItem']['name'],
                calories: (fi['foodItem']['calories'] as num).toDouble(),
                protein: (fi['foodItem']['protein'] as num).toDouble(),
                carbs: (fi['foodItem']['carbs'] as num).toDouble(),
                fat: (fi['foodItem']['fat'] as num).toDouble(),
                servingSize: (fi['foodItem']['serving_size'] as num?)?.toDouble() ?? 100,
                unit: fi['foodItem']['unit'] ?? 'g',
                category: fi['foodItem']['category'],
              ),
              servingSize: (fi['servingSize'] as num).toDouble(),
              quantity: (fi['quantity'] as num?)?.toDouble() ?? 1,
            )).toList(),
            photoPath: item['photoPath'],
            notes: item['notes'],
          );
        }).toList();
      }
    } catch (e) {
      // 에러 로깅
    }
    return [];
  }

  /// 식사 기록 추가
  static Future<bool> addDiet(MealEntry meal) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/diet'),
        headers: headers,
        body: json.encode({
          'mealType': meal.mealType.name,
          'timestamp': meal.timestamp.toIso8601String(),
          'foodItems': meal.foodItems.map((fi) => {
            'foodItem': fi.foodItem.toJson(),
            'servingSize': fi.servingSize,
            'quantity': fi.quantity,
          }).toList(),
          'notes': meal.notes,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// 식사 기록 삭제
  static Future<bool> deleteDiet(String mealId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/diet/$mealId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== 영양 통계 API ====================

  /// 일일 영양 통계 조회
  static Future<DailyNutrition> getDailyNutrition(DateTime date) async {
    try {
      final headers = await _getHeaders();
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$_baseUrl/nutrition/daily?date=$dateStr'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DailyNutrition(
          calories: (data['calories'] as num).toDouble(),
          protein: (data['protein'] as num).toDouble(),
          carbs: (data['carbs'] as num).toDouble(),
          fat: (data['fat'] as num).toDouble(),
        );
      }
    } catch (e) {
      // 에러 로깅
    }
    return DailyNutrition();
  }

  /// 주간 영양 통계 조회
  static Future<List<Map<String, dynamic>>> getWeeklyNutrition() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/nutrition/weekly'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // 에러 로깅
    }
    return [];
  }

  /// 월간 영양 통계 조회
  static Future<List<Map<String, dynamic>>> getMonthlyNutrition() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/nutrition/monthly'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // 에러 로깅
    }
    return [];
  }

  /// 음식 랭킹 조회
  static Future<List<Map<String, dynamic>>> getFoodRanking({String period = 'week'}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/nutrition/ranking?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // 에러 로깅
    }
    return [];
  }

  // ==================== 추천 API ====================

  /// 음식 추천 조회
  static Future<Map<String, dynamic>> getRecommendations({
    required double remainingCalories,
    int remainingMeals = 1,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/recommend?remainingCalories=${remainingCalories.toInt()}&remainingMeals=$remainingMeals'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      // 에러 로깅
    }
    return {'singleFoods': [], 'combinations': []};
  }

  // ==================== AI/OCR API ====================

  /// 음식 이미지 분석 (AI 인식)
  static Future<List<FoodItem>> recognizeFood(String imagePath) async {
    try {
      // 실제 구현에서는 multipart/form-data로 이미지 전송
      final response = await http.post(
        Uri.parse('$_baseUrl/ai/recognize'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'imagePath': imagePath}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> detections = data['detections'];
          return detections.map((d) {
            final food = d['food'];
            return FoodItem(
              id: food['id'].toString(),
              name: food['name'],
              calories: (food['calories'] as num).toDouble(),
              protein: (food['protein'] as num).toDouble(),
              carbs: (food['carbs'] as num).toDouble(),
              fat: (food['fat'] as num).toDouble(),
              servingSize: (food['serving_size'] as num?)?.toDouble() ?? 100,
              unit: food['unit'] ?? 'g',
              category: food['category'],
            );
          }).toList();
        }
      }
    } catch (e) {
      // 에러 로깅
    }
    return [];
  }

  /// 영양성분표 OCR 분석
  static Future<Map<String, dynamic>?> scanNutritionLabel(String imagePath) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ocr/nutrition'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'imagePath': imagePath}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      // 에러 로깅
    }
    return null;
  }

  // ==================== 헬스 체크 ====================

  /// 서버 상태 확인
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
