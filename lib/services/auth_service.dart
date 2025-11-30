import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import 'backend_api_service.dart';

class AuthService {
  static const String _usersKey = 'users_data';
  static const String _currentUserKey = 'current_user_id';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _useBackendKey = 'use_backend_auth';
  
  // 백엔드 사용 여부
  static bool _useBackend = true;

  /// 초기화 - 백엔드 연결 확인
  static Future<void> initialize() async {
    _useBackend = await BackendApiService.healthCheck();
  }

  // 회원가입
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    // 백엔드 사용 시도
    if (_useBackend) {
      final result = await BackendApiService.register(
        email: email,
        password: password,
        name: name,
      );
      if (result['success'] == true) {
        return result;
      }
    }

    // 로컬 폴백
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
    // 백엔드 사용 시도
    if (_useBackend) {
      final result = await BackendApiService.login(
        email: email,
        password: password,
      );
      if (result['success'] == true) {
        // 로컬 상태 업데이트
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setBool(_useBackendKey, true);
        
        // 사용자 정보 저장
        final userData = result['user'];
        if (userData != null) {
          final user = User(
            id: userData['id'].toString(),
            email: userData['email'],
            name: userData['name'],
            createdAt: DateTime.now(),
          );
          await prefs.setString(_currentUserKey, user.id);
          
          // 로컬 사용자 목록에도 추가
          final users = await _getAllUsers();
          if (!users.any((u) => u.email == email)) {
            users.add(user);
            await _saveUsers(users);
          }
        }
        
        return result;
      }
    }

    // 로컬 폴백
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
      await prefs.setBool(_useBackendKey, false);

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
    await BackendApiService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_currentUserKey);
  }

  // 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final localLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    
    if (localLoggedIn) {
      // 백엔드 토큰 유효성 확인
      final useBackend = prefs.getBool(_useBackendKey) ?? false;
      if (useBackend) {
        return await BackendApiService.isLoggedIn();
      }
      return true;
    }
    return false;
  }

  // 현재 로그인한 사용자 가져오기
  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final useBackend = prefs.getBool(_useBackendKey) ?? false;
      
      // 백엔드에서 프로필 가져오기 시도
      if (useBackend && _useBackend) {
        final profile = await BackendApiService.getProfile();
        if (profile != null) {
          return User(
            id: profile['id'].toString(),
            email: profile['email'],
            name: profile['name'],
            createdAt: DateTime.now(),
          );
        }
      }
      
      // 로컬 폴백
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
      final prefs = await SharedPreferences.getInstance();
      final useBackend = prefs.getBool(_useBackendKey) ?? false;
      
      // 백엔드 업데이트 시도
      if (useBackend && _useBackend) {
        final success = await BackendApiService.updateProfile(
          name: user.name,
        );
        if (success) {
          // 로컬도 업데이트
          final users = await _getAllUsers();
          final index = users.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            users[index] = user;
            await _saveUsers(users);
          }
          return true;
        }
      }
      
      // 로컬 폴백
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

  // 현재 사용자 ID 가져오기
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  // 현재 사용자 이름 가져오기
  static Future<String?> getCurrentUserName() async {
    final user = await getCurrentUser();
    return user?.name;
  }
}
