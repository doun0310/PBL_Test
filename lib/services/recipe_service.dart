import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../models/user_goals.dart';
import 'meal_tracking_service.dart';

/// Collaborative Filtering 기반 레시피 추천 서비스
/// 사용자 행동 데이터와 유사 사용자 패턴을 분석하여 맞춤형 레시피를 추천합니다.
class RecipeService {
  static const String _recipesKey = 'recipes_data';
  static const String _userRatingsKey = 'user_ratings';
  static const String _viewHistoryKey = 'recipe_view_history';
  static const String _cookHistoryKey = 'recipe_cook_history';
  
  // Collaborative Filtering 설정
  static const int _minRatingsForCF = 5; // CF 적용을 위한 최소 평점 수
  static const int _neighborhoodSize = 10; // 유사 사용자 수
  static const double _similarityThreshold = 0.3; // 유사도 임계값

  // 샘플 레시피 데이터
  static List<Recipe> _getSampleRecipes() {
    return [
      Recipe(
        name: '닭가슴살 샐러드',
        description: '신선한 채소와 구운 닭가슴살로 만든 건강한 샐러드',
        ingredients: [
          '닭가슴살 150g',
          '양상추 50g',
          '방울토마토 5개',
          '오이 1/2개',
          '올리브유 1스푼',
          '레몬즙 약간',
        ],
        instructions: [
          '닭가슴살을 소금, 후추로 밑간한다',
          '팬에 닭가슴살을 구워 익힌다',
          '채소를 깨끗이 씻어 먹기 좋은 크기로 자른다',
          '구운 닭가슴살을 먹기 좋게 썬다',
          '모든 재료를 볼에 담고 올리브유와 레몬즙으로 버무린다',
        ],
        calories: 250,
        protein: 35,
        carbs: 10,
        fat: 8,
        prepTimeMinutes: 10,
        cookTimeMinutes: 15,
        servings: 1,
        category: '다이어트',
        tags: ['저칼로리', '고단백', '샐러드'],
      ),
      Recipe(
        name: '연어 아보카도 덮밥',
        description: '오메가3가 풍부한 연어와 아보카도의 영양 덮밥',
        ingredients: [
          '현미밥 200g',
          '연어 100g',
          '아보카도 1/2개',
          '김 약간',
          '간장 1스푼',
          '참기름 약간',
        ],
        instructions: [
          '연어를 적당한 크기로 자른다',
          '아보카도를 슬라이스한다',
          '현미밥을 그릇에 담는다',
          '밥 위에 연어, 아보카도를 올린다',
          '김을 부숴 뿌리고 간장, 참기름으로 간한다',
        ],
        calories: 480,
        protein: 28,
        carbs: 55,
        fat: 18,
        prepTimeMinutes: 15,
        cookTimeMinutes: 0,
        servings: 1,
        category: '일반',
        tags: ['영양만점', '간편', '덮밥'],
      ),
      Recipe(
        name: '그릭 요거트 과일 볼',
        description: '단백질이 풍부한 그릭 요거트와 신선한 과일의 조합',
        ingredients: [
          '그릭 요거트 200g',
          '블루베리 30g',
          '딸기 50g',
          '바나나 1/2개',
          '꿀 1티스푼',
          '그래놀라 20g',
        ],
        instructions: [
          '과일을 깨끗이 씻어 먹기 좋게 자른다',
          '볼에 그릭 요거트를 담는다',
          '과일을 요거트 위에 올린다',
          '그래놀라를 뿌린다',
          '꿀을 살짝 뿌려 완성한다',
        ],
        calories: 320,
        protein: 18,
        carbs: 48,
        fat: 6,
        prepTimeMinutes: 5,
        cookTimeMinutes: 0,
        servings: 1,
        category: '간식',
        tags: ['간편', '아침식사', '과일'],
      ),
      Recipe(
        name: '두부 스테이크',
        description: '고단백 저칼로리 두부로 만든 건강한 스테이크',
        ingredients: [
          '두부 200g',
          '양파 1/2개',
          '파프리카 1/2개',
          '간장 2스푼',
          '올리브유 1스푼',
          '마늘 2쪽',
        ],
        instructions: [
          '두부의 물기를 제거하고 1cm 두께로 자른다',
          '양파와 파프리카를 채썬다',
          '팬에 올리브유를 두르고 두부를 굽는다',
          '양파, 파프리카, 마늘을 볶는다',
          '간장으로 간을 맞추고 두부와 함께 담아낸다',
        ],
        calories: 220,
        protein: 18,
        carbs: 12,
        fat: 12,
        prepTimeMinutes: 10,
        cookTimeMinutes: 15,
        servings: 1,
        category: '다이어트',
        tags: ['저칼로리', '고단백', '채식'],
      ),
      Recipe(
        name: '퀴노아 볼',
        description: '슈퍼푸드 퀴노아로 만든 영양 만점 한 그릇',
        ingredients: [
          '퀴노아 100g',
          '닭가슴살 100g',
          '브로콜리 50g',
          '당근 30g',
          '아보카도 1/4개',
          '레몬 드레싱',
        ],
        instructions: [
          '퀴노아를 깨끗이 씻어 물과 함께 끓인다',
          '닭가슴살을 구워 먹기 좋게 썬다',
          '브로콜리와 당근을 데친다',
          '볼에 퀴노아를 담고 재료를 올린다',
          '레몬 드레싱을 뿌려 완성한다',
        ],
        calories: 380,
        protein: 32,
        carbs: 42,
        fat: 10,
        prepTimeMinutes: 15,
        cookTimeMinutes: 20,
        servings: 1,
        category: '건강식',
        tags: ['영양만점', '슈퍼푸드', '균형식'],
      ),
    ];
  }

