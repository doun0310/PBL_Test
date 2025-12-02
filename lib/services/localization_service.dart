import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _localeKey = 'app_locale';
  
  // 지원 언어 목록
  static const List<Locale> supportedLocales = [
    Locale('ko', 'KR'), // 한국어
    Locale('en', 'US'), // 영어
    Locale('ja', 'JP'), // 일본어
    Locale('zh', 'CN'), // 중국어
  ];

  // 현재 로케일 가져오기
  static Future<Locale> getCurrentLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);
    
    if (localeCode == null) {
      return const Locale('ko', 'KR'); // 기본값: 한국어
    }

    final parts = localeCode.split('_');
    return Locale(parts[0], parts.length > 1 ? parts[1] : '');
  }

  // 로케일 변경
  static Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, '${locale.languageCode}_${locale.countryCode}');
  }

  // 언어 이름 가져오기
  static String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'zh':
        return '中文';
      default:
        return locale.languageCode;
    }
  }

  // 언어 플래그 이모지
  static String getLanguageFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return '🇰🇷';
      case 'en':
        return '🇺🇸';
      case 'ja':
        return '🇯🇵';
      case 'zh':
        return '🇨🇳';
      default:
        return '🌐';
    }
  }
}

// 간단한 번역 클래스
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // 번역 맵
  static final Map<String, Map<String, String>> _localizedValues = {
    'ko': {
      'app_title': '영양소 추적기',
      'dashboard': '대시보드',
      'add_meal': '식사 추가',
      'statistics': '통계',
      'profile': '프로필',
      'community': '커뮤니티',
      'exercise': '운동',
      'recipes': '레시피',
      'settings': '설정',
      'logout': '로그아웃',
      'calories': '칼로리',
      'protein': '단백질',
      'carbs': '탄수화물',
      'fat': '지방',
      'breakfast': '아침',
      'lunch': '점심',
      'dinner': '저녁',
      'snack': '간식',
      'today': '오늘',
      'week': '주간',
      'month': '월간',
      'goal': '목표',
      'consumed': '섭취',
      'remaining': '남음',
      'save': '저장',
      'cancel': '취소',
      'delete': '삭제',
      'edit': '수정',
      'search': '검색',
      'share': '공유',
      'notification': '알림',
      'dark_mode': '다크 모드',
      'language': '언어',
      'sync': '동기화',
      'backup': '백업',
      'restore': '복원',
    },
    'en': {
      'app_title': 'Nutrition Tracker',
      'dashboard': 'Dashboard',
      'add_meal': 'Add Meal',
      'statistics': 'Statistics',
      'profile': 'Profile',
      'community': 'Community',
      'exercise': 'Exercise',
      'recipes': 'Recipes',
      'settings': 'Settings',
      'logout': 'Logout',
      'calories': 'Calories',
      'protein': 'Protein',
      'carbs': 'Carbs',
      'fat': 'Fat',
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'dinner': 'Dinner',
      'snack': 'Snack',
      'today': 'Today',
      'week': 'Week',
      'month': 'Month',
      'goal': 'Goal',
      'consumed': 'Consumed',
      'remaining': 'Remaining',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'share': 'Share',
      'notification': 'Notification',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'sync': 'Sync',
      'backup': 'Backup',
      'restore': 'Restore',
    },
    'ja': {
      'app_title': '栄養トラッカー',
      'dashboard': 'ダッシュボード',
      'add_meal': '食事を追加',
      'statistics': '統計',
      'profile': 'プロフィール',
      'community': 'コミュニティ',
      'exercise': '運動',
      'recipes': 'レシピ',
      'settings': '設定',
      'logout': 'ログアウト',
      'calories': 'カロリー',
      'protein': 'タンパク質',
      'carbs': '炭水化物',
      'fat': '脂肪',
      'breakfast': '朝食',
      'lunch': '昼食',
      'dinner': '夕食',
      'snack': 'スナック',
      'today': '今日',
      'week': '週',
      'month': '月',
      'goal': '目標',
      'consumed': '摂取',
      'remaining': '残り',
      'save': '保存',
      'cancel': 'キャンセル',
      'delete': '削除',
      'edit': '編集',
      'search': '検索',
      'share': '共有',
      'notification': '通知',
      'dark_mode': 'ダークモード',
      'language': '言語',
      'sync': '同期',
      'backup': 'バックアップ',
      'restore': '復元',
    },
    'zh': {
      'app_title': '营养追踪器',
      'dashboard': '仪表板',
      'add_meal': '添加餐食',
      'statistics': '统计',
      'profile': '个人资料',
      'community': '社区',
      'exercise': '运动',
      'recipes': '食谱',
      'settings': '设置',
      'logout': '登出',
      'calories': '卡路里',
      'protein': '蛋白质',
      'carbs': '碳水化合物',
      'fat': '脂肪',
      'breakfast': '早餐',
      'lunch': '午餐',
      'dinner': '晚餐',
      'snack': '小吃',
      'today': '今天',
      'week': '周',
      'month': '月',
      'goal': '目标',
      'consumed': '已摄入',
      'remaining': '剩余',
      'save': '保存',
      'cancel': '取消',
      'delete': '删除',
      'edit': '编辑',
      'search': '搜索',
      'share': '分享',
      'notification': '通知',
      'dark_mode': '深色模式',
      'language': '语言',
      'sync': '同步',
      'backup': '备份',
      'restore': '恢复',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // 편의 메서드
  String get appTitle => translate('app_title');
  String get dashboard => translate('dashboard');
  String get addMeal => translate('add_meal');
  String get statistics => translate('statistics');
  String get profile => translate('profile');
  String get community => translate('community');
  String get exercise => translate('exercise');
  String get recipes => translate('recipes');
  String get settings => translate('settings');
  String get logout => translate('logout');
  String get calories => translate('calories');
  String get protein => translate('protein');
  String get carbs => translate('carbs');
  String get fat => translate('fat');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return LocalizationService.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
