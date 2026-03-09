import 'package:flutter/material.dart';

enum AppTheme { day, night, eyeCare, temple }

class ThemeManager {
  static AppTheme _currentTheme = AppTheme.day;

  static AppTheme get currentTheme => _currentTheme;

  static void setTheme(AppTheme theme) {
    _currentTheme = theme;
  }

  // Day 主题（原主题）
  static ThemeColors get dayTheme => ThemeColors(
        primary: const Color(0xff07C160),
        primaryLight: const Color(0xff5ECB8B),
        primaryDark: const Color(0xff06AD56),
        background: const Color(0xffEDEDED),
        cardBg: Colors.white,
        divider: const Color(0xffE5E5E5),
        textPrimary: const Color(0xff000000),
        textSecondary: const Color(0xff999999),
        textGrey: const Color(0xff666666),
        occupied: const Color(0xffFA5151),
        available: const Color(0xff07C160),
        partial: const Color(0xffFFC300),
        tabNormal: const Color(0xff999999),
        tabSelected: const Color(0xff07C160),
        tabBg: const Color(0xffF7F7F7),
      );

  // Night 主题（深色模式）
  static ThemeColors get nightTheme => ThemeColors(
        primary: const Color(0xff5ECB8B),
        primaryLight: const Color(0xff7ED4A0),
        primaryDark: const Color(0xff07C160),
        background: const Color(0xff1A1A1A),
        cardBg: const Color(0xff2D2D2D),
        divider: const Color(0xff3D3D3D),
        textPrimary: const Color(0xffE0E0E0),
        textSecondary: const Color(0xff888888),
        textGrey: const Color(0xffAAAAAA),
        occupied: const Color(0xffFF6B6B),
        available: const Color(0xff3D3D3D),
        partial: const Color(0xffD4A84A),
        tabNormal: const Color(0xff888888),
        tabSelected: const Color(0xff5ECB8B),
        tabBg: const Color(0xff252525),
      );

  // Eye Care 主题（护眼模式）
  static ThemeColors get eyeCareTheme => ThemeColors(
        primary: const Color(0xff5A8F6E),
        primaryLight: const Color(0xff7AAF8E),
        primaryDark: const Color(0xff4A7F5E),
        background: const Color(0xffF5F0E1),
        cardBg: const Color(0xffFAF6E9),
        divider: const Color(0xffE0D9C8),
        textPrimary: const Color(0xff4A4A3A),
        textSecondary: const Color(0xff7A7A6A),
        textGrey: const Color(0xff6A6A5A),
        occupied: const Color(0xffC85A5A),
        available: const Color(0xff5A8F6E),
        partial: const Color(0xffD4A84A),
        tabNormal: const Color(0xff7A7A6A),
        tabSelected: const Color(0xff5A8F6E),
        tabBg: const Color(0xffEDE8D8),
      );

  // Temple 主题（寺院风格）
  static ThemeColors get templeTheme => ThemeColors(
        primary: const Color(0xff8B4513),
        primaryLight: const Color(0xffA0522D),
        primaryDark: const Color(0xff654321),
        background: const Color(0xffFDF5E6),
        cardBg: const Color(0xffFFFAF0),
        divider: const Color(0xffD4C4A8),
        textPrimary: const Color(0xff3D2914),
        textSecondary: const Color(0xff8B7355),
        textGrey: const Color(0xff6B5344),
        occupied: const Color(0xffB22222),
        available: const Color(0xff8B4513),
        partial: const Color(0xffDAA520),
        tabNormal: const Color(0xff8B7355),
        tabSelected: const Color(0xff8B4513),
        tabBg: const Color(0xffF5E6D3),
      );

  static ThemeColors get currentColors {
    switch (_currentTheme) {
      case AppTheme.day:
        return dayTheme;
      case AppTheme.night:
        return nightTheme;
      case AppTheme.eyeCare:
        return eyeCareTheme;
      case AppTheme.temple:
        return templeTheme;
    }
  }
}

class ThemeColors {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color background;
  final Color cardBg;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textGrey;
  final Color occupied;
  final Color available;
  final Color partial;
  final Color tabNormal;
  final Color tabSelected;
  final Color tabBg;

  ThemeColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.background,
    required this.cardBg,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textGrey,
    required this.occupied,
    required this.available,
    required this.partial,
    required this.tabNormal,
    required this.tabSelected,
    required this.tabBg,
  });
}
