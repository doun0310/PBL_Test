import '../models/food_item.dart';
import 'backend_api_service.dart';

class FoodDatabaseService {
  // 캐시된 음식 데이터
  static List<FoodItem>? _cachedFoods;
  static List<String>? _cachedCategories;
  
  // 백엔드 사용 여부
  static bool _useBackend = true;
  
  // 샘플 음식 데이터베이스 (오프라인 폴백용)
  static final List<FoodItem> _fallbackDatabase = [
    // 밥류
    FoodItem(
      id: 'food_001',
      name: '흰쌀밥',
      calories: 310,
      protein: 6,
      carbs: 68,
      fat: 0.5,
      servingSize: 210,
      unit: 'g',
      category: '밥류',
    ),
    FoodItem(
      id: 'food_002',
      name: '현미밥',
      calories: 280,
      protein: 6,
      carbs: 60,
      fat: 2,
      servingSize: 210,
      unit: 'g',
      category: '밥류',
    ),
    FoodItem(
      id: 'food_003',
      name: '김밥',
      calories: 450,
      protein: 12,
      carbs: 75,
      fat: 8,
      servingSize: 300,
      unit: 'g',
      category: '밥류',
    ),
    FoodItem(
      id: 'food_004',
      name: '비빔밥',
      calories: 550,
      protein: 18,
      carbs: 78,
      fat: 15,
      servingSize: 400,
      unit: 'g',
      category: '밥류',
    ),
    
    // 국/찌개류
    FoodItem(
      id: 'food_005',
      name: '된장찌개',
      calories: 150,
      protein: 10,
      carbs: 12,
      fat: 6,
      servingSize: 250,
      unit: 'ml',
      category: '국/찌개',
    ),
    FoodItem(
      id: 'food_006',
      name: '김치찌개',
      calories: 180,
      protein: 12,
      carbs: 10,
      fat: 8,
      servingSize: 250,
      unit: 'ml',
      category: '국/찌개',
    ),
    FoodItem(
      id: 'food_007',
      name: '순두부찌개',
      calories: 200,
      protein: 14,
      carbs: 8,
      fat: 12,
      servingSize: 300,
      unit: 'ml',
      category: '국/찌개',
    ),
    FoodItem(
      id: 'food_008',
      name: '미역국',
      calories: 80,
      protein: 5,
      carbs: 8,
      fat: 3,
      servingSize: 250,
      unit: 'ml',
      category: '국/찌개',
    ),
    
    // 육류
    FoodItem(
      id: 'food_009',
      name: '닭가슴살',
      calories: 165,
      protein: 31,
      carbs: 0,
      fat: 3.6,
      servingSize: 100,
      unit: 'g',
      category: '육류',
    ),
    FoodItem(
      id: 'food_010',
      name: '삼겹살',
      calories: 518,
      protein: 17,
      carbs: 0,
      fat: 50,
      servingSize: 100,
      unit: 'g',
      category: '육류',
    ),
    FoodItem(
      id: 'food_011',
      name: '소고기(등심)',
      calories: 250,
      protein: 20,
      carbs: 0,
      fat: 18,
      servingSize: 100,
      unit: 'g',
      category: '육류',
    ),
    FoodItem(
      id: 'food_012',
      name: '불고기',
      calories: 250,
      protein: 20,
      carbs: 10,
      fat: 15,
      servingSize: 150,
      unit: 'g',
      category: '육류',
    ),
    FoodItem(
      id: 'food_013',
      name: '제육볶음',
      calories: 280,
      protein: 22,
      carbs: 12,
      fat: 18,
      servingSize: 150,
      unit: 'g',
      category: '육류',
    ),
    
    // 생선
    FoodItem(
      id: 'food_014',
      name: '고등어구이',
      calories: 262,
      protein: 22,
      carbs: 0,
      fat: 19,
      servingSize: 100,
      unit: 'g',
      category: '생선',
    ),
    FoodItem(
      id: 'food_015',
      name: '연어',
      calories: 208,
      protein: 20,
      carbs: 0,
      fat: 13,
      servingSize: 100,
      unit: 'g',
      category: '생선',
    ),
    
    // 반찬류
    FoodItem(
      id: 'food_016',
      name: '시금치나물',
      calories: 35,
      protein: 3,
      carbs: 4,
      fat: 1,
      servingSize: 100,
      unit: 'g',
      category: '반찬',
    ),
    FoodItem(
      id: 'food_017',
      name: '배추김치',
      calories: 18,
      protein: 1,
      carbs: 3,
      fat: 0.2,
      servingSize: 100,
      unit: 'g',
      category: '반찬',
    ),
    FoodItem(
      id: 'food_018',
      name: '계란찜',
      calories: 120,
      protein: 10,
      carbs: 2,
      fat: 8,
      servingSize: 100,
      unit: 'g',
      category: '반찬',
    ),
    
    // 면류
    FoodItem(
      id: 'food_019',
      name: '라면',
      calories: 510,
      protein: 10,
      carbs: 80,
      fat: 16,
      servingSize: 120,
      unit: 'g',
      category: '면류',
    ),
    FoodItem(
      id: 'food_020',
      name: '짜장면',
      calories: 580,
      protein: 18,
      carbs: 95,
      fat: 12,
      servingSize: 400,
      unit: 'g',
      category: '면류',
    ),
    FoodItem(
      id: 'food_021',
      name: '칼국수',
      calories: 400,
      protein: 12,
      carbs: 70,
      fat: 8,
      servingSize: 400,
      unit: 'g',
      category: '면류',
    ),
    
    // 분식류
    FoodItem(
      id: 'food_022',
      name: '떡볶이',
      calories: 380,
      protein: 8,
      carbs: 70,
      fat: 8,
      servingSize: 300,
      unit: 'g',
      category: '분식',
    ),
    FoodItem(
      id: 'food_023',
      name: '순대',
      calories: 250,
      protein: 15,
      carbs: 20,
      fat: 12,
      servingSize: 150,
      unit: 'g',
      category: '분식',
    ),
    
    // 빵/과자
    FoodItem(
      id: 'food_024',
      name: '식빵',
      calories: 270,
      protein: 8,
      carbs: 50,
      fat: 4,
      servingSize: 100,
      unit: 'g',
      category: '빵/과자',
    ),
    FoodItem(
      id: 'food_025',
      name: '크로와상',
      calories: 406,
      protein: 8,
      carbs: 46,
      fat: 21,
      servingSize: 100,
      unit: 'g',
      category: '빵/과자',
    ),
    
    // 음료
    FoodItem(
      id: 'food_026',
      name: '아메리카노',
      calories: 5,
      protein: 0.3,
      carbs: 1,
      fat: 0,
      servingSize: 240,
      unit: 'ml',
      category: '음료',
    ),
    FoodItem(
      id: 'food_027',
      name: '카페라떼',
      calories: 150,
      protein: 8,
      carbs: 15,
      fat: 6,
      servingSize: 240,
      unit: 'ml',
      category: '음료',
    ),
    FoodItem(
      id: 'food_028',
      name: '콜라',
      calories: 42,
      protein: 0,
      carbs: 10.6,
      fat: 0,
      servingSize: 100,
      unit: 'ml',
      category: '음료',
    ),
    
    // 과일
    FoodItem(
      id: 'food_029',
      name: '사과',
      calories: 52,
      protein: 0.3,
      carbs: 14,
      fat: 0.2,
      servingSize: 100,
      unit: 'g',
      category: '과일',
    ),
    FoodItem(
      id: 'food_030',
      name: '바나나',
      calories: 89,
      protein: 1.1,
      carbs: 23,
      fat: 0.3,
      servingSize: 100,
      unit: 'g',
      category: '과일',
    ),
  ];

