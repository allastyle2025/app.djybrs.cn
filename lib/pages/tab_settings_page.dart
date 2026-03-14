import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../room_colors.dart';

class TabSettingsPage extends StatefulWidget {
  const TabSettingsPage({super.key});

  @override
  State<TabSettingsPage> createState() => _TabSettingsPageState();
}

class _TabSettingsPageState extends State<TabSettingsPage> {
  bool _showMessageTab = true;
  bool _showHomeTab = true;
  bool _showPersonnelTab = true;
  bool _showRoomTab = false;
  bool _showToolsTab = true;
  bool _showProfileTab = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showMessageTab = prefs.getBool('showMessageTab') ?? true;
      _showHomeTab = prefs.getBool('showHomeTab') ?? true;
      _showPersonnelTab = prefs.getBool('showPersonnelTab') ?? true;
      _showRoomTab = prefs.getBool('showRoomTab') ?? false;
      _showToolsTab = prefs.getBool('showToolsTab') ?? true;
      _showProfileTab = prefs.getBool('showProfileTab') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? RoomColors.primary.withOpacity(0.1) : RoomColors.divider.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? RoomColors.primary : RoomColors.textGrey,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: enabled ? RoomColors.textPrimary : RoomColors.textGrey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: enabled ? RoomColors.textSecondary : RoomColors.textGrey,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: RoomColors.primary,
      ),
      enabled: enabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoomColors.background,
      appBar: AppBar(
        title: const Text('Tab显示设置'),
        backgroundColor: RoomColors.cardBg,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('showMessageTab', true);
              await prefs.setBool('showHomeTab', true);
              await prefs.setBool('showPersonnelTab', true);
              await prefs.setBool('showRoomTab', false);
              await prefs.setBool('showToolsTab', true);
              await prefs.setBool('showProfileTab', true);
              setState(() {
                _showMessageTab = true;
                _showHomeTab = true;
                _showPersonnelTab = true;
                _showRoomTab = false;
                _showToolsTab = true;
                _showProfileTab = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('已恢复默认设置'),
                  backgroundColor: RoomColors.available,
                ),
              );
            },
            child: Text(
              '恢复默认',
              style: TextStyle(color: RoomColors.primary),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: RoomColors.primary))
          : ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '底部导航栏显示控制',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: RoomColors.textSecondary,
                    ),
                  ),
                ),
                Container(
                  color: RoomColors.cardBg,
                  child: Column(
                    children: [
                      _buildSwitchItem(
                        title: '消息',
                        subtitle: '显示消息Tab',
                        value: _showMessageTab,
                        onChanged: (value) {
                          setState(() {
                            _showMessageTab = value;
                          });
                          _saveSetting('showMessageTab', value);
                        },
                        icon: Icons.chat_bubble_outline,
                      ),
                      Divider(height: 1, indent: 56, color: RoomColors.divider.withOpacity(0.3)),
                      _buildSwitchItem(
                        title: '首页',
                        subtitle: '显示首页Tab',
                        value: _showHomeTab,
                        onChanged: (value) {
                          setState(() {
                            _showHomeTab = value;
                          });
                          _saveSetting('showHomeTab', value);
                        },
                        icon: Icons.home_outlined,
                      ),
                      Divider(height: 1, indent: 56, color: RoomColors.divider.withOpacity(0.3)),
                      _buildSwitchItem(
                        title: '人员',
                        subtitle: '显示人员Tab',
                        value: _showPersonnelTab,
                        onChanged: (value) {
                          setState(() {
                            _showPersonnelTab = value;
                          });
                          _saveSetting('showPersonnelTab', value);
                        },
                        icon: Icons.people_outline,
                      ),
                      Divider(height: 1, indent: 56, color: RoomColors.divider.withOpacity(0.3)),
                      _buildSwitchItem(
                        title: '房间',
                        subtitle: '显示房间Tab（默认关闭）',
                        value: _showRoomTab,
                        onChanged: (value) {
                          setState(() {
                            _showRoomTab = value;
                          });
                          _saveSetting('showRoomTab', value);
                        },
                        icon: Icons.meeting_room_outlined,
                      ),
                      Divider(height: 1, indent: 56, color: RoomColors.divider.withOpacity(0.3)),
                      _buildSwitchItem(
                        title: '工具',
                        subtitle: '显示工具Tab',
                        value: _showToolsTab,
                        onChanged: (value) {
                          setState(() {
                            _showToolsTab = value;
                          });
                          _saveSetting('showToolsTab', value);
                        },
                        icon: Icons.apps_outlined,
                      ),
                      Divider(height: 1, indent: 56, color: RoomColors.divider.withOpacity(0.3)),
                      _buildSwitchItem(
                        title: '我的',
                        subtitle: '显示我的Tab（建议保持开启）',
                        value: _showProfileTab,
                        onChanged: (value) {
                          setState(() {
                            _showProfileTab = value;
                          });
                          _saveSetting('showProfileTab', value);
                        },
                        icon: Icons.person_outline,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '提示：关闭所有Tab将导致导航栏为空，请至少保留一个Tab开启。修改设置后需要重启应用才能生效。',
                    style: TextStyle(
                      fontSize: 12,
                      color: RoomColors.textGrey,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}