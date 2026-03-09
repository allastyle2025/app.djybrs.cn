import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../room_colors.dart';
import '../services/room_service.dart';
import 'update_dialog.dart';

/// 关于我们弹窗组件
class AppAboutDialog extends StatefulWidget {
  const AppAboutDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const AppAboutDialog(),
    );
  }

  @override
  State<AppAboutDialog> createState() => _AppAboutDialogState();
}

class _AppAboutDialogState extends State<AppAboutDialog> {
  bool _isCheckingUpdate = false;
  String _currentVersion = '1.0.0'; // 默认版本

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentVersion = packageInfo.version;
      });
      print('about_dialog: 真实版本号: $_currentVersion');
    } catch (e) {
      print('about_dialog: 获取版本号失败: $e');
    }
  }

  Future<void> _checkUpdate() async {
    print('=== about_dialog: 开始检查更新 ===');
    print('about_dialog: 当前版本 $_currentVersion');

    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      print('about_dialog: 调用 RoomService.checkUpdate...');
      final response = await RoomService.checkUpdate(_currentVersion);
      print(
        'about_dialog: 收到响应 code=${response.code}, message=${response.message}',
      );
      print('about_dialog: data=${response.data}');

      if (!mounted) {
        print('about_dialog: 组件已卸载，返回');
        return;
      }

      if (response.code == 200 && response.data != null) {
        if (response.data!.hasUpdate) {
          print('about_dialog: 发现新版本');
          final downloadUrl = response.data!.downloadUrl;
          print('about_dialog: 下载链接: $downloadUrl');
          // 有更新
          UpdateDialog.show(
            context: context,
            version: response.data!,
            onUpdate: () async {
              // 实现下载更新逻辑
              if (downloadUrl != null && downloadUrl.isNotEmpty) {
                final uri = Uri.parse(downloadUrl);
                print('about_dialog: 尝试打开下载链接: $downloadUrl');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  print('about_dialog: 已打开下载链接');
                } else {
                  print('about_dialog: 无法打开下载链接');
                  throw '无法打开下载链接';
                }
              } else {
                print('about_dialog: 下载链接为空');
                throw '下载链接不可用';
              }
            },
            onCancel: () {
              // 只关闭 UpdateDialog，不关闭 AppAboutDialog
              // 这里可以什么都不做，或者只执行一些清理操作
              print('用户取消了更新');
            },
          );
        } else {
          print('about_dialog: 已是最新版本');
          // 无更新
          UpdateResultDialog.showNoUpdate(context);
        }
      } else {
        print('about_dialog: 检查失败 - ${response.message}');
        // 检查失败
        UpdateResultDialog.showError(context, response.message);
      }
    } catch (e, stackTrace) {
      print('about_dialog: 异常 - $e');
      print('about_dialog: 堆栈 - $stackTrace');
      if (!mounted) return;
      UpdateResultDialog.showError(context, '网络错误: $e');
    } finally {
      print('=== about_dialog: 检查更新结束 ===');
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
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
                      '关于我们',
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
                    // App 图标占位
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: RoomColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.hotel,
                        size: 40,
                        color: RoomColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // App 名称
                    Text(
                      'DP 房间管理',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: RoomColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 版本号
                    Text(
                      '版本 $_currentVersion',
                      style: TextStyle(
                        fontSize: 14,
                        color: RoomColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 分隔线
                    Divider(color: RoomColors.divider),
                    const SizedBox(height: 16),
                    // 作者信息
                    _buildInfoRow(Icons.person_outline, '作者', 'allastyle'),
                    const SizedBox(height: 12),
                    // 网站信息
                    _buildInfoRow(Icons.language, '网站', 'vipassana.top'),
                    const SizedBox(height: 16),
                    // 分隔线
                    Divider(color: RoomColors.divider),
                    const SizedBox(height: 16),
                    // 检查更新按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCheckingUpdate ? null : _checkUpdate,
                        icon: _isCheckingUpdate
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.system_update, size: 18),
                        label: Text(_isCheckingUpdate ? '检查中...' : '检查更新'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RoomColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 版权信息
                    Text(
                      '© 2026 Digital Prajna. All rights reserved.',
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
        Icon(icon, size: 18, color: RoomColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: RoomColors.textSecondary),
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
