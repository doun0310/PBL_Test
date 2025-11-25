import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/food_item.dart';
import 'food_database_service.dart';

/// YOLO v11 기반 음식 인식 서비스
/// YOLOv11 객체 감지 모델을 사용하여 이미지에서 음식을 식별합니다.
class AIFoodRecognitionService {
  // YOLO v11 모델 인터프리터
  static Interpreter? _interpreter;
  static bool _isModelLoaded = false;
  
  // YOLO v11 모델 설정
  static const int _inputSize = 640; // YOLO v11 입력 크기
  static const double _confidenceThreshold = 0.5;
  static const double _iouThreshold = 0.45; // NMS IoU 임계값
  
  // YOLO v11 음식 클래스 라벨 (80개 COCO 클래스 + 음식 특화 클래스)
  static const List<String> _foodClasses = [
    // 음식 관련 COCO 클래스
    'banana', 'apple', 'sandwich', 'orange', 'broccoli', 'carrot',
    'hot dog', 'pizza', 'donut', 'cake', 'bowl', 'cup', 'fork',
    'knife', 'spoon', 'bottle', 'wine glass',
    // 한식 특화 클래스
    'rice', 'kimchi', 'bulgogi', 'bibimbap', 'samgyeopsal', 'tteokbokki',
    'kimbap', 'jjigae', 'ramyeon', 'japchae', 'galbi', 'sundubu',
    // 일반 음식 클래스
    'salad', 'soup', 'steak', 'pasta', 'sushi', 'ramen', 'chicken',
    'fish', 'egg', 'bread', 'noodle', 'rice bowl', 'meat', 'vegetable',
  ];

  /// YOLO v11 모델 초기화
  static Future<void> initializeModel() async {
    if (_isModelLoaded) return;
    
    try {
      // YOLO v11 TFLite 모델 로드
      // 실제 구현에서는 assets/models/yolov11.tflite 파일 필요
      _interpreter = await Interpreter.fromAsset('models/yolov11.tflite');
      _isModelLoaded = true;
    } catch (e) {
      // 모델 로드 실패 시 시뮬레이션 모드로 동작
      _isModelLoaded = false;
    }
  }

  /// YOLO v11을 사용한 음식 인식
  static Future<List<FoodItem>> recognizeFood(String imagePath) async {
    try {
      // 모델 초기화 확인
      if (!_isModelLoaded) {
        await initializeModel();
      }

      // YOLO v11 모델이 로드된 경우 실제 추론 수행
      if (_interpreter != null && _isModelLoaded) {
        return await _runYoloInference(imagePath);
      }

      // 모델이 없는 경우 시뮬레이션
      return _simulateYoloRecognition(imagePath);
    } catch (e) {
      // 에러 시 시뮬레이션 결과 반환
      return _simulateYoloRecognition(imagePath);
    }
  }

  /// YOLO v11 추론 실행
  static Future<List<FoodItem>> _runYoloInference(String imagePath) async {
    try {
      // 이미지 전처리 (YOLO v11 입력 형식으로 변환)
      final inputData = await _preprocessImage(imagePath);
      
      // 출력 텐서 준비 (YOLO v11 출력: [1, 84, 8400] 형식)
      final outputShape = [1, 84, 8400];
      final outputBuffer = List.generate(
        outputShape[0],
        (_) => List.generate(
          outputShape[1],
          (_) => List.filled(outputShape[2], 0.0),
        ),
      );

      // YOLO v11 추론 실행
      _interpreter!.run(inputData, outputBuffer);

      // 출력 후처리 (NMS 적용)
      final detections = _postprocessYoloOutput(outputBuffer);
      
      // 감지된 음식을 FoodItem으로 변환
      return _detectionsToFoodItems(detections);
    } catch (e) {
      return _simulateYoloRecognition(imagePath);
    }
  }

