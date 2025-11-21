import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // 초기화
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  // 알림 클릭 시 처리
  static void _onNotificationTapped(NotificationResponse response) {
    // 알림 클릭 시 처리 로직 (필요시 구현)
    // 예: 특정 화면으로 이동 등
  }

  // 권한 요청
  static Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    final iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      return await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }

    return true;
  }

  // 즉시 알림 표시
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'meal_reminder',
      '식사 알림',
      channelDescription: '식사 시간 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  // 예약 알림 설정
  static Future<void> scheduleMealReminder({
    required int id,
    required String mealType,
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 이미 지난 시간이면 다음 날로 설정
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'meal_reminder',
      '식사 알림',
      channelDescription: '식사 시간 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      '$mealType 시간입니다! 🍽️',
      '건강한 식사를 기록하세요.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 반복
    );
  }

  // 모든 식사 알림 설정
  static Future<void> setupDefaultMealReminders() async {
    await scheduleMealReminder(id: 1, mealType: '아침', hour: 8, minute: 0);
    await scheduleMealReminder(id: 2, mealType: '점심', hour: 12, minute: 0);
    await scheduleMealReminder(id: 3, mealType: '저녁', hour: 18, minute: 0);
  }

  // 특정 알림 취소
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // 모든 알림 취소
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // 대기 중인 알림 목록 조회
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // 알림 설정 저장
  static Future<void> saveMealReminderSettings(Map<String, Map<String, int>> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('meal_reminders', json.encode(settings));
  }

  // 알림 설정 불러오기
  static Future<Map<String, Map<String, int>>?> getMealReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('meal_reminders');
    
    if (settingsJson == null) return null;
    
    final decoded = json.decode(settingsJson) as Map<String, dynamic>;
    return decoded.map((key, value) => 
      MapEntry(key, Map<String, int>.from(value as Map))
    );
  }

  // 알림 활성화 상태 저장
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    
    if (!enabled) {
      await cancelAllNotifications();
    } else {
      await setupDefaultMealReminders();
    }
  }

  // 알림 활성화 상태 확인
  static Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }
}