  // ==========================================
  // Collaborative Filtering 핵심 알고리즘
  // ==========================================

  /// 사용자-아이템 평점 행렬 로드
  static Future<Map<String, Map<String, double>>> _loadUserRatingsMatrix() async {
    final prefs = await SharedPreferences.getInstance();
    final ratingsJson = prefs.getString(_userRatingsKey);
    
    if (ratingsJson == null) return {};
    
    final Map<String, dynamic> decoded = json.decode(ratingsJson);
    final result = <String, Map<String, double>>{};
    
    decoded.forEach((userId, ratings) {
      result[userId] = Map<String, double>.from(
        (ratings as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
      );
    });
    
    return result;
  }

  /// 현재 사용자의 평점 저장
  static Future<void> rateRecipe(String recipeName, double rating) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = 'current_user'; // 실제 구현에서는 사용자 ID 사용
    
    final matrix = await _loadUserRatingsMatrix();
    matrix[currentUserId] ??= {};
    matrix[currentUserId]![recipeName] = rating;
    
    await prefs.setString(_userRatingsKey, json.encode(matrix));
  }

  /// 피어슨 상관계수 계산 (사용자 유사도)
  static double _calculatePearsonCorrelation(
    Map<String, double> user1Ratings,
    Map<String, double> user2Ratings,
  ) {
    // 두 사용자가 모두 평가한 아이템 찾기
    final commonItems = user1Ratings.keys
        .where((item) => user2Ratings.containsKey(item))
        .toList();
    
    if (commonItems.length < 2) return 0.0;
    
    // 평균 계산
    final user1Mean = user1Ratings.values.reduce((a, b) => a + b) / user1Ratings.length;
    final user2Mean = user2Ratings.values.reduce((a, b) => a + b) / user2Ratings.length;
    
    // 피어슨 상관계수 계산
    double numerator = 0;
    double denominator1 = 0;
    double denominator2 = 0;
    
    for (var item in commonItems) {
      final diff1 = user1Ratings[item]! - user1Mean;
      final diff2 = user2Ratings[item]! - user2Mean;
      
      numerator += diff1 * diff2;
      denominator1 += diff1 * diff1;
      denominator2 += diff2 * diff2;
    }
    
    if (denominator1 == 0 || denominator2 == 0) return 0.0;
    
    return numerator / (sqrt(denominator1) * sqrt(denominator2));
  }

  /// 코사인 유사도 계산 (아이템 유사도)
  static double _calculateCosineSimilarity(
    Map<String, double> vector1,
    Map<String, double> vector2,
  ) {
    final allKeys = {...vector1.keys, ...vector2.keys};
    
    double dotProduct = 0;
    double norm1 = 0;
    double norm2 = 0;
    
    for (var key in allKeys) {
      final val1 = vector1[key] ?? 0;
      final val2 = vector2[key] ?? 0;
      
      dotProduct += val1 * val2;
      norm1 += val1 * val1;
      norm2 += val2 * val2;
    }
    
    if (norm1 == 0 || norm2 == 0) return 0.0;
    
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }

