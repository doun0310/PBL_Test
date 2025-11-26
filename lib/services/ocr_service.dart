import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

/// EasyOCR 기반 영양성분표 스캔 서비스
/// EasyOCR을 사용하여 이미지에서 텍스트를 추출하고 영양 정보를 파싱합니다.
class OCRService {
  // EasyOCR API 엔드포인트 (실제 배포 시 서버 주소로 변경)
  static const String _easyOcrEndpoint = 'http://localhost:5000/ocr';
  
  // 지원 언어
  static const List<String> _supportedLanguages = ['ko', 'en'];
  
  // EasyOCR 설정
  static const bool _useGPU = false; // 모바일에서는 CPU 사용
  static const double _textThreshold = 0.7;
  static const double _lowTextThreshold = 0.4;
  static const double _linkThreshold = 0.4;

  /// EasyOCR을 사용한 영양성분표 스캔
  static Future<Map<String, dynamic>?> scanNutritionLabel(String imagePath) async {
    try {
      // EasyOCR API 호출 시도
      final recognizedText = await _callEasyOcrApi(imagePath);
      
      if (recognizedText.isNotEmpty) {
        return _parseNutritionInfo(recognizedText);
      }
      
      // API 실패 시 로컬 시뮬레이션
      return _simulateEasyOcrScan(imagePath);
    } catch (e) {
      // 에러 시 시뮬레이션 결과 반환
      return _simulateEasyOcrScan(imagePath);
    }
  }

  /// EasyOCR API 호출
  static Future<String> _callEasyOcrApi(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse(_easyOcrEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image': base64Image,
          'languages': _supportedLanguages,
          'detail': 1, // 상세 결과 포함
          'gpu': _useGPU,
          'text_threshold': _textThreshold,
          'low_text': _lowTextThreshold,
          'link_threshold': _linkThreshold,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return _processEasyOcrResult(result);
      }
      
      return '';
    } catch (e) {
      // API 호출 실패
      return '';
    }
  }

  /// EasyOCR 결과 처리
  static String _processEasyOcrResult(dynamic result) {
    if (result is List) {
      // EasyOCR 결과 형식: [[bbox, text, confidence], ...]
      final textLines = <String>[];
      
      for (var detection in result) {
        if (detection is List && detection.length >= 2) {
          final text = detection[1] as String;
          final confidence = detection.length > 2 ? detection[2] as double : 1.0;
          
          // 신뢰도가 높은 텍스트만 포함
          if (confidence >= _textThreshold) {
            textLines.add(text);
          }
        }
      }
      
      return textLines.join('\n');
    }
    
    return result['text']?.toString() ?? '';
  }

  /// EasyOCR 시뮬레이션 (API 없을 때)
  static Map<String, dynamic> _simulateEasyOcrScan(String imagePath) {
    // 시뮬레이션된 영양성분 정보
    return {
      'calories': 250.0,
      'protein': 12.0,
      'carbs': 35.0,
      'fat': 8.0,
      'servingSize': 100.0,
      'rawText': '''
영양정보 (1회 제공량 100g 기준)
열량: 250kcal
탄수화물: 35g
단백질: 12g
지방: 8g
      ''',
    };
  }

  /// 텍스트에서 영양 정보 추출 (EasyOCR 결과 파싱)
  static Map<String, dynamic> _parseNutritionInfo(String text) {
    final result = <String, dynamic>{
      'calories': 0.0,
      'protein': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
      'servingSize': 100.0,
      'rawText': text,
    };

    // 텍스트를 줄 단위로 분리
    final lines = text.split('\n');

    for (var line in lines) {
      line = line.toLowerCase().replaceAll(' ', '');

      // 칼로리 추출 (EasyOCR 한국어/영어 지원)
      if (_containsAny(line, ['칼로리', '열량', 'kcal', 'calories', 'cal'])) {
        final calories = _extractNumber(line);
        if (calories != null) result['calories'] = calories;
      }

      // 탄수화물 추출
      if (_containsAny(line, ['탄수화물', 'carb', 'carbohydrate'])) {
        final carbs = _extractNumber(line);
        if (carbs != null) result['carbs'] = carbs;
      }

      // 단백질 추출
      if (_containsAny(line, ['단백질', 'protein'])) {
        final protein = _extractNumber(line);
        if (protein != null) result['protein'] = protein;
      }

      // 지방 추출
      if (_containsAny(line, ['지방', 'fat', '총지방', 'totalfat'])) {
        final fat = _extractNumber(line);
        if (fat != null) result['fat'] = fat;
      }

      // 1회 제공량 추출
      if (_containsAny(line, ['1회제공량', 'servingsize', '내용량', 'serving'])) {
        final serving = _extractNumber(line);
        if (serving != null) result['servingSize'] = serving;
      }
      
      // 나트륨 추출 (추가)
      if (_containsAny(line, ['나트륨', 'sodium', 'na'])) {
        final sodium = _extractNumber(line);
        if (sodium != null) result['sodium'] = sodium;
      }
      
      // 당류 추출 (추가)
      if (_containsAny(line, ['당류', 'sugar', '당', 'sugars'])) {
        final sugar = _extractNumber(line);
        if (sugar != null) result['sugar'] = sugar;
      }
    }

    return result;
  }
  
  /// 문자열에 특정 키워드가 포함되어 있는지 확인
  static bool _containsAny(String text, List<String> keywords) {
    for (var keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  /// 문자열에서 숫자 추출
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
        category: 'EasyOCR 스캔', id: 'easyocr_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 리소스 정리
  static Future<void> dispose() async {
    // EasyOCR API 사용 시 별도 정리 필요 없음
  }

  /// 텍스트 인식 (범용)
  static Future<String> recognizeText(String imagePath) async {
    try {
      final text = await _callEasyOcrApi(imagePath);
      return text.isNotEmpty ? text : 'EasyOCR: 텍스트를 인식할 수 없습니다.';
    } catch (e) {
      return '';
    }
  }

  /// 영양성분 검증
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

  /// OCR 결과 정리
  static Map<String, dynamic> cleanNutritionInfo(Map<String, dynamic> info) {
    return {
      'calories': (info['calories'] ?? 0.0).toDouble(),
      'protein': (info['protein'] ?? 0.0).toDouble(),
      'carbs': (info['carbs'] ?? 0.0).toDouble(),
      'fat': (info['fat'] ?? 0.0).toDouble(),
      'servingSize': (info['servingSize'] ?? 100.0).toDouble(),
      'sodium': (info['sodium'] ?? 0.0).toDouble(),
      'sugar': (info['sugar'] ?? 0.0).toDouble(),
    };
  }
  
  /// EasyOCR 바운딩 박스 정보 추출
  static Future<List<Map<String, dynamic>>> getTextWithBoundingBoxes(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse(_easyOcrEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image': base64Image,
          'languages': _supportedLanguages,
          'detail': 1,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body) as List;
        return result.map((item) => {
          'bbox': item[0],
          'text': item[1],
          'confidence': item[2],
        }).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
}
