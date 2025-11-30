import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_entry.dart';
import '../models/user_goals.dart';
import 'backend_api_service.dart';

class MealTrackingService {
  static const String _mealsKey = 'meals_data';
  static const String _goalsKey = 'user_goals';
  
  // 백엔드 사용 여부
  static bool _useBackend = true;

  /// 초기화 - 백엔드 연결 확인
  static Future<void> initialize() async {
    _useBackend = await BackendApiService.healthCheck();
  }

  // 모든 식사 기록 가져오기 (로컬)
  static Future<List<MealEntry>> getAllMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final mealsJson = prefs.getString(_mealsKey);
    
    if (mealsJson == null) {
      return [];
    }

    final List<dynamic> decoded = json.decode(mealsJson);
    return decoded.map((item) => MealEntry.fromJson(item)).toList();
  }

  // 특정 날짜의 식사 기록 가져오기
  static Future<List<MealEntry>> getMealsByDate(DateTime date) async {
    // 백엔드 사용 시도
    if (_useBackend) {
      try {
        final meals = await BackendApiService.getDietByDate(date);
        if (meals.isNotEmpty) {
          return meals;
        }
      } catch (e) {
        // 백엔드 실패 시 로컬 폴백
      }
    }

    // 로컬 폴백
    final allMeals = await getAllMeals();
    return allMeals.where((meal) {
      return meal.timestamp.year == date.year &&
          meal.timestamp.month == date.month &&
          meal.timestamp.day == date.day;
    }).toList();
  }

  // 식사 기록 추가
  static Future<void> addMeal(MealEntry meal) async {
    // 백엔드 저장 시도
    if (_useBackend) {
      try {
        final success = await BackendApiService.addDiet(meal);
        if (success) {
          // 로컬에도 저장 (캐시)
          final meals = await getAllMeals();
          meals.add(meal);
          await _saveMeals(meals);
          return;
        }
      } catch (e) {
        // 백엔드 실패 시 로컬에만 저장
      }
    }

    // 로컬 저장
    final meals = await getAllMeals();
    meals.add(meal);
    await _saveMeals(meals);
  }

  // 식사 기록 업데이트
  static Future<void> updateMeal(MealEntry meal) async {
    final meals = await getAllMeals();
    final index = meals.indexWhere((m) => m.id == meal.id);
    if (index != -1) {
      meals[index] = meal;
      await _saveMeals(meals);
    }
  }

  // 식사 기록 삭제
  static Future<void> deleteMeal(String mealId) async {
    // 백엔드 삭제 시도
    if (_useBackend) {
      try {
        await BackendApiService.deleteDiet(mealId);
      } catch (e) {
        // 백엔드 실패해도 로컬에서 삭제
      }
    }

    // 로컬 삭제
    final meals = await getAllMeals();
    meals.removeWhere((m) => m.id == mealId);
    await _saveMeals(meals);
  }

  // 식사 기록 저장
  static Future<void> _saveMeals(List<MealEntry> meals) async {
    final prefs = await SharedPreferences.getInstance();
    final mealsJson = json.encode(meals.map((m) => m.toJson()).toList());
    await prefs.setString(_mealsKey, mealsJson);
  }

  // 특정 날짜의 총 영양 정보 계산
  static Future<DailyNutrition> getDailyNutrition(DateTime date) async {
    // 백엔드 사용 시도
    if (_useBackend) {
      try {
        final nutrition = await BackendApiService.getDailyNutrition(date);
        if (nutrition.calories > 0 || nutrition.protein > 0 || 
            nutrition.carbs > 0 || nutrition.fat > 0) {
          return nutrition;
        }
      } catch (e) {
        // 백엔드 실패 시 로컬 계산
      }
    }

    // 로컬 계산
    final meals = await getMealsByDate(date);
    
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var meal in meals) {
      totalCalories += meal.totalCalories;
      totalProtein += meal.totalProtein;
      totalCarbs += meal.totalCarbs;
      totalFat += meal.totalFat;
    }

    return DailyNutrition(
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
    );
  }

  // 사용자 목표 가져오기
  static Future<UserGoals> getUserGoals() async {
    // 백엔드 사용 시도
    if (_useBackend) {
      try {
        return await BackendApiService.getGoals();
      } catch (e) {
        // 백엔드 실패 시 로컬 폴백
      }
    }

    // 로컬 폴백
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getString(_goalsKey);
    
    if (goalsJson == null) {
      return UserGoals();
    }

    return UserGoals.fromJson(json.decode(goalsJson));
  }

  // 사용자 목표 저장
  static Future<void> saveUserGoals(UserGoals goals) async {
    // 백엔드 저장 시도
    if (_useBackend) {
      try {
        await BackendApiService.updateGoals(goals);
      } catch (e) {
        // 백엔드 실패해도 로컬에 저장
      }
    }

    // 로컬 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalsKey, json.encode(goals.toJson()));
  }

  // 주간 영양 데이터 가져오기 (7일)
  static Future<List<DailyNutrition>> getWeeklyNutrition(DateTime endDate) async {
    // 백엔드 사용 시도
    if (_useBackend) {
      try {
        final weeklyData = await BackendApiService.getWeeklyNutrition();
        if (weeklyData.isNotEmpty) {
          return weeklyData.map((data) => DailyNutrition(
            calories: (data['calories'] as num?)?.toDouble() ?? 0,
            protein: (data['protein'] as num?)?.toDouble() ?? 0,
            carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
            fat: (data['fat'] as num?)?.toDouble() ?? 0,
          )).toList();
        }
      } catch (e) {
        // 백엔드 실패 시 로컬 계산
      }
    }

    // 로컬 계산
    List<DailyNutrition> weeklyData = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = endDate.subtract(Duration(days: i));
      final nutrition = await getDailyNutrition(date);
      weeklyData.add(nutrition);
    }
    
    return weeklyData;
  }

  // 월간 영양 데이터 가져오기 (30일)
  static Future<List<DailyNutrition>> getMonthlyNutrition(DateTime endDate) async {
    // 백엔드 사용 시도
    if (_useBackend) {
      try {
        final monthlyData = await BackendApiService.getMonthlyNutrition();
        if (monthlyData.isNotEmpty) {
          return monthlyData.map((data) => DailyNutrition(
            calories: (data['calories'] as num?)?.toDouble() ?? 0,
            protein: (data['protein'] as num?)?.toDouble() ?? 0,
            carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
            fat: (data['fat'] as num?)?.toDouble() ?? 0,
          )).toList();
        }
      } catch (e) {
        // 백엔드 실패 시 로컬 계산
      }
    }

    // 로컬 계산
    List<DailyNutrition> monthlyData = [];
    
    for (int i = 29; i >= 0; i--) {
      final date = endDate.subtract(Duration(days: i));
      final nutrition = await getDailyNutrition(date);
      monthlyData.add(nutrition);
    }
    
    return monthlyData;
  }

  // 가장 자주 먹은 음식 랭킹 (주간/월간)
  static Future<List<Map<String, dynamic>>> getFoodRanking(
    DateTime startDate, 
    DateTime endDate,
  ) async {
    // 백엔드 사용 시도
    final days = endDate.difference(startDate).inDays;
    final period = days > 14 ? 'month' : 'week';
    
    if (_useBackend) {
      try {
        return await BackendApiService.getFoodRanking(period: period);
      } catch (e) {
        // 백엔드 실패 시 로컬 계산
      }
    }

    // 로컬 계산
    final allMeals = await getAllMeals();
    final filteredMeals = allMeals.where((meal) {
      return meal.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
          meal.timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    Map<String, int> foodCount = {};
    Map<String, double> foodCalories = {};

    for (var meal in filteredMeals) {
      for (var foodEntry in meal.foodItems) {
        final foodName = foodEntry.foodItem.name;
        foodCount[foodName] = (foodCount[foodName] ?? 0) + 1;
        foodCalories[foodName] = foodEntry.foodItem.calories;
      }
    }

    List<Map<String, dynamic>> ranking = foodCount.entries.map((entry) {
      return {
        'name': entry.key,
        'count': entry.value,
        'calories': foodCalories[entry.key] ?? 0,
      };
    }).toList();

    ranking.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return ranking.take(10).toList();
  }

  // 음식 추천 가져오기
  static Future<Map<String, dynamic>> getRecommendations({
    required double remainingCalories,
    int remainingMeals = 1,
  }) async {
    if (_useBackend) {
      try {
        return await BackendApiService.getRecommendations(
          remainingCalories: remainingCalories,
          remainingMeals: remainingMeals,
        );
      } catch (e) {
        // 백엔드 실패 시 빈 결과
      }
    }
    return {'singleFoods': [], 'combinations': []};
  }
}
