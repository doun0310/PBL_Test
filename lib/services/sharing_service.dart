import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/meal_entry.dart';

class SharingService {
  // 식사 정보 공유
  static Future<void> shareMeal(MealEntry meal) async {
    final text = _formatMealText(meal);
    await Share.share(text, subject: '내 식사 기록');
  }

  // 식사 텍스트 포맷팅
  static String _formatMealText(MealEntry meal) {
    final buffer = StringBuffer();
    buffer.writeln('🍽️ ${meal.mealType.displayName} 식사 기록');
    buffer.writeln('');
    buffer.writeln('📅 ${_formatDate(meal.timestamp)}');
    buffer.writeln('');
    buffer.writeln('🥘 음식 목록:');
    
    for (var foodEntry in meal.foodItems) {
      buffer.writeln('• ${foodEntry.foodItem.name} (${foodEntry.servingSize.toStringAsFixed(0)}g)');
    }
    
    buffer.writeln('');
    buffer.writeln('📊 영양 정보:');
    buffer.writeln('• 칼로리: ${meal.totalCalories.toStringAsFixed(0)} kcal');
    buffer.writeln('• 단백질: ${meal.totalProtein.toStringAsFixed(1)}g');
    buffer.writeln('• 탄수화물: ${meal.totalCarbs.toStringAsFixed(1)}g');
    buffer.writeln('• 지방: ${meal.totalFat.toStringAsFixed(1)}g');
    
    if (meal.notes != null && meal.notes!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('📝 메모: ${meal.notes}');
    }
    
    buffer.writeln('');
    buffer.writeln('영양소 추적기 앱으로 기록했습니다 💚');
    
    return buffer.toString();
  }

  // 날짜 포맷팅
  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '오늘 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '어제 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  // 일일 요약 공유
  static Future<void> shareDailySummary(
    List<MealEntry> meals,
    double totalCalories,
    double totalProtein,
    double totalCarbs,
    double totalFat,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('📊 오늘의 식단 요약');
    buffer.writeln('');
    buffer.writeln('🍽️ 총 ${meals.length}끼 식사');
    buffer.writeln('');
    buffer.writeln('📈 영양소 섭취:');
    buffer.writeln('• 칼로리: ${totalCalories.toStringAsFixed(0)} kcal');
    buffer.writeln('• 단백질: ${totalProtein.toStringAsFixed(1)}g');
    buffer.writeln('• 탄수화물: ${totalCarbs.toStringAsFixed(1)}g');
    buffer.writeln('• 지방: ${totalFat.toStringAsFixed(1)}g');
    buffer.writeln('');
    
    final mealTypes = ['아침', '점심', '저녁', '간식'];
    for (var type in mealTypes) {
      final typeMeals = meals.where((m) => m.mealType == type).toList();
      if (typeMeals.isNotEmpty) {
        final typeCalories = typeMeals.fold<double>(
          0,
          (sum, m) => sum + m.totalCalories,
        );
        buffer.writeln('$type: ${typeCalories.toStringAsFixed(0)} kcal');
      }
    }
    
    buffer.writeln('');
    buffer.writeln('영양소 추적기 앱 💚');
    
    await Share.share(buffer.toString(), subject: '오늘의 식단 요약');
  }

  // 주간 통계 공유
  static Future<void> shareWeeklySummary(
    int totalMeals,
    double avgCalories,
    double totalExerciseCalories,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('📊 이번 주 건강 기록');
    buffer.writeln('');
    buffer.writeln('🍽️ 총 식사: $totalMeals끼');
    buffer.writeln('📈 평균 칼로리: ${avgCalories.toStringAsFixed(0)} kcal/일');
    
    if (totalExerciseCalories > 0) {
      buffer.writeln('🏃 운동으로 소모한 칼로리: ${totalExerciseCalories.toStringAsFixed(0)} kcal');
    }
    
    buffer.writeln('');
    buffer.writeln('영양소 추적기 앱으로 꾸준히 관리중! 💪');
    
    await Share.share(buffer.toString(), subject: '이번 주 건강 기록');
  }

  // 이미지와 함께 공유
  static Future<void> shareMealWithImage(MealEntry meal, String imagePath) async {
    final text = _formatMealText(meal);
    
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: text,
          subject: '내 식사 기록',
        );
      } else {
        // 이미지가 없으면 텍스트만 공유
        await Share.share(text, subject: '내 식사 기록');
      }
    } catch (e) {
      // 에러 시 텍스트만 공유
      await Share.share(text, subject: '내 식사 기록');
    }
  }

  // 운동 기록 공유
  static Future<void> shareExercise(
    String exerciseType,
    int durationMinutes,
    double caloriesBurned,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('🏃 운동 기록');
    buffer.writeln('');
    buffer.writeln('운동: $exerciseType');
    buffer.writeln('시간: $durationMinutes분');
    buffer.writeln('소모 칼로리: ${caloriesBurned.toStringAsFixed(0)} kcal');
    buffer.writeln('');
    buffer.writeln('영양소 추적기 앱 💪');
    
    await Share.share(buffer.toString(), subject: '운동 기록');
  }

  // 목표 달성 공유
  static Future<void> shareGoalAchievement(
    String achievementType,
    String description,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('🎉 목표 달성!');
    buffer.writeln('');
    buffer.writeln('$achievementType');
    buffer.writeln(description);
    buffer.writeln('');
    buffer.writeln('영양소 추적기 앱으로 건강 관리 중! 💚');
    
    await Share.share(buffer.toString(), subject: '목표 달성');
  }

  // 레시피 공유
  static Future<void> shareRecipe(
    String recipeName,
    List<String> ingredients,
    int calories,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('🍳 레시피: $recipeName');
    buffer.writeln('');
    buffer.writeln('📝 재료:');
    
    for (var ingredient in ingredients) {
      buffer.writeln('• $ingredient');
    }
    
    buffer.writeln('');
    buffer.writeln('📊 칼로리: $calories kcal');
    buffer.writeln('');
    buffer.writeln('영양소 추적기 앱 💚');
    
    await Share.share(buffer.toString(), subject: '레시피 공유');
  }

  // 커뮤니티 게시물 공유
  static Future<void> shareCommunityPost(
    String title,
    String content,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('💬 커뮤니티 게시물');
    buffer.writeln('');
    buffer.writeln(title);
    buffer.writeln('');
    buffer.writeln(content);
    buffer.writeln('');
    buffer.writeln('영양소 추적기 커뮤니티 💚');
    
    await Share.share(buffer.toString(), subject: title);
  }
}
