import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';
import '../services/notification_service.dart';
import '../services/firebase_sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  Locale _currentLocale = const Locale('ko', 'KR');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notificationsEnabled = await NotificationService.isNotificationsEnabled();
    final locale = await LocalizationService.getCurrentLocale();
    
    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _currentLocale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          _buildSection(
            '앱 설정',
            [
              _buildDarkModeSwitch(),
              _buildLanguageSetting(),
              _buildNotificationSwitch(),
            ],
          ),
          _buildSection(
            '데이터',
            [
              _buildSyncButton(),
              _buildBackupButton(),
              _buildRestoreButton(),
            ],
          ),
          _buildSection(
            '알림 시간',
            [
              _buildMealReminderSettings(),
            ],
          ),
          _buildSection(
            '정보',
            [
              _buildAboutTile(),
              _buildVersionTile(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDarkModeSwitch() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Column(
          children: [
            ListTile(
              leading: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: RotationTransition(
                      turns: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  key: ValueKey<bool>(themeService.isDarkMode),
                  color: themeService.isDarkMode ? Colors.deepPurple[200] : Colors.orange[700],
                ),
              ),
              title: const Text('테마'),
              subtitle: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  themeService.useSystemTheme 
                      ? '시스템 설정 사용 중' 
                      : (themeService.isDarkMode ? '다크 모드' : '라이트 모드'),
                  key: ValueKey<String>(
                    themeService.useSystemTheme 
                        ? 'system' 
                        : (themeService.isDarkMode ? 'dark' : 'light'),
                  ),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemeDialog(context, themeService),
            ),
            // 시스템 테마 사용 스위치
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: !themeService.useSystemTheme
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '시스템 설정에 따라 자동으로 변경됩니다',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context, ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('테마 선택'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              themeService,
              '시스템 설정',
              '기기 설정에 따라 자동으로 변경됩니다',
              Icons.phone_android,
              ThemeMode.system,
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              context,
              themeService,
              '라이트 모드',
              '밝은 테마를 사용합니다',
              Icons.light_mode,
              ThemeMode.light,
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              context,
              themeService,
              '다크 모드',
              '어두운 테마를 사용합니다',
              Icons.dark_mode,
              ThemeMode.dark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeService themeService,
    String title,
    String subtitle,
    IconData icon,
    ThemeMode mode,
  ) {
    final isSelected = (mode == ThemeMode.system && themeService.useSystemTheme) ||
        (mode != ThemeMode.system && !themeService.useSystemTheme && themeService.themeMode == mode);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected 
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).iconTheme.color,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        trailing: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: isSelected ? 1.0 : 0.0,
          child: Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onTap: () {
          themeService.setThemeMode(mode);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('테마가 "$title"(으)로 변경되었습니다'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageSetting() {
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('언어'),
      subtitle: Text(LocalizationService.getLanguageName(_currentLocale)),
      trailing: Text(LocalizationService.getLanguageFlag(_currentLocale)),
      onTap: _showLanguageDialog,
    );
  }

  Widget _buildNotificationSwitch() {
    return SwitchListTile(
      title: const Text('알림'),
      subtitle: const Text('식사 시간 알림 받기'),
      secondary: const Icon(Icons.notifications),
      value: _notificationsEnabled,
      onChanged: (value) async {
        await NotificationService.setNotificationsEnabled(value);
        setState(() => _notificationsEnabled = value);
        
        if (value) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('알림이 활성화되었습니다')),
          );
        }
      },
    );
  }

  Widget _buildSyncButton() {
    return ListTile(
      leading: const Icon(Icons.sync),
      title: const Text('클라우드 동기화'),
      subtitle: const Text('데이터를 클라우드와 동기화'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        _showLoadingDialog('동기화 중...');
        try {
          await FirebaseSyncService.syncMealsToCloud();
          Navigator.pop(context); // 로딩 다이얼로그 닫기
          _showSuccessDialog('동기화 완료!');
        } catch (e) {
          Navigator.pop(context);
          _showErrorDialog('동기화 실패: $e');
        }
      },
    );
  }

  Widget _buildBackupButton() {
    return ListTile(
      leading: const Icon(Icons.backup),
      title: const Text('백업'),
      subtitle: const Text('모든 데이터를 클라우드에 백업'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        _showLoadingDialog('백업 중...');
        try {
          await FirebaseSyncService.backupAllData();
          Navigator.pop(context);
          _showSuccessDialog('백업 완료!');
        } catch (e) {
          Navigator.pop(context);
          _showErrorDialog('백업 실패: $e');
        }
      },
    );
  }

  Widget _buildRestoreButton() {
    return ListTile(
      leading: const Icon(Icons.restore),
      title: const Text('복원'),
      subtitle: const Text('클라우드에서 데이터 복원'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final confirm = await _showConfirmDialog(
          '데이터 복원',
          '클라우드에서 데이터를 복원하시겠습니까?\n현재 데이터는 덮어쓰기됩니다.',
        );
        
        if (confirm == true) {
          _showLoadingDialog('복원 중...');
          try {
            await FirebaseSyncService.restoreAllData();
            Navigator.pop(context);
            _showSuccessDialog('복원 완료!');
          } catch (e) {
            Navigator.pop(context);
            _showErrorDialog('복원 실패: $e');
          }
        }
      },
    );
  }

  Widget _buildMealReminderSettings() {
    return ListTile(
      leading: const Icon(Icons.alarm),
      title: const Text('식사 알림 시간'),
      subtitle: const Text('아침, 점심, 저녁 알림 시간 설정'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _showMealReminderDialog,
    );
  }

  Widget _buildAboutTile() {
    return ListTile(
      leading: const Icon(Icons.info),
      title: const Text('앱 정보'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showAboutDialog(
          context: context,
          applicationName: 'DIETRACKING',
          applicationVersion: '2.0.0',
          applicationIcon: const Icon(Icons.restaurant, size: 48),
          children: [
            const Text('AI 기반 식단 및 칼로리 추적 애플리케이션'),
            const SizedBox(height: 16),
            const Text('개발자:'),
            const Text('• 강성민: 백엔드 API 및 암호화'),
            const Text('• 이도은: 프론트엔드 개발 및 데이터 분석'),
          ],
        );
      },
    );
  }

  Widget _buildVersionTile() {
    return const ListTile(
      leading: Icon(Icons.smartphone),
      title: Text('버전'),
      trailing: Text('2.0.0'),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('언어 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocalizationService.supportedLocales.map((locale) {
            final isSelected = locale == _currentLocale;
            return ListTile(
              leading: Text(
                LocalizationService.getLanguageFlag(locale),
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(LocalizationService.getLanguageName(locale)),
              trailing: isSelected ? const Icon(Icons.check) : null,
              onTap: () async {
                await LocalizationService.setLocale(locale);
                setState(() => _currentLocale = locale);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('언어가 ${LocalizationService.getLanguageName(locale)}(으)로 변경되었습니다'),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMealReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('식사 알림 시간'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReminderTimeTile('아침', 8, 0),
            _buildReminderTimeTile('점심', 12, 0),
            _buildReminderTimeTile('저녁', 18, 0),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTimeTile(String mealType, int hour, int minute) {
    return ListTile(
      title: Text(mealType),
      trailing: Text('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
        );
        
        if (time != null) {
          await NotificationService.scheduleMealReminder(
            id: mealType == '아침' ? 1 : mealType == '점심' ? 2 : 3,
            mealType: mealType,
            hour: time.hour,
            minute: time.minute,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$mealType 알림이 ${time.format(context)}(으)로 설정되었습니다')),
          );
        }
      },
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('성공'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            const Text('오류'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
