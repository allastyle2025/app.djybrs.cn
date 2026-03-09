import 'package:flutter/material.dart';
import '../models/user.dart';
import '../room_colors.dart';
import '../services/auth_service.dart';

/// 用户详情弹窗组件
class UserProfileDialog extends StatelessWidget {
  final User? user;

  const UserProfileDialog({super.key, this.user});

  static Future<void> show(BuildContext context, {User? user}) {
    return showDialog(
      context: context,
      builder: (context) => UserProfileDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayUser = user ?? AuthService.currentUser;
    final roleText = displayUser?.role == 'admin' ? '管理员' : '普通用户';
    final roleColor = displayUser?.role == 'admin' ? RoomColors.occupied : RoomColors.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      RoomColors.primary.withOpacity(0.1),
                      RoomColors.primary.withOpacity(0.02),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '用户信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: RoomColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: RoomColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 内容区域
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 用户头像
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: RoomColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          displayUser?.userName.substring(0, 1).toUpperCase() ?? 'U',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: RoomColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 昵称
                    Text(
                      displayUser?.nickName ?? displayUser?.userName ?? '用户',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: RoomColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 角色标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        roleText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: roleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 分隔线
                    Divider(color: RoomColors.divider),
                    const SizedBox(height: 16),
                    // 用户信息列表
                    _buildInfoRow(Icons.person_outline, '用户名', displayUser?.userName ?? '-'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.badge_outlined, '用户ID', '${displayUser?.userId ?? '-'}'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.shield_outlined, '角色', roleText),
                    const SizedBox(height: 16),
                    // 分隔线
                    Divider(color: RoomColors.divider),
                    const SizedBox(height: 16),
                    // 提示信息
                    Text(
                      '点击头像区域可查看此详情',
                      style: TextStyle(
                        fontSize: 12,
                        color: RoomColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: RoomColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: RoomColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: RoomColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
