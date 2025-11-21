import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/food_item.dart';

class OCRService {
  static final _textRecognizer = TextRecognizer();

  // 영양성분표 스캔
  static Future<Map<String, dynamic>?> scanNutritionLabel(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      return _parseNutritionInfo(recognizedText.text);
    } catch (e) {
      print('OCR 에러: $e');
      return null;
    }
  }

  // 텍스트에서 영양 정보 추출
  static Map<String, dynamic> _parseNutritionInfo(String text) {
    final result = <String, dynamic>{
      'calories': 0.0,
      'protein': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
      'servingSize': 100.0,
    };

    // 텍스트를 줄 단위로 분리
    final lines = text.split('\n');

    for (var line in lines) {
      line = line.toLowerCase().replaceAll(' ', '');

      // 칼로리 추출
      if (line.contains('칼로리') || line.contains('열량') || line.contains('kcal')) {
        final calories = _extractNumber(line);
        if (calories != null) result['calories'] = calories;
      }

      // 탄수화물 추출
      if (line.contains('탄수화물') || line.contains('carb')) {
        final carbs = _extractNumber(line);
        if (carbs != null) result['carbs'] = carbs;
      }

      // 단백질 추출
      if (line.contains('단백질') || line.contains('protein')) {
        final protein = _extractNumber(line);
        if (protein != null) result['protein'] = protein;
      }

      // 지방 추출
      if (line.contains('지방') || line.contains('fat')) {
        final fat = _extractNumber(line);
        if (fat != null) result['fat'] = fat;
      }

      // 1회 제공량 추출
      if (line.contains('1회제공량') || line.contains('servingsize') || line.contains('내용량')) {
        final serving = _extractNumber(line);
        if (serving != null) result['servingSize'] = serving;
      }
    }

    return result;
  }

  // 문자열에서 숫자 추출
  static double? _extractNumber(String text) {
    // 숫자와 소수점만 남기기
    final numberPattern = RegExp(r'[\d.]+');
    final matches = numberPattern.allMatches(text);

    if (matches.isEmpty) return null;

    // 첫 번째 숫자를 반환
    for (var match in matches) {
      final numberStr = match.group(0);
      if (numberStr != null) {
        final number = double.tryParse(numberStr);
        if (number != null && number > 0) {
          return number;
        }
      }
    }

    return null;
  }

  // 영양성분표에서 FoodItem 생성
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
        category: '스캔',
      );
    } catch (e) {
      print('FoodItem 생성 에러: $e');
      return null;
    }
  }

  // 리소스 정리
  static Future<void> dispose() async {
    await _textRecognizer.close();
  }

  // 텍스트 인식 (범용)
  static Future<String> recognizeText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print('텍스트 인식 에러: $e');
      return '';
    }
  }

  // 영양성분 검증
  static bool validateNutritionInfo(Map<String, dynamic> info) {
    // 최소한 칼로리가 있어야 함
    if (info['calories'] == null || info['calories'] <= 0) {
      return false;
    }

    // 3대 영양소 중 하나 이상은 있어야 함
    final hasProtein = info['protein'] != null && info['protein'] > 0;
    final hasCarbs = info['carbs'] != null && info['carbs'] > 0;
    final hasFat = info['fat'] != null && info['fat'] > 0;

    return hasProtein || hasCarbs || hasFat;
  }

  // OCR 결과 정리
  static Map<String, dynamic> cleanNutritionInfo(Map<String, dynamic> info) {
    return {
      'calories': (info['calories'] ?? 0.0).toDouble(),
      'protein': (info['protein'] ?? 0.0).toDouble(),
      'carbs': (info['carbs'] ?? 0.0).toDouble(),
      'fat': (info['fat'] ?? 0.0).toDouble(),
      'servingSize': (info['servingSize'] ?? 100.0).toDouble(),
    };
  }
}
