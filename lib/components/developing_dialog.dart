import 'package:flutter/material.dart';
import '../room_colors.dart';

/// 功能正在开发中弹窗组件
class DevelopingDialog {
  /// 显示开发中提示
  static Future<void> show(BuildContext context, {String? featureName}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 开发中图标
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: RoomColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.construction,
                      size: 32,
                      color: RoomColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 标题
                Text(
                  '功能开发中',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: RoomColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // 提示内容
                Text(
                  featureName != null
                      ? '「$featureName」功能正在紧张开发中，敬请期待！'
                      : '该功能正在紧张开发中，敬请期待！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: RoomColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                // 确定按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RoomColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('知道了'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
