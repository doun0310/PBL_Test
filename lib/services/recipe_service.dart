import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../models/user_goals.dart';
import 'meal_tracking_service.dart';

class RecipeService {
  static const String _recipesKey = 'recipes_data';

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

  // 모든 레시피 가져오기
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

  // 레시피 추가
  static Future<void> addRecipe(Recipe recipe) async {
    final recipes = await getAllRecipes();
    recipes.add(recipe);
    await _saveRecipes(recipes);
  }

  // 사용자 맞춤 레시피 추천
  static Future<List<Recipe>> getRecommendedRecipes({int limit = 5}) async {
    final allRecipes = await getAllRecipes();
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

    // 남은 칼로리의 70~100% 범위의 레시피
    final suitableRecipes = allRecipes.where((recipe) {
      return recipe.calories >= remainingCalories * 0.3 &&
          recipe.calories <= remainingCalories;
    }).toList();

    if (suitableRecipes.isEmpty) {
      // 적합한 레시피가 없으면 저칼로리 레시피 추천
      allRecipes.sort((a, b) => a.calories.compareTo(b.calories));
      return allRecipes.take(limit).toList();
    }

    // 영양 균형 고려하여 정렬
    suitableRecipes.sort((a, b) {
      final aScore = _calculateNutritionScore(a, userGoals);
      final bScore = _calculateNutritionScore(b, userGoals);
      return bScore.compareTo(aScore);
    });

    return suitableRecipes.take(limit).toList();
  }

  // 영양 균형 점수 계산
  static double _calculateNutritionScore(Recipe recipe, UserGoals goals) {
    final proteinRatio = recipe.protein / goals.proteinGoal;
    final carbsRatio = recipe.carbs / goals.carbsGoal;
    final fatRatio = recipe.fat / goals.fatGoal;

    // 목표에 가까울수록 높은 점수
    return (1 - (proteinRatio - 1).abs()) +
        (1 - (carbsRatio - 1).abs()) +
        (1 - (fatRatio - 1).abs());
  }

  // 카테고리별 레시피
  static Future<List<Recipe>> getRecipesByCategory(String category) async {
    final allRecipes = await getAllRecipes();
    return allRecipes.where((recipe) => recipe.category == category).toList();
  }

  // 태그로 레시피 검색
  static Future<List<Recipe>> searchByTag(String tag) async {
    final allRecipes = await getAllRecipes();
    return allRecipes.where((recipe) => recipe.tags.contains(tag)).toList();
  }

  // 칼로리 범위로 레시피 검색
  static Future<List<Recipe>> getRecipesByCalorieRange(
    double minCalories,
    double maxCalories,
  ) async {
    final allRecipes = await getAllRecipes();
    return allRecipes.where((recipe) {
      return recipe.calories >= minCalories && recipe.calories <= maxCalories;
    }).toList();
  }

  // 조리 시간으로 레시피 필터링
  static Future<List<Recipe>> getQuickRecipes(int maxMinutes) async {
    final allRecipes = await getAllRecipes();
    return allRecipes.where((recipe) {
      return recipe.totalTimeMinutes <= maxMinutes;
    }).toList();
  }

  // 레시피 검색
  static Future<List<Recipe>> searchRecipes(String query) async {
    final allRecipes = await getAllRecipes();
    final queryLower = query.toLowerCase();
    
    return allRecipes.where((recipe) {
      return recipe.name.toLowerCase().contains(queryLower) ||
          recipe.description.toLowerCase().contains(queryLower) ||
          recipe.ingredients.any((i) => i.toLowerCase().contains(queryLower));
    }).toList();
  }

  // 인기 레시피 (칼로리가 낮은 순)
  static Future<List<Recipe>> getPopularRecipes({int limit = 10}) async {
    final allRecipes = await getAllRecipes();
    allRecipes.sort((a, b) => a.calories.compareTo(b.calories));
    return allRecipes.take(limit).toList();
  }

  // 레시피 저장 (내부 메서드)
  static Future<void> _saveRecipes(List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(recipes.map((r) => r.toJson()).toList());
    await prefs.setString(_recipesKey, encoded);
  }
}
