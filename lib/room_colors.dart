import 'package:flutter/material.dart';
import 'theme_manager.dart';

class RoomColors {
  // 动态获取当前主题颜色
  static ThemeColors get _colors => ThemeManager.currentColors;

  // 主色调
  static Color get primary => _colors.primary;
  static Color get primaryLight => _colors.primaryLight;
  static Color get primaryDark => _colors.primaryDark;

  // 背景色
  static Color get background => _colors.background;
  static Color get cardBg => _colors.cardBg;
  static Color get divider => _colors.divider;

  // 文字色
  static Color get textPrimary => _colors.textPrimary;
  static Color get textSecondary => _colors.textSecondary;
  static Color get textGrey => _colors.textGrey;

  // 状态色
  static Color get occupied => _colors.occupied;
  static Color get available => _colors.available;
  static Color get partial => _colors.partial;

  // Tab栏
  static Color get tabNormal => _colors.tabNormal;
  static Color get tabSelected => _colors.tabSelected;
  static Color get tabBg => _colors.tabBg;
}
