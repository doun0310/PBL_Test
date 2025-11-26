import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_entry.dart';

class ExerciseTrackingService {
  static const String _exercisesKey = 'exercises_data';

  // 모든 운동 기록 가져오기
  static Future<List<ExerciseEntry>> getAllExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final exercisesJson = prefs.getString(_exercisesKey);
    
    if (exercisesJson == null) {
      return [];
    }

    final List<dynamic> decoded = json.decode(exercisesJson);
    return decoded.map((item) => ExerciseEntry.fromJson(item)).toList();
  }

  // 특정 날짜의 운동 기록 가져오기
  static Future<List<ExerciseEntry>> getExercisesByDate(DateTime date) async {
    final allExercises = await getAllExercises();
    return allExercises.where((exercise) {
      return exercise.timestamp.year == date.year &&
          exercise.timestamp.month == date.month &&
          exercise.timestamp.day == date.day;
    }).toList();
  }

  // 운동 기록 추가
  static Future<void> addExercise(ExerciseEntry exercise) async {
    final exercises = await getAllExercises();
    exercises.add(exercise);
    await _saveExercises(exercises);
  }

  // 운동 기록 업데이트
  static Future<void> updateExercise(ExerciseEntry exercise) async {
    final exercises = await getAllExercises();
    final index = exercises.indexWhere((e) => e.id == exercise.id);
    if (index != -1) {
      exercises[index] = exercise;
      await _saveExercises(exercises);
    }
  }

  // 운동 기록 삭제
  static Future<void> deleteExercise(String id) async {
    final exercises = await getAllExercises();
    exercises.removeWhere((e) => e.id == id);
    await _saveExercises(exercises);
  }

  // 특정 기간의 총 소모 칼로리 계산
  static Future<double> getTotalCaloriesBurned(DateTime startDate, DateTime endDate) async {
    final allExercises = await getAllExercises();
    final filteredExercises = allExercises.where((exercise) {
      return exercise.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
          exercise.timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    return filteredExercises.fold<double>(0.0, (sum, exercise) => sum + exercise.caloriesBurned);
  }

  // 특정 날짜의 총 소모 칼로리
  static Future<double> getDailyCaloriesBurned(DateTime date) async {
    final exercises = await getExercisesByDate(date);
    return exercises.fold<double>(0.0, (sum, exercise) => sum + exercise.caloriesBurned);
  }

  // 주간 통계
  static Future<Map<String, double>> getWeeklyStats(DateTime weekStart) async {
    final stats = <String, double>{};
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateKey = '${date.month}/${date.day}';
      stats[dateKey] = await getDailyCaloriesBurned(date);
    }
    return stats;
  }

  // 월간 통계
  static Future<Map<String, double>> getMonthlyStats(int year, int month) async {
    final stats = <String, double>{};
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dateKey = '$month/$day';
      stats[dateKey] = await getDailyCaloriesBurned(date);
    }
    return stats;
  }

  // 운동 유형별 통계
  static Future<Map<String, int>> getExerciseTypeStats(DateTime startDate, DateTime endDate) async {
    final allExercises = await getAllExercises();
    final filteredExercises = allExercises.where((exercise) {
      return exercise.timestamp.isAfter(startDate.subtract(const Duration(days: 1))) &&
          exercise.timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final typeStats = <String, int>{};
    for (var exercise in filteredExercises) {
      typeStats[exercise.exerciseType] = (typeStats[exercise.exerciseType] ?? 0) + 1;
    }
    return typeStats;
  }

  // 운동 기록 저장 (내부 메서드)
  static Future<void> _saveExercises(List<ExerciseEntry> exercises) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(exercises.map((e) => e.toJson()).toList());
    await prefs.setString(_exercisesKey, encoded);
  }

  // 모든 운동 기록 삭제
  static Future<void> clearAllExercises() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_exercisesKey);
  }
}
