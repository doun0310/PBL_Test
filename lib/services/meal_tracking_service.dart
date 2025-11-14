import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_entry.dart';
import '../models/user_goals.dart';

class MealTrackingService {
  static const String _mealsKey = 'meals_data';
  static const String _goalsKey = 'user_goals';

  // 모든 식사 기록 가져오기
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
    final allMeals = await getAllMeals();
    return allMeals.where((meal) {
      return meal.timestamp.year == date.year &&
          meal.timestamp.month == date.month &&
          meal.timestamp.day == date.day;
    }).toList();
  }

  // 식사 기록 추가
  static Future<void> addMeal(MealEntry meal) async {
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
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getString(_goalsKey);
    
    if (goalsJson == null) {
      return UserGoals();
    }

    return UserGoals.fromJson(json.decode(goalsJson));
  }

  // 사용자 목표 저장
  static Future<void> saveUserGoals(UserGoals goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalsKey, json.encode(goals.toJson()));
  }

  // 주간 영양 데이터 가져오기 (7일)
  static Future<List<DailyNutrition>> getWeeklyNutrition(DateTime endDate) async {
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
}
