import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

class AuthService {
  static const String _usersKey = 'users_data';
  static const String _currentUserKey = 'current_user_id';
  static const String _isLoggedInKey = 'is_logged_in';

  // 회원가입
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 기존 사용자 목록 가져오기
      final users = await _getAllUsers();
      
      // 이메일 중복 체크
      final existingUser = users.where((u) => u.email == email).firstOrNull;
      if (existingUser != null) {
        return {
          'success': false,
          'message': '이미 등록된 이메일입니다.',
        };
      }

      // 새 사용자 생성
      final newUser = User(
        id: const Uuid().v4(),
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );

      // 사용자 목록에 추가
      users.add(newUser);
      await _saveUsers(users);

      // 비밀번호 저장 (실제로는 해시 처리해야 함)
      await prefs.setString('password_${newUser.id}', password);

      return {
        'success': true,
        'message': '회원가입이 완료되었습니다.',
        'user': newUser,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '회원가입 중 오류가 발생했습니다: $e',
      };
    }
  }

  // 로그인
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = await _getAllUsers();

      // 이메일로 사용자 찾기
      final user = users.where((u) => u.email == email).firstOrNull;
      
      if (user == null) {
        return {
          'success': false,
          'message': '등록되지 않은 이메일입니다.',
        };
      }

      // 비밀번호 확인
      final savedPassword = prefs.getString('password_${user.id}');
      if (savedPassword != password) {
        return {
          'success': false,
          'message': '비밀번호가 일치하지 않습니다.',
        };
      }

      // 로그인 상태 저장
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_currentUserKey, user.id);

      return {
        'success': true,
        'message': '로그인 성공',
        'user': user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '로그인 중 오류가 발생했습니다: $e',
      };
    }
  }

  // 로그아웃
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_currentUserKey);
  }

  // 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // 현재 로그인한 사용자 가져오기
  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserKey);
      
      if (userId == null) {
        return null;
      }

      final users = await _getAllUsers();
      return users.where((u) => u.id == userId).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  // 사용자 정보 업데이트
  static Future<bool> updateUser(User user) async {
    try {
      final users = await _getAllUsers();
      final index = users.indexWhere((u) => u.id == user.id);
      
      if (index == -1) {
        return false;
      }

      users[index] = user;
      await _saveUsers(users);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 비밀번호 변경
  static Future<bool> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPassword = prefs.getString('password_$userId');
      
      if (savedPassword != oldPassword) {
        return false;
      }

      await prefs.setString('password_$userId', newPassword);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 모든 사용자 가져오기 (내부용)
  static Future<List<User>> _getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    
    if (usersJson == null) {
      return [];
    }

    final List<dynamic> decoded = json.decode(usersJson);
    return decoded.map((item) => User.fromJson(item)).toList();
  }

  // 사용자 목록 저장 (내부용)
  static Future<void> _saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = json.encode(users.map((u) => u.toJson()).toList());
    await prefs.setString(_usersKey, usersJson);
  }
}
