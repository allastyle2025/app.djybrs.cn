import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../room_colors.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  // 控制是否显示房间ID
  bool _showRoomId = false;
  // 控制是否启用Tab左右滑动
  bool _enableTabSwipe = false;
  // 控制是否显示义工申请表入口
  bool _showVolunteerApplication = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 从本地存储加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showRoomId = prefs.getBool('showRoomId') ?? false;
      _enableTabSwipe = prefs.getBool('enableTabSwipe') ?? false;
      _showVolunteerApplication = prefs.getBool('showVolunteerApplication') ?? false;
    });
  }

  // 保存设置到本地存储
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showRoomId', _showRoomId);
    await prefs.setBool('enableTabSwipe', _enableTabSwipe);
    await prefs.setBool('showVolunteerApplication', _showVolunteerApplication);
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: value ? RoomColors.primary.withOpacity(0.05) : RoomColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value ? RoomColors.primary.withOpacity(0.2) : RoomColors.divider,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: value
                          ? [RoomColors.primary.withOpacity(0.15), RoomColors.primary.withOpacity(0.05)]
                          : [RoomColors.divider.withOpacity(0.5), RoomColors.divider.withOpacity(0.2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: value ? RoomColors.primary : RoomColors.textGrey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: RoomColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: RoomColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: value ? RoomColors.primary : RoomColors.divider,
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          '外观设置',
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
            // 房间网格设置
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
                    '房间网格设置',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: RoomColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 显示房间ID开关
                  _buildSwitchTile(
                    icon: Icons.tag,
                    title: '显示房间ID',
                    subtitle: '在房间卡片上显示房间编号',
                    value: _showRoomId,
                    onChanged: (value) {
                      setState(() {
                        _showRoomId = value;
                        _saveSettings();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 导航设置
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RoomColors.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '导航设置',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: RoomColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tab左右滑动开关
                  _buildSwitchTile(
                    icon: Icons.swipe,
                    title: 'Tab左右滑动切换',
                    subtitle: '启用底部导航栏左右滑动切换页面',
                    value: _enableTabSwipe,
                    onChanged: (value) {
                      setState(() {
                        _enableTabSwipe = value;
                        _saveSettings();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 功能入口设置
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RoomColors.cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '功能入口设置',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: RoomColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 显示义工申请表入口开关
                  _buildSwitchTile(
                    icon: Icons.volunteer_activism_outlined,
                    title: '显示义工申请表入口',
                    subtitle: '在工具页面显示义工申请表快捷入口',
                    value: _showVolunteerApplication,
                    onChanged: (value) {
                      setState(() {
                        _showVolunteerApplication = value;
                        _saveSettings();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                      '修改外观设置后，会立即应用到相关页面。',
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
