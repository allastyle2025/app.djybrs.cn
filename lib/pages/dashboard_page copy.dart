import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/about_dialog.dart';
import '../components/menu_section.dart';
import '../components/room_app_bar.dart';
import '../components/room_bottom_nav.dart';
import '../room_colors.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';
import '../theme_manager.dart';
import '../theme_provider.dart';
import '../components/developing_dialog.dart';
import '../components/user_profile_dialog.dart';
import 'appearance_settings_page.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'room/check_in_registration_page.dart';
import 'room/current_check_ins_page.dart';
import 'room/room_grid_page.dart';
import 'room/room_list_page.dart';
import 'server_settings_page.dart';
import 'tools_page.dart';
import 'user_management_page.dart';
import 'volunteer_application_page.dart';

// 保持页面状态的包装器
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  int _themeVersion = 0; // 用于强制重建子页面
  final PageController _pageController = PageController();
  bool _enableTabSwipe = false; // 是否启用Tab左右滑动
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();
  final GlobalKey<RoomGridPageState> _roomGridKey = GlobalKey<RoomGridPageState>();
  final GlobalKey<ToolsPageState> _toolsKey = GlobalKey<ToolsPageState>();

  final List<String> _titles = ['首页', '房间', '工具', '我的'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableTabSwipe = prefs.getBool('enableTabSwipe') ?? false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // 直接跳转，不使用滑动动画
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  IconData _getThemeIcon() {
    return switch (ThemeManager.currentTheme) {
      AppTheme.day => Icons.wb_sunny_outlined,
      AppTheme.night => Icons.dark_mode_outlined,
      AppTheme.eyeCare => Icons.remove_red_eye_outlined,
      AppTheme.temple => Icons.temple_buddhist_outlined,
    };
  }

  Future<void> _toggleTheme() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currentTheme = ThemeManager.currentTheme;
    
    // 四个主题循环切换：day -> night -> eyeCare -> temple -> day
    final newTheme = switch (currentTheme) {
      AppTheme.day => AppTheme.night,
      AppTheme.night => AppTheme.eyeCare,
      AppTheme.eyeCare => AppTheme.temple,
      AppTheme.temple => AppTheme.day,
    };
    await themeProvider.setTheme(newTheme);
    
    // 显示切换提示
    final themeName = switch (newTheme) {
      AppTheme.day => '日间模式',
      AppTheme.night => '夜间模式',
      AppTheme.eyeCare => '护眼模式',
      AppTheme.temple => '寺院风格',
    };
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已切换至$themeName'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    // 强制重建以应用新主题
    setState(() {
      _themeVersion++;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _logout() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: RoomColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '确认退出',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: RoomColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '确定要退出登录吗？',
                  style: TextStyle(
                    fontSize: 14,
                    color: RoomColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RoomColors.background,
                          foregroundColor: RoomColors.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: RoomColors.divider),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          AuthService.logout();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RoomColors.occupied,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('确定'),
                      ),
                    ),
                  ],
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: RoomColors.background,
        appBar: RoomAppBar(
          title: _titles[_currentIndex],
          actions: _buildActions(),
        ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: _enableTabSwipe
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        allowImplicitScrolling: _enableTabSwipe,
        children: [
          KeepAliveWrapper(child: HomePage(
            key: _homeKey,
            onDataChanged: () {
              // 首页数据变更时刷新Grid
              _roomGridKey.currentState?.refreshRooms();
            },
          )),
          KeepAliveWrapper(child: RoomGridPage(
            key: _roomGridKey,
            onDataChanged: () {
              // Grid页面数据变更时刷新首页
              _homeKey.currentState?.refreshData();
            },
          )),
          KeepAliveWrapper(child: ToolsPage(key: _toolsKey)),
          KeepAliveWrapper(child: _buildProfilePage()),
        ],
      ),
      bottomNavigationBar: RoomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
      ),
    );
  }

  /// 处理返回键 - 显示确认退出对话框
  Future<bool> _onWillPop() async {
    // 显示确认对话框
    final shouldExit = await showDialog<bool>(
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
                Icon(
                  Icons.exit_to_app,
                  size: 48,
                  color: RoomColors.occupied,
                ),
                const SizedBox(height: 16),
                Text(
                  '确认退出',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: RoomColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '确定要退出应用吗？',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: RoomColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RoomColors.textSecondary,
                          side: BorderSide(color: RoomColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RoomColors.occupied,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('退出'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return shouldExit ?? false;
  }

  List<Widget>? _buildActions() {
    if (_currentIndex == 0) {
      // 首页 - 显示主题切换按钮（搜索按钮暂时隐藏）
      return [
        // 搜索按钮（暂时隐藏）
        // IconButton(
        //   icon: Icon(Icons.search, color: RoomColors.textPrimary),
        //   onPressed: () {
        //     // 搜索功能
        //   },
        // ),
        IconButton(
          icon: Icon(
            _getThemeIcon(),
            color: RoomColors.textPrimary,
          ),
          onPressed: () {
            _toggleTheme();
          },
        ),
      ];
    } else if (_currentIndex == 1) {
      // 房间页面 - 显示刷新按钮
      return [
        IconButton(
          icon: Icon(Icons.refresh, color: RoomColors.textPrimary),
          onPressed: () {
            _roomGridKey.currentState?.refreshRooms();
          },
        ),
      ];
    } else if (_currentIndex == 2) {
      // 工具页面 - 显示刷新按钮（设置按钮暂时隐藏）
      return [
        IconButton(
          icon: Icon(Icons.refresh, color: RoomColors.textPrimary),
          onPressed: () {
            _toolsKey.currentState?.refreshSettings();
          },
        ),
        // 设置按钮（暂时隐藏）
        // IconButton(
        //   icon: Icon(Icons.settings_outlined, color: RoomColors.textPrimary),
        //   onPressed: () {
        //     // 设置功能
        //   },
        // ),
      ];
    }
    return null;
  }

  Widget _buildProfilePage() {
    final user = AuthService.currentUser;

    return SingleChildScrollView(
      child: Column(
        children: [
          // 用户信息卡片
          GestureDetector(
            onTap: () => UserProfileDialog.show(context, user: user),
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RoomColors.cardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: RoomColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        user?.userName.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: RoomColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.nickName ?? user?.userName ?? '用户',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: RoomColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.role == 'admin' ? '管理员' : '普通用户',
                          style: TextStyle(
                            fontSize: 13,
                            color: RoomColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: RoomColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // 主题切换
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RoomColors.cardBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '主题',
                  style: TextStyle(
                    fontSize: 13,
                    color: RoomColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildThemeIcon(Icons.wb_sunny, AppTheme.day, '日间'),
                    _buildThemeIcon(Icons.nights_stay, AppTheme.night, '夜间'),
                    _buildThemeIcon(Icons.visibility, AppTheme.eyeCare, '护眼'),
                    _buildThemeIcon(Icons.temple_buddhist, AppTheme.temple, '寺院'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 服务器设置
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: RoomColors.cardBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(Icons.dns_outlined, color: RoomColors.primary),
              title: Text(
                '服务器设置',
                style: TextStyle(
                  fontSize: 15,
                  color: RoomColors.textPrimary,
                ),
              ),
              subtitle: Text(
                RoomService.baseUrl,
                style: TextStyle(
                  fontSize: 12,
                  color: RoomColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: RoomColors.textSecondary,
                size: 20,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ServerSettingsPage()),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // 功能列表
          MenuSection(
            title: '通用',
            items: [
              MenuItem(
                icon: Icons.notifications_outlined,
                title: '消息通知',
                onTap: () => DevelopingDialog.show(context, featureName: '消息通知'),
              ),
              MenuItem(
                icon: Icons.language_outlined,
                title: '语言',
                onTap: () => DevelopingDialog.show(context, featureName: '语言设置'),
              ),
              MenuItem(
                icon: Icons.palette_outlined,
                title: '外观设置',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AppearanceSettingsPage()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          MenuSection(
            title: '账号与安全',
            items: [
              MenuItem(
                icon: Icons.lock_outline,
                title: '修改密码',
                onTap: () => DevelopingDialog.show(context, featureName: '修改密码'),
              ),
              MenuItem(
                icon: Icons.privacy_tip_outlined,
                title: '隐私设置',
                onTap: () => DevelopingDialog.show(context, featureName: '隐私设置'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          MenuSection(
            title: '关于',
            items: [
              MenuItem(
                icon: Icons.help_outline,
                title: '帮助中心',
                onTap: () => DevelopingDialog.show(context, featureName: '帮助中心'),
              ),
              MenuItem(
                icon: Icons.feedback_outlined,
                title: '意见反馈',
                onTap: () => DevelopingDialog.show(context, featureName: '意见反馈'),
              ),
              MenuItem(
                icon: Icons.info_outline,
                title: '关于我们',
                onTap: () {
                  _showAboutDialog();
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 退出登录
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: RoomColors.cardBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: RoomColors.occupied),
              title: Text(
                '退出登录',
                style: TextStyle(color: RoomColors.occupied),
              ),
              onTap: _logout,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: RoomColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeIcon(IconData icon, AppTheme theme, String label) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isSelected = themeProvider.currentTheme == theme;
    return GestureDetector(
      onTap: () {
        themeProvider.setTheme(theme);
        setState(() {
          _themeVersion++;
        });
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? RoomColors.primary : RoomColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? RoomColors.primary : RoomColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : RoomColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? RoomColors.primary : RoomColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    AppAboutDialog.show(context);
  }
}
