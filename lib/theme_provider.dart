import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_manager.dart';

class ThemeProvider extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.day;
  static const String _themeKey = 'app_theme';

  AppTheme get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  // 从本地存储加载主题
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    if (themeString != null) {
      _currentTheme = _parseTheme(themeString);
      ThemeManager.setTheme(_currentTheme);
      notifyListeners();
    }
  }

  // 解析主题字符串
  AppTheme _parseTheme(String themeString) {
    return switch (themeString) {
      'day' => AppTheme.day,
      'night' => AppTheme.night,
      'eyeCare' => AppTheme.eyeCare,
      'temple' => AppTheme.temple,
      _ => AppTheme.day,
    };
  }

  // 将主题转换为字符串
  String _themeToString(AppTheme theme) {
    return switch (theme) {
      AppTheme.day => 'day',
      AppTheme.night => 'night',
      AppTheme.eyeCare => 'eyeCare',
      AppTheme.temple => 'temple',
    };
  }

  ThemeMode get themeMode {
    switch (_currentTheme) {
      case AppTheme.day:
      case AppTheme.eyeCare:
      case AppTheme.temple:
        return ThemeMode.light;
      case AppTheme.night:
        return ThemeMode.dark;
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    ThemeManager.setTheme(theme);
    
    // 保存到本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeToString(theme));
    
    notifyListeners();
  }

  ThemeData getThemeData(BuildContext context) {
    final colors = ThemeManager.currentColors;
    
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        primary: colors.primary,
        brightness: _currentTheme == AppTheme.night ? Brightness.dark : Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.cardBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: colors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.tabBg,
        selectedItemColor: colors.tabSelected,
        unselectedItemColor: colors.tabNormal,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