  /// K-최근접 이웃 찾기
  static List<MapEntry<String, double>> _findKNearestNeighbors(
    String targetUser,
    Map<String, Map<String, double>> ratingsMatrix,
    int k,
  ) {
    final targetRatings = ratingsMatrix[targetUser];
    if (targetRatings == null || targetRatings.isEmpty) return [];
    
    final similarities = <MapEntry<String, double>>[];
    
    ratingsMatrix.forEach((userId, ratings) {
      if (userId != targetUser && ratings.isNotEmpty) {
        final similarity = _calculatePearsonCorrelation(targetRatings, ratings);
        if (similarity > _similarityThreshold) {
          similarities.add(MapEntry(userId, similarity));
        }
      }
    });
    
    // 유사도 순으로 정렬
    similarities.sort((a, b) => b.value.compareTo(a.value));
    
    return similarities.take(k).toList();
  }

  /// Collaborative Filtering 기반 예측 평점 계산
  static double _predictRating(
    String recipeName,
    Map<String, double> targetUserRatings,
    List<MapEntry<String, double>> neighbors,
    Map<String, Map<String, double>> ratingsMatrix,
  ) {
    if (neighbors.isEmpty) return 0.0;
    
    double weightedSum = 0;
    double similaritySum = 0;
    
    for (var neighbor in neighbors) {
      final neighborRatings = ratingsMatrix[neighbor.key];
      if (neighborRatings != null && neighborRatings.containsKey(recipeName)) {
        final neighborMean = neighborRatings.values.reduce((a, b) => a + b) / neighborRatings.length;
        
        weightedSum += neighbor.value * (neighborRatings[recipeName]! - neighborMean);
        similaritySum += neighbor.value.abs();
      }
    }
    
    if (similaritySum == 0) return 0.0;
    
    final targetMean = targetUserRatings.isEmpty 
        ? 3.0 
        : targetUserRatings.values.reduce((a, b) => a + b) / targetUserRatings.length;
    
    return targetMean + (weightedSum / similaritySum);
  }

