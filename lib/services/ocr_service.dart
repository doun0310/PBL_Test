import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

/// EasyOCR 기반 영양성분표 스캔 서비스
class OCRService {
  // EasyOCR API 엔드포인트 (실제 배포 시 서버 주소로 변경)
  static const String _easyOcrEndpoint = 'http://192.168.219.113:5000/ocr';

  /// EasyOCR을 사용한 영양성분표 스캔
  static Future<Map<String, dynamic>?> scanNutritionLabel(String imagePath) async {
    try {
      // EasyOCR API 호출하여 파싱된 결과(Map)를 직접 받음
      final result = await _callEasyOcrApi(imagePath);

      if (result != null && result['success'] == true && result['nutrition'] != null) {
        debugPrint('[OCRService] Nutrition data received successfully.');
        // 서버에서 받은 nutrition 데이터와 raw_text를 포함하여 반환
        final nutritionData = result['nutrition'] as Map<String, dynamic>;
        return {
          'calories': nutritionData['calories'],
          'protein': nutritionData['protein'],
          'carbs': nutritionData['carbs'], // 서버는 'carbs' 키를 사용
          'fat': nutritionData['fat'],
          'servingSize': 100.0, // 기본값 또는 서버에서 제공하는 값 사용
          'rawText': result['raw_text'] ?? '',
        };
      }

      debugPrint('[OCRService] API call failed or returned no nutrition data.');
      return null;
    } catch (e) {
      debugPrint('[OCRService] Error during scanNutritionLabel: $e');
      return null;
    }
  }

  /// EasyOCR API 호출 (MultipartRequest 사용)
  /// 서버로부터 Map 형태의 JSON 객체를 반환
  static Future<Map<String, dynamic>?> _callEasyOcrApi(String imagePath) async {
    try {
      final uri = Uri.parse(_easyOcrEndpoint);
      final request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      debugPrint('[OCRService] Calling API with image file: $imagePath');

      final response = await request.send().timeout(const Duration(seconds: 30));

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        debugPrint('[OCRService] API call successful.');
        final result = json.decode(responseBody) as Map<String, dynamic>;
        return result;
      } else {
        debugPrint('[OCRService] API call failed with status code: ${response.statusCode}');
        debugPrint('[OCRService] Response body: $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('[OCRService] Exception during API call: $e');
      return null;
    }
  }

  /// 스캔 결과로 FoodItem 생성
  static FoodItem? createFoodItemFromScan(
      String name,
      Map<String, dynamic> nutritionInfo,
      ) {
    try {
      return FoodItem(
        name: name,
        calories: nutritionInfo['calories']?.toDouble() ?? 0.0,
        protein: nutritionInfo['protein']?.toDouble() ?? 0.0,
        carbs: nutritionInfo['carbs']?.toDouble() ?? 0.0,
        fat: nutritionInfo['fat']?.toDouble() ?? 0.0,
        servingSize: nutritionInfo['servingSize']?.toDouble() ?? 100.0,
        unit: 'g',
        category: 'EasyOCR 스캔',
        id: 'easyocr_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      debugPrint('[OCRService] Error creating FoodItem: $e');
      return null;
    }
  }

  /// 텍스트 인식 (범용) - 서버 응답 구조에 맞게 수정
  static Future<String> recognizeText(String imagePath) async {
    try {
      final result = await _callEasyOcrApi(imagePath);
      if (result != null && result['success'] == true && result['raw_text'] != null) {
        return result['raw_text'];
      }
      return 'EasyOCR: 텍스트를 인식할 수 없습니다.';
    } catch (e) {
      debugPrint('[OCRService] Error in recognizeText: $e');
      return '텍스트 인식 중 오류가 발생했습니다.';
    }
  }

  /// 영양성분 검증
  static bool validateNutritionInfo(Map<String, dynamic> info) {
    final calories = info['calories'] as num?;
    if (calories == null || calories <= 0) {
      return false;
    }
    final hasProtein = (info['protein'] as num?) != null && info['protein'] > 0;
    final hasCarbs = (info['carbs'] as num?) != null && info['carbs'] > 0;
    final hasFat = (info['fat'] as num?) != null && info['fat'] > 0;
    return hasProtein || hasCarbs || hasFat;
  }

  /// OCR 결과 정리 (null 값을 0.0으로 변환)
  static Map<String, dynamic> cleanNutritionInfo(Map<String, dynamic> info) {
    return {
      'calories': (info['calories'] as num?)?.toDouble() ?? 0.0,
      'protein': (info['protein'] as num?)?.toDouble() ?? 0.0,
      'carbs': (info['carbs'] as num?)?.toDouble() ?? 0.0,
      'fat': (info['fat'] as num?)?.toDouble() ?? 0.0,
      'servingSize': (info['servingSize'] as num?)?.toDouble() ?? 100.0,
      'rawText': info['rawText'] ?? '',
    };
  }
}
