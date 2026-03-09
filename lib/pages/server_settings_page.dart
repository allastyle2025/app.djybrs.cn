import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../room_colors.dart';
import '../services/room_service.dart';

class ServerSettingsPage extends StatefulWidget {
  const ServerSettingsPage({super.key});

  @override
  State<ServerSettingsPage> createState() => _ServerSettingsPageState();
}

class _ServerSettingsPageState extends State<ServerSettingsPage> {
  final TextEditingController _serverUrlController = TextEditingController();
  String _currentServerUrl = RoomService.baseUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentServerUrl = RoomService.baseUrl;
    _serverUrlController.text = _currentServerUrl;
  }

  @override
  void didUpdateWidget(covariant ServerSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _currentServerUrl = RoomService.baseUrl;
    _serverUrlController.text = _currentServerUrl;
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveServerUrl() async {
    final newUrl = _serverUrlController.text.trim();
    if (newUrl.isEmpty) {
      _showError('服务器地址不能为空');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    print('=== 服务器设置页面：开始保存 ===');
    print('新地址: $newUrl');
    
    // 保存到RoomService（会自动保存到本地存储）
    RoomService.baseUrl = newUrl;
    
    // 等待一小段时间确保保存完成
    await Future.delayed(const Duration(milliseconds: 500));
    
    print('=== 服务器设置页面：保存完成 ===');

    setState(() {
      _isSaving = false;
      _currentServerUrl = newUrl;
    });

    if (mounted) {
      // 显示重启提示对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('服务器地址已更新'),
          content: const Text('服务器地址已更改，需要重启应用才能生效。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('稍后重启'),
            ),
            ElevatedButton(
              onPressed: () {
                // 退出应用，用户需要手动重新打开
                Navigator.pop(context);
                Navigator.pop(context);
                // 退出应用
                SystemNavigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RoomColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('立即重启'),
            ),
          ],
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: RoomColors.occupied,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoomColors.background,
      appBar: AppBar(
        backgroundColor: RoomColors.cardBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '服务器设置',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: RoomColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: RoomColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前服务器地址
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RoomColors.cardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前服务器地址',
                    style: TextStyle(
                      fontSize: 13,
                      color: RoomColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.dns_outlined,
                        size: 20,
                        color: RoomColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentServerUrl,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: RoomColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 输入新地址
            Text(
              '修改服务器地址',
              style: TextStyle(
                fontSize: 13,
                color: RoomColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: RoomColors.cardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _serverUrlController,
                decoration: InputDecoration(
                  hintText: '请输入服务器地址',
                  hintStyle: TextStyle(color: RoomColors.textSecondary),
                  prefixIcon: Icon(Icons.link, color: RoomColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: TextStyle(color: RoomColors.textPrimary),
                keyboardType: TextInputType.url,
              ),
            ),
            const SizedBox(height: 24),
            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveServerUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoomColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '保存',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // 提示信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RoomColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: RoomColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '修改服务器地址后，应用将使用新的地址进行数据请求。请确保地址正确且可访问。',
                      style: TextStyle(
                        fontSize: 12,
                        color: RoomColors.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
