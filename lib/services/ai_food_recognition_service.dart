import 'dart:math';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/food_item.dart';
import 'food_database_service.dart';

class AIFoodRecognitionService {
  // ML Kit 이미지 라벨러
  static final _imageLabeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.5),
  );

  // 음식 인식 (시뮬레이션)
  static Future<List<FoodItem>> recognizeFood(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await _imageLabeler.processImage(inputImage);

      // 인식된 라벨을 음식 데이터베이스와 매칭
      final recognizedFoods = <FoodItem>[];
      final allFoods = FoodDatabaseService.getAllFoods();

      for (var label in labels) {
        final matchedFood = _findMatchingFood(label.label, allFoods);
        if (matchedFood != null && !recognizedFoods.contains(matchedFood)) {
          recognizedFoods.add(matchedFood);
        }
      }

      // 라벨 매칭이 없는 경우 유사한 음식 제안
      if (recognizedFoods.isEmpty) {
        recognizedFoods.addAll(_getSuggestedFoods(allFoods, 3));
      }

      return recognizedFoods;
    } catch (e) {
      // 에러 시 시뮬레이션 결과 반환
      return _simulateRecognition();
    }
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
    await _imageLabeler.close();
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
