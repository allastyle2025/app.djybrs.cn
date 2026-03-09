import 'package:flutter/material.dart';
import '../models/app_version.dart';
import '../room_colors.dart';

/// 应用更新弹窗组件
class UpdateDialog extends StatelessWidget {
  final AppVersion version;
  final Future<void> Function() onUpdate;
  final VoidCallback onCancel;

  const UpdateDialog({
    super.key,
    required this.version,
    required this.onUpdate,
    required this.onCancel,
  });

  static Future<void> show({
    required BuildContext context,
    required AppVersion version,
    required Future<void> Function() onUpdate,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !version.forceUpdate!,
      builder: (context) => UpdateDialog(
        version: version,
        onUpdate: onUpdate,
        onCancel: onCancel ?? () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      '发现新版本',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: RoomColors.textPrimary,
                      ),
                    ),
                    if (!(version.forceUpdate ?? false))
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          onCancel();
                        },
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
                    // 更新图标
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: RoomColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.system_update,
                        size: 32,
                        color: RoomColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 版本信息
                    Text(
                      'v${version.version}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: RoomColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 版本号
                    if (version.versionCode != null)
                      Text(
                        '版本号: ${version.versionCode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: RoomColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 16),
                    // 强制更新提示
                    if (version.forceUpdate ?? false)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: RoomColors.occupied.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '强制更新',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: RoomColors.occupied,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // 分隔线
                    Divider(color: RoomColors.divider),
                    const SizedBox(height: 16),
                    // 更新日志
                    if (version.updateLog != null && version.updateLog!.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '更新内容:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: RoomColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: RoomColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          version.updateLog!,
                          style: TextStyle(
                            fontSize: 13,
                            color: RoomColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // 文件大小和发布时间
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (version.fileSize != null)
                          _buildInfoChip(Icons.storage, version.formattedFileSize),
                        if (version.fileSize != null && version.releaseTime != null)
                          const SizedBox(width: 12),
                        if (version.releaseTime != null)
                          _buildInfoChip(Icons.calendar_today, version.formattedReleaseTime),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 按钮区域
                    Row(
                      children: [
                        if (!(version.forceUpdate ?? false)) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onCancel();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: RoomColors.textSecondary,
                                side: BorderSide(color: RoomColors.divider),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('稍后更新'),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await onUpdate();
                              } catch (e) {
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('错误'),
                                      content: Text(e.toString()),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('确定'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RoomColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('立即更新'),
                          ),
                        ),
                      ],
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: RoomColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: RoomColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 检查更新结果弹窗（无更新或错误）
class UpdateResultDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;

  const UpdateResultDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
  });

  static Future<void> showNoUpdate(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const UpdateResultDialog(
        title: '已是最新版本',
        message: '当前已是最新版本，无需更新',
        icon: Icons.check_circle,
        iconColor: Colors.green,
      ),
    );
  }

  static Future<void> showError(BuildContext context, String errorMessage) {
    return showDialog(
      context: context,
      builder: (context) => UpdateResultDialog(
        title: '检查更新失败',
        message: errorMessage,
        icon: Icons.error,
        iconColor: RoomColors.occupied,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 32),
              Icon(
                icon,
                size: 48,
                color: iconColor,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: RoomColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: RoomColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
