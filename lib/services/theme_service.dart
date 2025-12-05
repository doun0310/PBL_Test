import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _systemThemeKey = 'use_system_theme';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _useSystemTheme = true;
  bool _isAnimating = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark || 
      (_themeMode == ThemeMode.system && _isSystemDark());
  bool get useSystemTheme => _useSystemTheme;
  bool get isAnimating => _isAnimating;

  // 시스템 다크모드 감지
  bool _isSystemDark() {
    return SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  // 초기화
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _useSystemTheme = prefs.getBool(_systemThemeKey) ?? true;
    
    if (_useSystemTheme) {
      _themeMode = ThemeMode.system;
    } else {
      final isDark = prefs.getBool(_themeKey) ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }
    
    notifyListeners();
  }

  // 테마 변경 (애니메이션 포함)
  Future<void> toggleTheme() async {
    _isAnimating = true;
    notifyListeners();
    
    // Chrome처럼 자연스러운 전환을 위한 짧은 딜레이
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (_useSystemTheme) {
      // 시스템 테마 사용 중이면 수동 모드로 전환
      _useSystemTheme = false;
      _themeMode = _isSystemDark() ? ThemeMode.light : ThemeMode.dark;
    } else {
      // 수동 모드에서 토글
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
    await prefs.setBool(_systemThemeKey, _useSystemTheme);
    
    notifyListeners();
    
    // 애니메이션 완료 후 상태 리셋
    await Future.delayed(const Duration(milliseconds: 200));
    _isAnimating = false;
    notifyListeners();
  }

  // 시스템 테마 사용 설정
  Future<void> setUseSystemTheme(bool value) async {
    _isAnimating = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 50));
    
    _useSystemTheme = value;
    if (value) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = _isSystemDark() ? ThemeMode.dark : ThemeMode.light;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_systemThemeKey, value);
    if (!value) {
      await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
    }
    
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _isAnimating = false;
    notifyListeners();
  }

  // 특정 테마로 설정
  Future<void> setThemeMode(ThemeMode mode) async {
    _isAnimating = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 50));
    
    _themeMode = mode;
    _useSystemTheme = mode == ThemeMode.system;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_systemThemeKey, _useSystemTheme);
    if (!_useSystemTheme) {
      await prefs.setBool(_themeKey, mode == ThemeMode.dark);
    }
    
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _isAnimating = false;
    notifyListeners();
  }

  // 라이트 테마
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.green,
      primaryColor: const Color(0xFF4CAF50),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        primary: const Color(0xFF4CAF50),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF2C3E50),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4CAF50),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        elevation: 8,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // 다크 테마
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.green,
      primaryColor: const Color(0xFF66BB6A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF66BB6A),
        primary: const Color(0xFF66BB6A),
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E1E),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF66BB6A),
          foregroundColor: Colors.black,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF66BB6A),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white38),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF66BB6A), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: Color(0xFF66BB6A),
        unselectedItemColor: Colors.grey,
        elevation: 8,
      ),
      dividerColor: Colors.white24,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // 테마에 따른 색상 가져오기
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
  }

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF2C3E50);
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.grey[600]!;
  }

  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white24
        : Colors.grey[300]!;
  }
}
