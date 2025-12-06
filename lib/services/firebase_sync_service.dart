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
    if (currentUserId == null) {
      throw Exception('로그인이 필요합니다. 먼저 로그인해주세요.');
    }

    try {
      final meals = await MealTrackingService.getAllMeals();
      
      if (meals.isEmpty) {
        throw Exception('동기화할 식사 기록이 없습니다.');
      }

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
      if (e.toString().contains('로그인')) {
        rethrow;
      }
      throw Exception('식사 기록 동기화 실패: ${e.toString()}');
    }
  }

  // 식사 기록 복원 (다운로드)
  static Future<void> restoreMealsFromCloud() async {
    if (currentUserId == null) {
      throw Exception('사용자가 로그인되어 있지 않습니다.');
    }

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
      throw Exception('식사 기록 복원 실패: $e');
    }
  }

  // 사용자 목표 동기화
  static Future<void> syncGoalsToCloud(UserGoals goals) async {
    if (currentUserId == null) {
      throw Exception('사용자가 로그인되어 있지 않습니다.');
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({'goals': goals.toJson()}, SetOptions(merge: true));
    } catch (e) {
      throw Exception('목표 동기화 실패: $e');
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
      // 목표 복원 실패 시 null 반환
      return null;
    }
  }

  // 운동 기록 동기화
  static Future<void> syncExercisesToCloud(List<ExerciseEntry> exercises) async {
    if (currentUserId == null) {
      throw Exception('사용자가 로그인되어 있지 않습니다.');
    }

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
      throw Exception('운동 기록 동기화 실패: $e');
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
      // 운동 기록 복원 실패 시 빈 리스트 반환
      return [];
    }
  }

  // 전체 백업
  static Future<void> backupAllData() async {
    if (currentUserId == null) {
      throw Exception('로그인이 필요합니다. 먼저 로그인해주세요.');
    }
    
    try {
      await syncMealsToCloud();
      final goals = await MealTrackingService.getUserGoals();
      await syncGoalsToCloud(goals);
    } catch (e) {
      if (e.toString().contains('로그인') || e.toString().contains('동기화할 식사 기록이 없습니다')) {
        rethrow;
      }
      throw Exception('백업 실패: ${e.toString()}');
    }
  }

  // 전체 복원
  static Future<void> restoreAllData() async {
    if (currentUserId == null) {
      throw Exception('로그인이 필요합니다. 먼저 로그인해주세요.');
    }
    
    try {
      await restoreMealsFromCloud();
      final goals = await restoreGoalsFromCloud();
      if (goals != null) {
        await MealTrackingService.saveUserGoals(goals);
      }
    } catch (e) {
      if (e.toString().contains('로그인')) {
        rethrow;
      }
      throw Exception('복원 실패: ${e.toString()}');
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
