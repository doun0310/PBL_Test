import '../models/food_item.dart';

class FoodDatabaseService {
  // 샘플 음식 데이터베이스
  static final List<FoodItem> _foodDatabase = [
    FoodItem(id: 'food_001', name: '배추김치', calories: 18, protein: 1, carbs: 3, fat: 0.2, servingSize: 100, unit: 'g', category: '채소'),
    FoodItem(id: 'food_002', name: '비빔밥', calories: 580, protein: 20, carbs: 85, fat: 15, servingSize: 400, unit: 'g', category: '밥류'),
    FoodItem(id: 'food_003', name: '비빔냉면', calories: 560, protein: 18, carbs: 90, fat: 12, servingSize: 450, unit: 'g', category: '면류'),
    FoodItem(id: 'food_004', name: '보쌈', calories: 600, protein: 35, carbs: 5, fat: 50, servingSize: 200, unit: 'g', category: '육류'),
    FoodItem(id: 'food_005', name: '부추김치', calories: 30, protein: 2, carbs: 5, fat: 0.5, servingSize: 100, unit: 'g', category: '채소'),
    FoodItem(id: 'food_006', name: '불고기', calories: 450, protein: 25, carbs: 30, fat: 25, servingSize: 200, unit: 'g', category: '육류'),
    FoodItem(id: 'food_007', name: '닭갈비', calories: 500, protein: 30, carbs: 20, fat: 30, servingSize: 250, unit: 'g', category: '육류'),
    FoodItem(id: 'food_008', name: '더덕구이', calories: 150, protein: 3, carbs: 30, fat: 2, servingSize: 100, unit: 'g', category: '채소'),
    FoodItem(id: 'food_009', name: '된장찌개', calories: 150, protein: 10, carbs: 12, fat: 6, servingSize: 250, unit: 'ml', category: '국/찌개'),
    FoodItem(id: 'food_010', name: '동그랑땡', calories: 250, protein: 15, carbs: 10, fat: 18, servingSize: 100, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_011', name: '도토리묵', calories: 45, protein: 1, carbs: 10, fat: 0.2, servingSize: 100, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_012', name: '두부조림', calories: 180, protein: 15, carbs: 8, fat: 10, servingSize: 150, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_013', name: '어묵볶음', calories: 200, protein: 10, carbs: 25, fat: 8, servingSize: 100, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_014', name: '갈비구이', calories: 550, protein: 30, carbs: 15, fat: 40, servingSize: 200, unit: 'g', category: '육류'),
    FoodItem(id: 'food_015', name: '갈비찜', calories: 500, protein: 35, carbs: 20, fat: 30, servingSize: 250, unit: 'g', category: '육류'),
    FoodItem(id: 'food_016', name: '갈치구이', calories: 220, protein: 20, carbs: 0, fat: 15, servingSize: 100, unit: 'g', category: '생선'),
    FoodItem(id: 'food_017', name: '간장게장', calories: 150, protein: 20, carbs: 5, fat: 5, servingSize: 200, unit: 'g', category: '해산물'),
    FoodItem(id: 'food_018', name: '갓김치', calories: 25, protein: 2, carbs: 4, fat: 0.4, servingSize: 100, unit: 'g', category: '채소'),
    FoodItem(id: 'food_019', name: '김밥', calories: 450, protein: 12, carbs: 75, fat: 8, servingSize: 300, unit: 'g', category: '밥류'),
    FoodItem(id: 'food_020', name: '김치볶음밥', calories: 500, protein: 15, carbs: 80, fat: 15, servingSize: 300, unit: 'g', category: '밥류'),
    FoodItem(id: 'food_021', name: '김치전', calories: 350, protein: 8, carbs: 40, fat: 18, servingSize: 150, unit: 'g', category: '전/부침'),
    FoodItem(id: 'food_022', name: '김치찌개', calories: 180, protein: 12, carbs: 10, fat: 8, servingSize: 250, unit: 'ml', category: '국/찌개'),
    FoodItem(id: 'food_023', name: '고추장진미채볶음', calories: 280, protein: 25, carbs: 30, fat: 6, servingSize: 100, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_024', name: '고등어구이', calories: 262, protein: 22, carbs: 0, fat: 19, servingSize: 100, unit: 'g', category: '생선'),
    FoodItem(id: 'food_025', name: '곱창구이', calories: 350, protein: 20, carbs: 2, fat: 30, servingSize: 150, unit: 'g', category: '육류'),
    FoodItem(id: 'food_026', name: '계란국', calories: 120, protein: 10, carbs: 5, fat: 6, servingSize: 250, unit: 'ml', category: '국/찌개'),
    FoodItem(id: 'food_027', name: '계란후라이', calories: 90, protein: 6, carbs: 1, fat: 7, servingSize: 50, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_028', name: '계란찜', calories: 130, protein: 12, carbs: 3, fat: 8, servingSize: 150, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_029', name: '계란말이', calories: 180, protein: 15, carbs: 2, fat: 12, servingSize: 100, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_030', name: '훈제오리', calories: 350, protein: 18, carbs: 1, fat: 30, servingSize: 100, unit: 'g', category: '육류'),
    FoodItem(id: 'food_031', name: '잔치국수', calories: 420, protein: 12, carbs: 80, fat: 5, servingSize: 500, unit: 'g', category: '면류'),
    FoodItem(id: 'food_032', name: '장어구이', calories: 300, protein: 25, carbs: 5, fat: 20, servingSize: 150, unit: 'g', category: '생선'),
    FoodItem(id: 'food_033', name: '장조림', calories: 220, protein: 25, carbs: 10, fat: 10, servingSize: 100, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_034', name: '잡채', calories: 300, protein: 8, carbs: 45, fat: 10, servingSize: 150, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_035', name: '잡곡밥', calories: 300, protein: 7, carbs: 65, fat: 2, servingSize: 210, unit: 'g', category: '밥류'),
    FoodItem(id: 'food_036', name: '제육볶음', calories: 550, protein: 30, carbs: 25, fat: 35, servingSize: 250, unit: 'g', category: '육류'),
    FoodItem(id: 'food_037', name: '짜장면', calories: 580, protein: 18, carbs: 95, fat: 12, servingSize: 400, unit: 'g', category: '면류'),
    FoodItem(id: 'food_038', name: '짬뽕', calories: 500, protein: 20, carbs: 70, fat: 18, servingSize: 600, unit: 'g', category: '면류'),
    FoodItem(id: 'food_039', name: '찜닭', calories: 600, protein: 40, carbs: 45, fat: 30, servingSize: 350, unit: 'g', category: '육류'),
    FoodItem(id: 'food_040', name: '조개구이', calories: 150, protein: 20, carbs: 5, fat: 4, servingSize: 200, unit: 'g', category: '해산물'),
    FoodItem(id: 'food_041', name: '족발', calories: 450, protein: 30, carbs: 2, fat: 35, servingSize: 200, unit: 'g', category: '육류'),
    FoodItem(id: 'food_042', name: '칼국수', calories: 450, protein: 15, carbs: 85, fat: 5, servingSize: 550, unit: 'g', category: '면류'),
    FoodItem(id: 'food_043', name: '깻잎장아찌', calories: 40, protein: 2, carbs: 6, fat: 1, servingSize: 50, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_044', name: '깍두기', calories: 20, protein: 1, carbs: 4, fat: 0.2, servingSize: 100, unit: 'g', category: '채소'),
    FoodItem(id: 'food_045', name: '꽈리고추무침', calories: 50, protein: 2, carbs: 8, fat: 1, servingSize: 100, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_046', name: '콩자반', calories: 180, protein: 10, carbs: 25, fat: 5, servingSize: 50, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_047', name: '콩나물국', calories: 80, protein: 6, carbs: 8, fat: 2, servingSize: 300, unit: 'ml', category: '국/찌개'),
    FoodItem(id: 'food_048', name: '콩나물무침', calories: 45, protein: 4, carbs: 5, fat: 1, servingSize: 100, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_049', name: '만두', calories: 350, protein: 15, carbs: 40, fat: 15, servingSize: 150, unit: 'g', category: '기타'),
    FoodItem(id: 'food_050', name: '메추리알장조림', calories: 200, protein: 15, carbs: 10, fat: 12, servingSize: 100, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_051', name: '미역국', calories: 90, protein: 5, carbs: 8, fat: 4, servingSize: 300, unit: 'ml', category: '국/찌개'),
    FoodItem(id: 'food_052', name: '미역줄기볶음', calories: 60, protein: 2, carbs: 10, fat: 2, servingSize: 100, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_053', name: '무국', calories: 70, protein: 4, carbs: 10, fat: 1, servingSize: 300, unit: 'ml', category: '국/찌개'),
    FoodItem(id: 'food_054', name: '물냉면', calories: 480, protein: 15, carbs: 95, fat: 5, servingSize: 500, unit: 'g', category: '면류'),
    FoodItem(id: 'food_055', name: '무생채', calories: 30, protein: 1, carbs: 6, fat: 0.5, servingSize: 100, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_056', name: '멸치볶음', calories: 250, protein: 20, carbs: 15, fat: 12, servingSize: 50, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_057', name: '파전', calories: 400, protein: 15, carbs: 45, fat: 20, servingSize: 200, unit: 'g', category: '전/부침'),
    FoodItem(id: 'food_058', name: '라면', calories: 510, protein: 10, carbs: 80, fat: 16, servingSize: 120, unit: 'g', category: '면류'),
    FoodItem(id: 'food_059', name: '삼겹살', calories: 518, protein: 17, carbs: 0, fat: 50, servingSize: 100, unit: 'g', category: '육류'),
    FoodItem(id: 'food_060', name: '시금치나물', calories: 35, protein: 3, carbs: 4, fat: 1, servingSize: 100, unit: 'g', category: '채소'),
    FoodItem(id: 'food_061', name: '소세지볶음', calories: 300, protein: 12, carbs: 15, fat: 22, servingSize: 100, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_062', name: '떡볶이', calories: 480, protein: 10, carbs: 90, fat: 8, servingSize: 250, unit: 'g', category: '분식'),
    FoodItem(id: 'food_063', name: '떡갈비', calories: 350, protein: 20, carbs: 25, fat: 20, servingSize: 150, unit: 'g', category: '육류'),
    FoodItem(id: 'food_064', name: '떡국_만두국', calories: 550, protein: 20, carbs: 80, fat: 15, servingSize: 500, unit: 'g', category: '국/찌개'),
    FoodItem(id: 'food_065', name: '우엉조림', calories: 150, protein: 3, carbs: 30, fat: 2, servingSize: 100, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_066', name: '양념치킨', calories: 350, protein: 20, carbs: 30, fat: 18, servingSize: 100, unit: 'g', category: '육류'),
    FoodItem(id: 'food_067', name: '연근조림', calories: 160, protein: 2, carbs: 35, fat: 1, servingSize: 100, unit: 'g', category: '반찬'),
    FoodItem(id: 'food_068', name: '유부초밥', calories: 60, protein: 2, carbs: 10, fat: 1.5, servingSize: 30, unit: 'g', category: '밥류'),
    FoodItem(id: 'food_069', name: '육개장', calories: 450, protein: 25, carbs: 15, fat: 30, servingSize: 400, unit: 'g', category: '국/찌개'),
    FoodItem(id: 'food_070', name: '후라이드치킨', calories: 320, protein: 22, carbs: 15, fat: 20, servingSize: 100, unit: 'g', category: '육류'),
    FoodItem(id: 'food_071', name: '피자', calories: 280, protein: 12, carbs: 35, fat: 10, servingSize: 100, unit: 'g', category: '기타'),
  ];

  // 모든 음식 가져오기
  static List<FoodItem> getAllFoods() {
    return _foodDatabase;
  }

  // 음식 검색
  static List<FoodItem> searchFoods(String query) {
    if (query.isEmpty) {
      return _foodDatabase;
    }

    return _foodDatabase.where((food) {
      return food.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // 카테고리별 음식 가져오기
  static List<FoodItem> getFoodsByCategory(String category) {
    return _foodDatabase.where((food) => food.category == category).toList();
  }

  // ID로 음식 찾기
  static FoodItem? getFoodById(String id) {
    try {
      return _foodDatabase.firstWhere((food) => food.id == id);
    } catch (e) {
      return null;
    }
  }

  // 음식 추가 (사용자 정의 음식)
  static void addFood(FoodItem food) {
    _foodDatabase.add(food);
  }

  // 모든 카테고리 가져오기
  static List<String> getAllCategories() {
    return _foodDatabase
        .map((food) => food.category ?? '기타')
        .toSet()
        .toList();
  }
}