  /// 서버 연결 확인 및 초기화
  static Future<void> initialize() async {
    _useBackend = await BackendApiService.healthCheck();
    if (_useBackend) {
      _cachedFoods = await BackendApiService.getAllFoods();
      _cachedCategories = await BackendApiService.getCategories();
    }
  }

  /// 모든 음식 가져오기
  static List<FoodItem> getAllFoods() {
    if (_cachedFoods != null && _cachedFoods!.isNotEmpty) {
      return _cachedFoods!;
    }
    return _fallbackDatabase;
  }

  /// 모든 음식 가져오기 (비동기)
  static Future<List<FoodItem>> getAllFoodsAsync() async {
    if (_useBackend) {
      final foods = await BackendApiService.getAllFoods();
      if (foods.isNotEmpty) {
        _cachedFoods = foods;
        return foods;
      }
    }
    return _fallbackDatabase;
  }

  /// 음식 검색
  static List<FoodItem> searchFoods(String query) {
    final allFoods = getAllFoods();
    
    if (query.isEmpty) {
      return allFoods;
    }
    
    return allFoods.where((food) {
      return food.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// 음식 검색 (비동기 - 백엔드 사용)
  static Future<List<FoodItem>> searchFoodsAsync(String query, {String? category}) async {
    if (_useBackend) {
      final foods = await BackendApiService.searchFoods(query, category: category);
      if (foods.isNotEmpty) {
        return foods;
      }
    }
    return searchFoods(query);
  }

  /// 카테고리별 음식 가져오기
  static List<FoodItem> getFoodsByCategory(String category) {
    return getAllFoods().where((food) => food.category == category).toList();
  }

  /// ID로 음식 찾기
  static FoodItem? getFoodById(String id) {
    try {
      return getAllFoods().firstWhere((food) => food.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 음식 추가 (사용자 정의 음식)
  static void addFood(FoodItem food) {
    if (_cachedFoods != null) {
      _cachedFoods!.add(food);
    } else {
      _fallbackDatabase.add(food);
    }
  }

  /// 모든 카테고리 가져오기
  static List<String> getAllCategories() {
    if (_cachedCategories != null && _cachedCategories!.isNotEmpty) {
      return _cachedCategories!;
    }
    return getAllFoods()
        .map((food) => food.category ?? '기타')
        .toSet()
        .toList();
  }

  /// 모든 카테고리 가져오기 (비동기)
  static Future<List<String>> getAllCategoriesAsync() async {
    if (_useBackend) {
      final categories = await BackendApiService.getCategories();
      if (categories.isNotEmpty) {
        _cachedCategories = categories;
        return categories;
      }
    }
    return getAllCategories();
  }

  /// 캐시 초기화
  static void clearCache() {
    _cachedFoods = null;
    _cachedCategories = null;
  }
}
