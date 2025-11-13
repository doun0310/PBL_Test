import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import 'auth_service.dart';

class FoodRecognitionService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// 음식 사진을 AI 서버로 전송하여 음식 인식
  static Future<List<Meal>> recognizeFood(File imageFile) async {
    try {
      final token = await AuthService.getToken();

      // 이미지를 multipart로 전송
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ai/recognize-food'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> foods = data['recognizedFoods'] ?? [];
        return foods.map((food) => Meal.fromJson(food)).toList();
      } else {
        throw Exception('음식 인식 실패: ${response.statusCode}');
      }
    } catch (e) {
      // 개발 중에는 더미 데이터 반환
      return _getDummyRecognizedFoods();
    }
  }

  /// 개발/테스트용 더미 데이터
  static List<Meal> _getDummyRecognizedFoods() {
    return [
      Meal(
        name: '삼겹살',
        calories: 518,
        protein: 17,
        carbs: 0,
        fat: 50,
        allergens: ['돼지고기'],
      ),
      Meal(
        name: '김치찌개',
        calories: 220,
        protein: 12,
        carbs: 15,
        fat: 13,
        allergens: ['새우젓'],
      ),
      Meal(
        name: '흰쌀밥',
        calories: 310,
        protein: 6,
        carbs: 68,
        fat: 1,
        allergens: [],
      ),
    ];
  }
}