  /// 조회 기록 저장
  static Future<void> recordView(String recipeName) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_viewHistoryKey);
    
    List<Map<String, dynamic>> history = [];
    if (historyJson != null) {
      history = List<Map<String, dynamic>>.from(json.decode(historyJson));
    }
    
    history.add({
      'recipe': recipeName,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // 최근 100개만 유지
    if (history.length > 100) {
      history = history.sublist(history.length - 100);
    }
    
    await prefs.setString(_viewHistoryKey, json.encode(history));
  }

  /// 요리 기록 저장
  static Future<void> recordCook(String recipeName) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_cookHistoryKey);
    
    List<Map<String, dynamic>> history = [];
    if (historyJson != null) {
      history = List<Map<String, dynamic>>.from(json.decode(historyJson));
    }
    
    history.add({
      'recipe': recipeName,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString(_cookHistoryKey, json.encode(history));
  }

  // ==========================================
  // 레시피 조회 및 추천 메서드
  // ==========================================

  /// 모든 레시피 가져오기
  static Future<List<Recipe>> getAllRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final recipesJson = prefs.getString(_recipesKey);
    
    if (recipesJson == null) {
      final sampleRecipes = _getSampleRecipes();
      await _saveRecipes(sampleRecipes);
      return sampleRecipes;
    }

    final List<dynamic> decoded = json.decode(recipesJson);
    return decoded.map((item) => Recipe.fromJson(item)).toList();
  }

  /// 레시피 추가
  static Future<void> addRecipe(Recipe recipe) async {
    final recipes = await getAllRecipes();
    recipes.add(recipe);
    await _saveRecipes(recipes);
  }

  /// Collaborative Filtering 기반 맞춤 레시피 추천
  static Future<List<Recipe>> getRecommendedRecipes({int limit = 5}) async {
    final allRecipes = await getAllRecipes();
    final ratingsMatrix = await _loadUserRatingsMatrix();
    final currentUserId = 'current_user';
    final userRatings = ratingsMatrix[currentUserId] ?? {};
    
    // CF 적용 가능 여부 확인
    if (userRatings.length >= _minRatingsForCF && ratingsMatrix.length > 1) {
      // Collaborative Filtering 추천
      return _getCollaborativeFilteringRecommendations(
        allRecipes, 
        ratingsMatrix, 
        currentUserId, 
        limit,
      );
    }
    
    // CF 데이터 부족 시 하이브리드 추천 (콘텐츠 기반 + 인기도)
    return _getHybridRecommendations(allRecipes, userRatings, limit);
  }

  /// Collaborative Filtering 추천
  static Future<List<Recipe>> _getCollaborativeFilteringRecommendations(
    List<Recipe> allRecipes,
    Map<String, Map<String, double>> ratingsMatrix,
    String currentUserId,
    int limit,
  ) async {
    final userRatings = ratingsMatrix[currentUserId] ?? {};
    
    // K-최근접 이웃 찾기
    final neighbors = _findKNearestNeighbors(
      currentUserId, 
      ratingsMatrix, 
      _neighborhoodSize,
    );
    
    // 아직 평가하지 않은 레시피에 대한 예측 평점 계산
    final predictions = <MapEntry<Recipe, double>>[];
    
    for (var recipe in allRecipes) {
      if (!userRatings.containsKey(recipe.name)) {
        final predictedRating = _predictRating(
          recipe.name, 
          userRatings, 
          neighbors, 
          ratingsMatrix,
        );
        
        if (predictedRating > 0) {
          predictions.add(MapEntry(recipe, predictedRating));
        }
      }
    }
    
    // 예측 평점 순으로 정렬
    predictions.sort((a, b) => b.value.compareTo(a.value));
    
    if (predictions.isEmpty) {
      // 예측이 없으면 하이브리드 추천으로 폴백
      return _getHybridRecommendations(allRecipes, userRatings, limit);
    }
    
    return predictions.take(limit).map((e) => e.key).toList();
  }

  /// 하이브리드 추천 (콘텐츠 기반 + 영양 목표)
  static Future<List<Recipe>> _getHybridRecommendations(
    List<Recipe> allRecipes,
    Map<String, double> userRatings,
    int limit,
  ) async {
    final userGoals = await MealTrackingService.getUserGoals();
    
    if (userGoals == null) {
      // 목표가 없으면 무작위 추천
      final shuffled = List<Recipe>.from(allRecipes)..shuffle();
      return shuffled.take(limit).toList();
    }

    // 남은 칼로리에 맞는 레시피 찾기
    final today = DateTime.now();
    final todaysMeals = await MealTrackingService.getMealsByDate(today);
    final consumedCalories = todaysMeals.fold<double>(
      0,
      (sum, meal) => sum + meal.totalCalories,
    );
    final remainingCalories = userGoals.dailyCalories - consumedCalories;

    // 점수 계산 (영양 균형 + 선호도)
    final scoredRecipes = <MapEntry<Recipe, double>>[];
    
    for (var recipe in allRecipes) {
      double score = 0;
      
      // 칼로리 적합성 점수
      if (recipe.calories <= remainingCalories && recipe.calories >= remainingCalories * 0.3) {
        score += 3;
      } else if (recipe.calories <= remainingCalories) {
        score += 1;
      }
      
      // 영양 균형 점수
      score += _calculateNutritionScore(recipe, userGoals);
      
      // 사용자 선호도 반영 (높은 평점 레시피와 유사한 특성)
      score += _calculatePreferenceScore(recipe, userRatings, allRecipes);
      
      scoredRecipes.add(MapEntry(recipe, score));
    }
    
    // 점수 순으로 정렬
    scoredRecipes.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredRecipes.take(limit).map((e) => e.key).toList();
  }

  /// 콘텐츠 기반 선호도 점수 계산
  static double _calculatePreferenceScore(
    Recipe recipe,
    Map<String, double> userRatings,
    List<Recipe> allRecipes,
  ) {
    if (userRatings.isEmpty) return 0;
    
    // 높은 평점을 준 레시피들 찾기
    final likedRecipes = allRecipes.where(
      (r) => userRatings.containsKey(r.name) && userRatings[r.name]! >= 4.0
    ).toList();
    
    if (likedRecipes.isEmpty) return 0;
    
    // 태그 유사도 계산
    double tagSimilarity = 0;
    for (var likedRecipe in likedRecipes) {
      final commonTags = recipe.tags.where(
        (tag) => likedRecipe.tags.contains(tag)
      ).length;
      tagSimilarity += commonTags / max(recipe.tags.length, 1);
    }
    
    // 카테고리 유사도
    final categoryMatches = likedRecipes.where(
      (r) => r.category == recipe.category
    ).length;
    
    return (tagSimilarity / likedRecipes.length) + (categoryMatches / likedRecipes.length);
  }

  /// 영양 균형 점수 계산
  static double _calculateNutritionScore(Recipe recipe, UserGoals goals) {
    final proteinRatio = recipe.protein / goals.proteinGoal;
    final carbsRatio = recipe.carbs / goals.carbsGoal;
    final fatRatio = recipe.fat / goals.fatGoal;

    // 목표에 가까울수록 높은 점수
    return (1 - (proteinRatio - 1).abs()) +
        (1 - (carbsRatio - 1).abs()) +
        (1 - (fatRatio - 1).abs());
  }

  /// 카테고리별 레시피
  static Future<List<Recipe>> getRecipesByCategory(String category) async {
    final allRecipes = await getAllRecipes();
    return allRecipes.where((recipe) => recipe.category == category).toList();
  }

  /// 태그로 레시피 검색
  static Future<List<Recipe>> searchByTag(String tag) async {
    final allRecipes = await getAllRecipes();
    return allRecipes.where((recipe) => recipe.tags.contains(tag)).toList();
  }

  /// 칼로리 범위로 레시피 검색
  static Future<List<Recipe>> getRecipesByCalorieRange(
    double minCalories,
    double maxCalories,
  ) async {
    final allRecipes = await getAllRecipes();
    return allRecipes.where((recipe) {
      return recipe.calories >= minCalories && recipe.calories <= maxCalories;
    }).toList();
  }

  /// 조리 시간으로 레시피 필터링
  static Future<List<Recipe>> getQuickRecipes(int maxMinutes) async {
    final allRecipes = await getAllRecipes();
    return allRecipes.where((recipe) {
      return recipe.totalTimeMinutes <= maxMinutes;
    }).toList();
  }

  /// 레시피 검색
  static Future<List<Recipe>> searchRecipes(String query) async {
    final allRecipes = await getAllRecipes();
    final queryLower = query.toLowerCase();
    
    return allRecipes.where((recipe) {
      return recipe.name.toLowerCase().contains(queryLower) ||
          recipe.description.toLowerCase().contains(queryLower) ||
          recipe.ingredients.any((i) => i.toLowerCase().contains(queryLower));
    }).toList();
  }

  /// 인기 레시피 (CF 평점 기반)
  static Future<List<Recipe>> getPopularRecipes({int limit = 10}) async {
    final allRecipes = await getAllRecipes();
    final ratingsMatrix = await _loadUserRatingsMatrix();
    
    // 각 레시피의 평균 평점 계산
    final recipeScores = <String, List<double>>{};
    
    ratingsMatrix.forEach((userId, ratings) {
      ratings.forEach((recipeName, rating) {
        recipeScores[recipeName] ??= [];
        recipeScores[recipeName]!.add(rating);
      });
    });
    
    // 평균 평점으로 정렬
    allRecipes.sort((a, b) {
      final aScores = recipeScores[a.name] ?? [];
      final bScores = recipeScores[b.name] ?? [];
      
      final aAvg = aScores.isEmpty ? 0 : aScores.reduce((x, y) => x + y) / aScores.length;
      final bAvg = bScores.isEmpty ? 0 : bScores.reduce((x, y) => x + y) / bScores.length;
      
      return bAvg.compareTo(aAvg);
    });
    
    return allRecipes.take(limit).toList();
  }

  /// 레시피 저장 (내부 메서드)
  static Future<void> _saveRecipes(List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(recipes.map((r) => r.toJson()).toList());
    await prefs.setString(_recipesKey, encoded);
  }

  /// 유사 레시피 추천 (아이템 기반 CF)
  static Future<List<Recipe>> getSimilarRecipes(Recipe targetRecipe, {int limit = 5}) async {
    final allRecipes = await getAllRecipes();
    final ratingsMatrix = await _loadUserRatingsMatrix();
    
    // 각 레시피의 평점 벡터 생성
    final itemVectors = <String, Map<String, double>>{};
    
    ratingsMatrix.forEach((userId, ratings) {
      ratings.forEach((recipeName, rating) {
        itemVectors[recipeName] ??= {};
        itemVectors[recipeName]![userId] = rating;
      });
    });
    
    // 타겟 레시피와의 유사도 계산
    final targetVector = itemVectors[targetRecipe.name] ?? {};
    final similarities = <MapEntry<Recipe, double>>[];
    
    for (var recipe in allRecipes) {
      if (recipe.name == targetRecipe.name) continue;
      
      final recipeVector = itemVectors[recipe.name] ?? {};
      
      // CF 유사도 + 콘텐츠 유사도 조합
      double similarity = 0;
      
      if (targetVector.isNotEmpty && recipeVector.isNotEmpty) {
        similarity += _calculateCosineSimilarity(targetVector, recipeVector) * 0.6;
      }
      
      // 태그 유사도
      final commonTags = recipe.tags.where((t) => targetRecipe.tags.contains(t)).length;
      similarity += (commonTags / max(targetRecipe.tags.length, 1)) * 0.3;
      
      // 카테고리 유사도
      if (recipe.category == targetRecipe.category) {
        similarity += 0.1;
      }
      
      similarities.add(MapEntry(recipe, similarity));
    }
    
    similarities.sort((a, b) => b.value.compareTo(a.value));
    
    return similarities.take(limit).map((e) => e.key).toList();
  }
}
