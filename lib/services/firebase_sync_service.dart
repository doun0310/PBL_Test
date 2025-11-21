import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal_entry.dart';
import '../models/user_goals.dart';
import '../models/exercise_entry.dart';
import 'meal_tracking_service.dart';

class FirebaseSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 사용자 ID 가져오기
  static String? get currentUserId => _auth.currentUser?.uid;

  // 식사 기록 동기화 (업로드)
  static Future<void> syncMealsToCloud() async {
    if (currentUserId == null) return;

    try {
      final meals = await MealTrackingService.getAllMeals();
      final batch = _firestore.batch();

      for (var meal in meals) {
        final docRef = _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('meals')
            .doc(meal.id);
        
        batch.set(docRef, meal.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      print('식사 기록 동기화 실패: $e');
      rethrow;
    }
  }

  // 식사 기록 복원 (다운로드)
  static Future<void> restoreMealsFromCloud() async {
    if (currentUserId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meals')
          .get();

      final meals = snapshot.docs
          .map((doc) => MealEntry.fromJson(doc.data()))
          .toList();

      // 로컬에 저장
      for (var meal in meals) {
        await MealTrackingService.addMeal(meal);
      }
    } catch (e) {
      print('식사 기록 복원 실패: $e');
      rethrow;
    }
  }

  // 사용자 목표 동기화
  static Future<void> syncGoalsToCloud(UserGoals goals) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({'goals': goals.toJson()}, SetOptions(merge: true));
    } catch (e) {
      print('목표 동기화 실패: $e');
      rethrow;
    }
  }

  // 사용자 목표 복원
  static Future<UserGoals?> restoreGoalsFromCloud() async {
    if (currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (doc.exists && doc.data()?['goals'] != null) {
        return UserGoals.fromJson(doc.data()!['goals']);
      }
      return null;
    } catch (e) {
      print('목표 복원 실패: $e');
      return null;
    }
  }

  // 운동 기록 동기화
  static Future<void> syncExercisesToCloud(List<ExerciseEntry> exercises) async {
    if (currentUserId == null) return;

    try {
      final batch = _firestore.batch();

      for (var exercise in exercises) {
        final docRef = _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('exercises')
            .doc(exercise.id);
        
        batch.set(docRef, exercise.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      print('운동 기록 동기화 실패: $e');
      rethrow;
    }
  }

  // 운동 기록 복원
  static Future<List<ExerciseEntry>> restoreExercisesFromCloud() async {
    if (currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('exercises')
          .get();

      return snapshot.docs
          .map((doc) => ExerciseEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('운동 기록 복원 실패: $e');
      return [];
    }
  }

  // 전체 백업
  static Future<void> backupAllData() async {
    await syncMealsToCloud();
    final goals = await MealTrackingService.getUserGoals();
    if (goals != null) {
      await syncGoalsToCloud(goals);
    }
  }

  // 전체 복원
  static Future<void> restoreAllData() async {
    await restoreMealsFromCloud();
    final goals = await restoreGoalsFromCloud();
    if (goals != null) {
      await MealTrackingService.saveUserGoals(goals);
    }
  }

  // 실시간 동기화 리스너 설정
  static Stream<List<MealEntry>> watchMeals() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('meals')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MealEntry.fromJson(doc.data()))
            .toList());
  }
}
