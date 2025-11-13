import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nutrition_label.dart';
import 'auth_service.dart';

class OCRService {
  static const String baseUrl = 'http://localhost:3000/api';

  /// 영양성분표 사진을 OCR로 분석
  static Future<NutritionLabel> extractNutritionLabel(File imageFile) async {
    try {
      final token = await AuthService.getToken();

      // 이미지를 multipart로 전송
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ai/ocr-nutrition'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NutritionLabel.fromJson(data);
      } else {
        throw Exception('OCR 처리 실패: ${response.statusCode}');
      }
    } catch (e) {
      // 개발 중에는 더미 데이터 반환
      return _getDummyNutritionLabel();
    }
  }

  /// 개발/테스트용 더미 데이터
  static NutritionLabel _getDummyNutritionLabel() {
    return NutritionLabel(
      productName: '샘플 식품',
      calories: 250,
      carbohydrate: 35,
      sugars: 8,
      protein: 6,
      fat: 9,
      saturatedFat: 3,
      transFat: 0,
      cholesterol: 15,
      sodium: 480,
    );
  }
}