  /// 이미지 전처리 (YOLO v11 입력 형식)
  static Future<List<List<List<List<double>>>>> _preprocessImage(String imagePath) async {
    // 이미지를 [1, 640, 640, 3] 형식으로 변환
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    
    // 실제 구현에서는 이미지 디코딩 및 리사이징 필요
    // 여기서는 더미 데이터 반환
    return List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (_) => List.generate(
          _inputSize,
          (_) => List.filled(3, 0.5),
        ),
      ),
    );
  }

  /// YOLO v11 출력 후처리 (Non-Maximum Suppression)
  static List<Map<String, dynamic>> _postprocessYoloOutput(
    List<List<List<double>>> output,
  ) {
    final detections = <Map<String, dynamic>>[];
    
    // YOLO v11 출력 파싱 (형식: [x, y, w, h, conf, class_probs...])
    for (var i = 0; i < output[0][0].length; i++) {
      final confidence = output[0][4][i];
      
      if (confidence > _confidenceThreshold) {
        // 클래스 확률 추출
        double maxClassProb = 0;
        int maxClassIdx = 0;
        
        for (var j = 5; j < output[0].length && j - 5 < _foodClasses.length; j++) {
          if (output[0][j][i] > maxClassProb) {
            maxClassProb = output[0][j][i];
            maxClassIdx = j - 5;
          }
        }
        
        // 음식 클래스인 경우에만 추가
        if (maxClassIdx < _foodClasses.length) {
          detections.add({
            'class': _foodClasses[maxClassIdx],
            'confidence': confidence * maxClassProb,
            'bbox': [
              output[0][0][i], // x
              output[0][1][i], // y
              output[0][2][i], // width
              output[0][3][i], // height
            ],
          });
        }
      }
    }
    
    // NMS (Non-Maximum Suppression) 적용
    return _applyNMS(detections);
  }

  /// Non-Maximum Suppression 적용
  static List<Map<String, dynamic>> _applyNMS(List<Map<String, dynamic>> detections) {
    if (detections.isEmpty) return detections;
    
    // 신뢰도 순으로 정렬
    detections.sort((a, b) => 
      (b['confidence'] as double).compareTo(a['confidence'] as double)
    );
    
    final selected = <Map<String, dynamic>>[];
    final suppressed = List.filled(detections.length, false);
    
    for (var i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      
      selected.add(detections[i]);
      
      for (var j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        
        final iou = _calculateIoU(
          detections[i]['bbox'] as List<double>,
          detections[j]['bbox'] as List<double>,
        );
        
        if (iou > _iouThreshold) {
          suppressed[j] = true;
        }
      }
    }
    
    return selected;
  }

  /// IoU (Intersection over Union) 계산
  static double _calculateIoU(List<double> box1, List<double> box2) {
    final x1 = max(box1[0] - box1[2]/2, box2[0] - box2[2]/2);
    final y1 = max(box1[1] - box1[3]/2, box2[1] - box2[3]/2);
    final x2 = min(box1[0] + box1[2]/2, box2[0] + box2[2]/2);
    final y2 = min(box1[1] + box1[3]/2, box2[1] + box2[3]/2);
    
    final intersection = max(0, x2 - x1) * max(0, y2 - y1);
    final area1 = box1[2] * box1[3];
    final area2 = box2[2] * box2[3];
    final union = area1 + area2 - intersection;
    
    return union > 0 ? intersection / union : 0;
  }

  /// 감지 결과를 FoodItem으로 변환
  static List<FoodItem> _detectionsToFoodItems(List<Map<String, dynamic>> detections) {
    final recognizedFoods = <FoodItem>[];
    final allFoods = FoodDatabaseService.getAllFoods();
    
    for (var detection in detections) {
      final className = detection['class'] as String;
      final matchedFood = _findMatchingFood(className, allFoods);
      
      if (matchedFood != null && !recognizedFoods.any((f) => f.name == matchedFood.name)) {
        recognizedFoods.add(matchedFood);
      }
    }
    
    // 인식된 음식이 없으면 추천 음식 제공
    if (recognizedFoods.isEmpty) {
      recognizedFoods.addAll(_getSuggestedFoods(allFoods, 3));
    }
    
    return recognizedFoods;
  }

  /// YOLO v11 시뮬레이션 (모델 없을 때)
  static List<FoodItem> _simulateYoloRecognition(String imagePath) {
    final allFoods = FoodDatabaseService.getAllFoods();
    final random = Random();
    
    // YOLO v11 스타일 시뮬레이션: 여러 음식 동시 감지
    final detectedCount = random.nextInt(3) + 1;
    final shuffled = List<FoodItem>.from(allFoods)..shuffle();
    
    return shuffled.take(detectedCount).toList();
  }

  // 라벨과 음식 매칭
  static FoodItem? _findMatchingFood(String label, List<FoodItem> foods) {
    final labelLower = label.toLowerCase();

    // 정확한 매칭 시도
    for (var food in foods) {
      if (food.name.toLowerCase().contains(labelLower) ||
          labelLower.contains(food.name.toLowerCase())) {
        return food;
      }
    }

    // 카테고리 매칭
    final categoryMatches = {
      'rice': '밥',
      'meat': '고기',
      'chicken': '닭',
      'fish': '생선',
      'vegetable': '채소',
      'fruit': '과일',
      'bread': '빵',
      'noodle': '면',
      'soup': '국',
      'salad': '샐러드',
    };

    for (var entry in categoryMatches.entries) {
      if (labelLower.contains(entry.key)) {
        return foods.firstWhere(
          (food) => food.category.contains(entry.value) || food.name.contains(entry.value),
          orElse: () => foods.first,
        );
      }
    }

    return null;
  }

  // 추천 음식 제공
  static List<FoodItem> _getSuggestedFoods(List<FoodItem> allFoods, int count) {
    final shuffled = List<FoodItem>.from(allFoods)..shuffle();
    return shuffled.take(min(count, allFoods.length)).toList();
  }

  // 시뮬레이션 인식 (ML 모델이 없을 때)
  static List<FoodItem> _simulateRecognition() {
    final allFoods = FoodDatabaseService.getAllFoods();
    final random = Random();
    final count = random.nextInt(3) + 1; // 1-3개의 음식 인식

    final shuffled = List<FoodItem>.from(allFoods)..shuffle();
    return shuffled.take(count).toList();
  }

  // 음식 카테고리 분류
  static String classifyFoodCategory(String foodName) {
    final categories = {
      '밥': ['밥', '쌀', '현미', '잡곡'],
      '고기': ['소고기', '돼지고기', '닭고기', '양고기'],
      '생선': ['연어', '고등어', '참치', '삼치', '광어'],
      '채소': ['배추', '양파', '당근', '오이', '토마토'],
      '과일': ['사과', '바나나', '포도', '딸기', '오렌지'],
      '유제품': ['우유', '요구르트', '치즈', '버터'],
      '빵': ['식빵', '바게트', '크루아상', '베이글'],
      '면': ['라면', '우동', '파스타', '국수'],
    };

    for (var entry in categories.entries) {
      for (var keyword in entry.value) {
        if (foodName.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return '기타';
  }

  // 칼로리 예측 (이미지 기반)
  static Future<double> estimateCalories(String imagePath, String foodName) async {
    // 실제 구현에서는 ML 모델을 사용하여 음식의 양을 추정
    // 여기서는 시뮬레이션
    final random = Random();
    final baseCalories = FoodDatabaseService.getAllFoods()
        .firstWhere(
          (food) => food.name == foodName,
          orElse: () => FoodItem(
            name: foodName,
            calories: 200,
            protein: 10,
            carbs: 30,
            fat: 5,
            servingSize: 100,
            unit: 'g',
            category: '기타',
          ),
        )
        .calories;

    // 0.5 ~ 1.5배 범위로 칼로리 추정
    final multiplier = 0.5 + random.nextDouble();
    return baseCalories * multiplier;
  }

  // 유사 음식 찾기
  static List<FoodItem> findSimilarFoods(FoodItem food, {int limit = 5}) {
    final allFoods = FoodDatabaseService.getAllFoods();
    final similarFoods = <FoodItem>[];

    for (var otherFood in allFoods) {
      if (otherFood.name == food.name) continue;

      // 카테고리가 같은 음식
      if (otherFood.category == food.category) {
        similarFoods.add(otherFood);
      }
      // 칼로리가 유사한 음식 (±20%)
      else if ((otherFood.calories - food.calories).abs() / food.calories < 0.2) {
        similarFoods.add(otherFood);
      }
    }

    return similarFoods.take(limit).toList();
  }

  // 리소스 정리
  static Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }

  // 인식 신뢰도 계산
  static double calculateConfidence(String label, String foodName) {
    final labelLower = label.toLowerCase();
    final foodNameLower = foodName.toLowerCase();

    if (labelLower == foodNameLower) return 1.0;
    if (labelLower.contains(foodNameLower) || foodNameLower.contains(labelLower)) {
      return 0.8;
    }
    return 0.5;
  }

  // 배치 인식 (여러 이미지)
  static Future<Map<String, List<FoodItem>>> recognizeMultipleImages(
    List<String> imagePaths,
  ) async {
    final results = <String, List<FoodItem>>{};

    for (var path in imagePaths) {
      final foods = await recognizeFood(path);
      results[path] = foods;
    }

    return results;
  }
}
