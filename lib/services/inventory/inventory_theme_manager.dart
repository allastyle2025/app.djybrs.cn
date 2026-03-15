import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题配置类
class AppTheme {
  final String name;
  final String icon;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color divider;
  final Color success;
  final Color danger;
  final Brightness brightness;

  const AppTheme({
    required this.name,
    required this.icon,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.divider,
    required this.success,
    required this.danger,
    required this.brightness,
  });
}

/// 10套精美主题
class Themes {
  static const macaron = AppTheme(
    name: '马卡龙',
    icon: '🍬',
    primary: Color(0xFFFFB7C5),
    primaryLight: Color(0xFFFFD1DC),
    primaryDark: Color(0xFFFF9AAF),
    secondary: Color(0xFFB5EAD7),
    background: Color(0xFFFFF5F7),
    surface: Colors.white,
    textPrimary: Color(0xFF6B5B5B),
    textSecondary: Color(0xFF9B8B8B),
    accent: Color(0xFFFFDAC1),
    divider: Color(0xFFFFE4E8),
    success: Color(0xFF96CEB4),
    danger: Color(0xFFFF8B94),
    brightness: Brightness.light,
  );

  static const dark = AppTheme(
    name: '黑夜',
    icon: '🌙',
    primary: Color(0xFF7C4DFF),
    primaryLight: Color(0xFFB388FF),
    primaryDark: Color(0xFF651FFF),
    secondary: Color(0xFF00BCD4),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    textPrimary: Color(0xFFE0E0E0),
    textSecondary: Color(0xFF9E9E9E),
    accent: Color(0xFFFF4081),
    divider: Color(0xFF2C2C2C),
    success: Color(0xFF66BB6A),
    danger: Color(0xFFEF5350),
    brightness: Brightness.dark,
  );

