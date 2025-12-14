import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal_entry.dart';
import '../models/user_goals.dart';
import '../models/exercise_entry.dart';
import 'meal_tracking_service.dart';
// 🔥 추가: ExerciseTrackingService 임포트
import 'exercise_tracking_service.dart';
import '../main.dart';

class FirebaseSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 사용자 ID를 비동기적으로 가져오고, 필요한 경우 인증을 기다립니다.
  static Future<String?> _getUserId() async {
    if (_auth.currentUser != null) {
      return _auth.currentUser!.uid;
    }
    // 인증 상태 변경을 기다립니다. 타임아웃을 20초로 늘립니다.
    final user = await _auth.authStateChanges().firstWhere((user) => user != null).timeout(
      const Duration(seconds: 20),
      // 타임아웃 시 예외를 던지는 대신 null을 반환합니다.
      onTimeout: () => null,
    );
    return user?.uid;
  }

  // 사용자 ID를 가져오고 null일 경우 예외를 던지는 헬퍼 함수
  static Future<String> _getRequiredUserId() async {
    final userId = await _getUserId();
    if (userId == null) {
      throw Exception('로그인이 필요합니다. 다시 시도해주세요.');
    }
    return userId;
  }

  // 식사 기록 동기화 (업로드)
  static Future<void> syncMealsToCloud() async {
    try {
      final userId = await _getRequiredUserId();
      final meals = await MealTrackingService.getAllMeals();

      if (meals.isEmpty) {
        return;
      }

      final batch = _firestore.batch();
      for (var meal in meals) {
        final docRef = _firestore.collection('users').doc(userId).collection('meals').doc(meal.id);
        batch.set(docRef, meal.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      throw Exception('식사 기록 동기화 실패: ${e.toString()}');
    }
  }

  // 식사 기록 복원 (다운로드)
  static Future<void> restoreMealsFromCloud() async {
    try {
      final userId = await _getRequiredUserId();
      final snapshot = await _firestore.collection('users').doc(userId).collection('meals').get();
      final meals = snapshot.docs.map((doc) => MealEntry.fromJson(doc.data())).toList();
      // 🔥 주의: MealTrackingService.addMeal()이 각 기록을 로컬 DB에 저장한다고 가정
      for (var meal in meals) {
        await MealTrackingService.addMeal(meal);
      }
    } catch (e) {
      throw Exception('식사 기록 복원 실패: $e');
    }
  }

  // 사용자 목표 동기화
  static Future<void> syncGoalsToCloud(UserGoals goals) async {
    try {
      final userId = await _getRequiredUserId();
      await _firestore.collection('users').doc(userId).set({'goals': goals.toJson()}, SetOptions(merge: true));
    } catch (e) {
      throw Exception('목표 동기화 실패: $e');
    }
  }

  // 사용자 목표 복원
  static Future<UserGoals?> restoreGoalsFromCloud() async {
    try {
      final userId = await _getUserId(); // 여기서는 null을 허용
      if (userId == null) return null;
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data()?['goals'] != null) {
        return UserGoals.fromJson(doc.data()!['goals']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 운동 기록 동기화 (로컬 데이터베이스와 통합)
  static Future<void> syncExercisesToCloud() async { // 🔥 함수 시그니처 수정
    try {
      final userId = await _getRequiredUserId();
      // 🔥 수정: ExerciseTrackingService를 통해 로컬 운동 기록 가져오기
      final exercises = await ExerciseTrackingService.getAllExercises();

      final batch = _firestore.batch();
      for (var exercise in exercises) {
        final docRef = _firestore.collection('users').doc(userId).collection('exercises').doc(exercise.id);
        batch.set(docRef, exercise.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      throw Exception('운동 기록 동기화 실패: ${e.toString()}');
    }
  }

  // 운동 기록 복원
  static Future<List<ExerciseEntry>> restoreExercisesFromCloud() async {
    try {
      final userId = await _getUserId(); // 여기서는 null을 허용
      if (userId == null) return [];
      final snapshot = await _firestore.collection('users').doc(userId).collection('exercises').get();
      return snapshot.docs.map((doc) => ExerciseEntry.fromJson(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }

  // 전체 백업
  static Future<void> backupAllData() async {
    try {
      await _getRequiredUserId(); // 로그인 확인
      await syncMealsToCloud();
      final goals = await MealTrackingService.getUserGoals();
      await syncGoalsToCloud(goals);
      // 🔥 수정: 운동 기록 동기화 (전체 데이터)
      await syncExercisesToCloud();
    } catch (e) {
      throw Exception('백업 실패: ${e.toString()}');
    }
  }

  // 전체 복원
  static Future<void> restoreAllData() async {
    try {
      await _getRequiredUserId(); // 로그인 확인
      await restoreMealsFromCloud();
      final goals = await restoreGoalsFromCloud();
      if (goals != null) {
        // 🔥 주의: MealTrackingService.saveUserGoals()가 목표를 로컬에 저장한다고 가정
        await MealTrackingService.saveUserGoals(goals);
      }

      // 🔥 수정: 운동 기록 복원 후 로컬에 저장
      final exercises = await restoreExercisesFromCloud();
      // 기존 운동 기록을 지우고 복원된 데이터로 대체하는 것이 안전 (선택 사항: ExerciseTrackingService.clearAllExercises() 호출)
      await ExerciseTrackingService.clearAllExercises();
      for (var exercise in exercises) {
        await ExerciseTrackingService.addExercise(exercise);
      }

    } catch (e) {
      throw Exception('복원 실패: ${e.toString()}');
    }
  }

  // 실시간 동기화 리스너 설정
  static Stream<List<MealEntry>> watchMeals() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MealEntry.fromJson(doc.data())).toList());
  }
}