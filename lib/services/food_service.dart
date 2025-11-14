import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';
import 'auth_service.dart';

class FoodService {
  static const String baseUrl = 'http://localhost:3000/api';

  // AI를 사용한 음식 이미지 분석 (Mock implementation)
  static Future<Meal> analyzeFoodImage(File imageFile) async {
    // In production, this would send the image to an AI service
    // For now, we'll simulate the analysis with a delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock AI analysis result
    return Meal(
      name: '샘플 음식',
      calories: 350,
      protein: 20,
      carbs: 45,
      fat: 12,
      allergens: [],
      timestamp: DateTime.now(),
    );
  }

  // 음식 저장 (로컬 및 서버)
  static Future<void> saveMeal(Meal meal) async {
    try {
      // Save to local storage first
      await _saveToLocal(meal);

      // Try to sync with server
      final token = await AuthService.getToken();
      if (token != null) {
        try {
          final response = await http.post(
            Uri.parse('$baseUrl/meals'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(meal.toJson()),
          );

          if (response.statusCode == 201) {
            print('✅ 음식이 서버에 저장되었습니다.');
          }
        } catch (e) {
          print('⚠️ 서버 동기화 실패, 로컬에만 저장됨: $e');
        }
      }
    } catch (e) {
      print('❌ 음식 저장 실패: $e');
      rethrow;
    }
  }

  // 로컬에 음식 저장
  static Future<void> _saveToLocal(Meal meal) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing foods
    final foodsJson = prefs.getString('saved_foods');
    List<Map<String, dynamic>> foods = [];
    
    if (foodsJson != null) {
      foods = List<Map<String, dynamic>>.from(jsonDecode(foodsJson));
    }
    
    // Add new food with generated ID
    final mealWithId = meal.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    
    foods.add(mealWithId.toJson());
    
    // Save back to preferences
    await prefs.setString('saved_foods', jsonEncode(foods));
  }

  // 저장된 음식 목록 가져오기
  static Future<List<Meal>> getSavedFoods() async {
    try {
      // First try to get from server
      final token = await AuthService.getToken();
      if (token != null) {
        try {
          final response = await http.get(
            Uri.parse('$baseUrl/foods'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            return data.map((json) => Meal.fromJson(json)).toList();
          }
        } catch (e) {
          print('⚠️ 서버에서 음식 목록 가져오기 실패: $e');
        }
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final foodsJson = prefs.getString('saved_foods');
      
      if (foodsJson != null) {
        final List<dynamic> data = jsonDecode(foodsJson);
        return data.map((json) => Meal.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('❌ 음식 목록 가져오기 실패: $e');
      return [];
    }
  }

  // 음식 삭제
  static Future<void> deleteFood(String id) async {
    try {
      // Delete from local storage
      final prefs = await SharedPreferences.getInstance();
      final foodsJson = prefs.getString('saved_foods');
      
      if (foodsJson != null) {
        List<Map<String, dynamic>> foods = 
            List<Map<String, dynamic>>.from(jsonDecode(foodsJson));
        
        foods.removeWhere((food) => food['id'].toString() == id);
        
        await prefs.setString('saved_foods', jsonEncode(foods));
      }

      // Try to delete from server
      final token = await AuthService.getToken();
      if (token != null) {
        try {
          await http.delete(
            Uri.parse('$baseUrl/foods/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        } catch (e) {
          print('⚠️ 서버에서 음식 삭제 실패: $e');
        }
      }
    } catch (e) {
      print('❌ 음식 삭제 실패: $e');
      rethrow;
    }
  }

  // 음식 검색
  static Future<List<Meal>> searchFoods(String query) async {
    final allFoods = await getSavedFoods();
    
    if (query.isEmpty) {
      return allFoods;
    }
    
    return allFoods.where((food) {
      return food.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