  static const light = AppTheme(
    name: '白天',
    icon: '☀️',
    primary: Color(0xFF2196F3),
    primaryLight: Color(0xFF64B5F6),
    primaryDark: Color(0xFF1976D2),
    secondary: Color(0xFF4CAF50),
    background: Color(0xFFF5F5F5),
    surface: Colors.white,
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF757575),
    accent: Color(0xFFFF9800),
    divider: Color(0xFFE0E0E0),
    success: Color(0xFF4CAF50),
    danger: Color(0xFFF44336),
    brightness: Brightness.light,
  );

  static const kawaii = AppTheme(
    name: '可爱',
    icon: '🎀',
    primary: Color(0xFFFF69B4),
    primaryLight: Color(0xFFFF8DC7),
    primaryDark: Color(0xFFFF1493),
    secondary: Color(0xFFFFB6C1),
    background: Color(0xFFFFF0F5),
    surface: Colors.white,
    textPrimary: Color(0xFF8B4C6B),
    textSecondary: Color(0xFFB88AA0),
    accent: Color(0xFFFFD700),
    divider: Color(0xFFFFE4F0),
    success: Color(0xFF98D8C8),
    danger: Color(0xFFFFA07A),
    brightness: Brightness.light,
  );

  static const industrial = AppTheme(
    name: '工业',
    icon: '⚙️',
    primary: Color(0xFF607D8B),
    primaryLight: Color(0xFF90A4AE),
    primaryDark: Color(0xFF455A64),
    secondary: Color(0xFFFF5722),
    background: Color(0xFF263238),
    surface: Color(0xFF37474F),
    textPrimary: Color(0xFFECEFF1),
    textSecondary: Color(0xFFB0BEC5),
    accent: Color(0xFFFFC107),
    divider: Color(0xFF455A64),
    success: Color(0xFF81C784),
    danger: Color(0xFFE57373),
    brightness: Brightness.dark,
  );

  static const temple = AppTheme(
    name: '寺院',
    icon: '🏯',
    primary: Color(0xFF8D6E63),
    primaryLight: Color(0xFFBCAAA4),
    primaryDark: Color(0xFF6D4C41),
    secondary: Color(0xFF558B2F),
    background: Color(0xFFF5F5DC),
    surface: Color(0xFFFAFAF0),
    textPrimary: Color(0xFF3E2723),
    textSecondary: Color(0xFF6D4C41),
    accent: Color(0xFFD4AF37),
    divider: Color(0xFFD7CCC8),
    success: Color(0xFF8BC34A),
    danger: Color(0xFFCD5C5C),
    brightness: Brightness.light,
  );

  static const ocean = AppTheme(
    name: '海洋',
    icon: '🌊',
    primary: Color(0xFF006994),
    primaryLight: Color(0xFF4FC3F7),
    primaryDark: Color(0xFF01579B),
    secondary: Color(0xFF00ACC1),
    background: Color(0xFFE0F7FA),
    surface: Colors.white,
    textPrimary: Color(0xFF006064),
    textSecondary: Color(0xFF00838F),
    accent: Color(0xFFFFB300),
    divider: Color(0xFFB2EBF2),
    success: Color(0xFF26A69A),
    danger: Color(0xFFEF5350),
    brightness: Brightness.light,
  );

  static const forest = AppTheme(
    name: '森林',
    icon: '🌲',
    primary: Color(0xFF2E7D32),
    primaryLight: Color(0xFF66BB6A),
    primaryDark: Color(0xFF1B5E20),
    secondary: Color(0xFF795548),
    background: Color(0xFFF1F8E9),
    surface: Colors.white,
    textPrimary: Color(0xFF1B5E20),
    textSecondary: Color(0xFF4E342E),
    accent: Color(0xFFFF6F00),
    divider: Color(0xFFDCEDC8),
    success: Color(0xFF558B2F),
    danger: Color(0xFFD32F2F),
    brightness: Brightness.light,
  );

  static const cyberpunk = AppTheme(
    name: '赛博',
    icon: '🤖',
    primary: Color(0xFF00F0FF),
    primaryLight: Color(0xFF80F8FF),
    primaryDark: Color(0xFF00C4CC),
    secondary: Color(0xFFFF00FF),
    background: Color(0xFF0A0A0F),
    surface: Color(0xFF1A1A2E),
    textPrimary: Color(0xFFE0E0FF),
    textSecondary: Color(0xFF8080A0),
    accent: Color(0xFFFFD700),
    divider: Color(0xFF2A2A3E),
    success: Color(0xFF00E676),
    danger: Color(0xFFFF1744),
    brightness: Brightness.dark,
  );

  static const morandi = AppTheme(
    name: '莫兰迪',
    icon: '🎨',
    primary: Color(0xFF9B8B7A),
    primaryLight: Color(0xFFB8A99A),
    primaryDark: Color(0xFF7D6E5D),
    secondary: Color(0xFF8B9A7C),
    background: Color(0xFFF5F0EB),
    surface: Colors.white,
    textPrimary: Color(0xFF4A4A4A),
    textSecondary: Color(0xFF8B8680),
    accent: Color(0xFFC9B8A7),
    divider: Color(0xFFE8E0D8),
    success: Color(0xFFA5D6A7),
    danger: Color(0xFFEF9A9A),
    brightness: Brightness.light,
  );

  static const List<AppTheme> all = [
    macaron,
    dark,
    light,
    kawaii,
    industrial,
    temple,
    ocean,
    forest,
    cyberpunk,
    morandi,
  ];
}

/// 库存管理主题管理器（单例模式）
class InventoryThemeManager {
  static final InventoryThemeManager _instance = InventoryThemeManager._internal();
  factory InventoryThemeManager() => _instance;
  InventoryThemeManager._internal();

  static const String _themeKey = 'inventory_theme_index';
  int _currentThemeIndex = 0;
  bool _isInitialized = false;

  int get currentThemeIndex => _currentThemeIndex;
  AppTheme get currentTheme => Themes.all[_currentThemeIndex];

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentThemeIndex = prefs.getInt(_themeKey) ?? 0;
      _isInitialized = true;
    } catch (e) {
      _currentThemeIndex = 0;
      _isInitialized = true;
    }
  }

  Future<void> setThemeIndex(int index) async {
    _currentThemeIndex = index % Themes.all.length;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, _currentThemeIndex);
    } catch (e) {
    }
  }

  Future<void> nextTheme() async {
    await setThemeIndex(_currentThemeIndex + 1);
  }

  AppTheme getThemeByIndex(int index) {
    return Themes.all[index % Themes.all.length];
  }
}
