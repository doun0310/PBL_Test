import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  // ✅ 수정: 웹 테스트는 실제 IP 주소로 변경 필요
  static const String baseUrl = 'http://localhost:3000/api';
  // static const String baseUrl = 'http://192.168.0.100:3000/api'; // 웹 테스트용

  // 로그인
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // JWT 토큰 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data['user']));

        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'message': '로그인 성공',
        };
      } else {
        return {
          'success': false,
          'message': '이메일 또는 비밀번호가 올바르지 않습니다.',
        };
      }
    } catch (e) {
      print('로그인 오류: \${e.toString()}');
      return {
        'success': false,
        'message': '서버 연결 오류: \${e.toString()}',
      };
    } // ✅ 수정: 누락된 중괄호 추가
  }

  // 회원가입
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    List<String>? allergies,
    List<String>? preferences,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'allergies': allergies ?? [],
          'preferences': preferences ?? [],
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': '회원가입이 완료되었습니다.',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? '회원가입 실패',
        };
      }
    } catch (e) {
      print('회원가입 오류: \${e.toString()}');
      return {
        'success': false,
        'message': '서버 연결 오류: \${e.toString()}',
      };
    } // ✅ 수정: 누락된 중괄호 추가
  }

  // 로그아웃
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  // 현재 사용자 정보 가져오기
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');

    if (userString != null) {
      return User.fromJson(jsonDecode(userString));
    }

    return null;
  }

  // JWT 토큰 가져오기
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
