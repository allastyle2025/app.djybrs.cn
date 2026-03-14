import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/about_dialog.dart';
import '../components/menu_section.dart';
import '../components/room_app_bar.dart';
import '../components/room_bottom_nav.dart';
import '../models/message.dart';
import '../room_colors.dart';
import '../services/auth_service.dart';
import '../services/local_message_service.dart';
import '../services/notification_display_service.dart';
import '../services/notification_service.dart';
import '../services/room_service.dart';
import '../theme_manager.dart';
import '../theme_provider.dart';
import '../components/developing_dialog.dart';
import '../components/user_profile_dialog.dart';
import 'appearance_settings_page.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'message_page.dart';
import 'room/check_in_registration_page.dart';
import 'room/current_check_ins_page.dart';
import 'room/room_grid_page.dart';
import 'room/room_list_page.dart';
import 'server_settings_page.dart';
import 'tab_settings_page.dart';
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

// 全局状态引用，用于子页面刷新badge
_DashboardPageState? _dashboardState;

/// 获取Dashboard状态，用于子页面刷新badge
_DashboardPageState? get dashboardState => _dashboardState;

/// 全局刷新消息badge的Stream
final StreamController<void> _badgeRefreshController = StreamController<void>.broadcast();
Stream<void> get badgeRefreshStream => _badgeRefreshController.stream;

/// 触发刷新消息badge
void refreshBadge() {
  _badgeRefreshController.add(null);
}

/// 全局刷新人员badge的Stream
final StreamController<void> _personnelBadgeRefreshController = StreamController<void>.broadcast();
Stream<void> get personnelBadgeRefreshStream => _personnelBadgeRefreshController.stream;

/// 触发刷新人员badge
void refreshPersonnelBadge() {
  _personnelBadgeRefreshController.add(null);
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  int _themeVersion = 0; // 用于强制重建子页面
  final PageController _pageController = PageController();
  bool _enableTabSwipe = false; // 是否启用Tab左右滑动
  bool _showMessageTab = false; // 是否显示消息tab（默认隐藏）
  bool _showHomeTab = true; // 是否显示首页tab
  bool _showPersonnelTab = true; // 是否显示人员tab
  bool _showRoomTab = false; // 是否显示房间tab
  bool _showToolsTab = true; // 是否显示工具tab
  bool _showProfileTab = true; // 是否显示我的tab
  int _messageBadgeCount = 0; // 消息tab的未读数量
  int _personnelBadgeCount = 0; // 人员tab的待审核数量
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();
  
  // SSE 通知服务
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<bool>? _connectionStatusSubscription;
  
  // 系统通知显示服务
  final NotificationDisplayService _notificationDisplayService = NotificationDisplayService();
  final GlobalKey<CurrentCheckInsPageState> _currentKey = GlobalKey<CurrentCheckInsPageState>();
  final GlobalKey<RoomGridPageState> _roomGridKey = GlobalKey<RoomGridPageState>();
  final GlobalKey<ToolsPageState> _toolsKey = GlobalKey<ToolsPageState>();
  final GlobalKey<MessagePageState> _messageKey = GlobalKey<MessagePageState>();

  // 页面标题根据当前导航生成
  String _getTitle(int index) {
    final visibleTabs = _getVisibleTabs();
    final tabNames = ['消息', '首页', '人员', '房间', '工具', '我的'];
    final tabKeys = ['message', 'home', 'personnel', 'room', 'tools', 'profile'];
    
    // 获取当前可见tab的索引
    int visibleIndex = 0;
    for (int i = 0; i < tabKeys.length; i++) {
      if (visibleTabs[tabKeys[i]] == true) {
        if (visibleIndex == index) {
          return tabNames[i];
        }
        visibleIndex++;
      }
    }
    return '未知';
  }

  // 获取可见tab的映射
  Map<String, bool> _getVisibleTabs() {
    return {
      'message': _showMessageTab,
      'home': _showHomeTab,
      'personnel': _showPersonnelTab,
      'room': _showRoomTab,
      'tools': _showToolsTab,
      'profile': _showProfileTab,
    };
  }

  // 获取可见tab的数量
  int _getVisibleTabCount() {
    return _getVisibleTabs().values.where((visible) => visible).length;
  }

  // 根据可见索引获取页面列表中的实际索引
  int _getActualPageIndex(int visibleIndex) {
    // 页面列表和导航栏的顺序是一致的，所以直接返回visibleIndex
    return visibleIndex;
  }

  // 根据页面列表中的实际索引获取可见索引
  int _getVisibleIndex(int actualIndex) {
    // 页面列表和导航栏的顺序是一致的，所以直接返回actualIndex
    return actualIndex;
  }

  // 判断是否应该隐藏AppBar
  // 人员页和消息页有自己的AppBar，需要隐藏dashboard的AppBar
  bool _shouldHideAppBar(int visibleIndex) {
    final visibleTabs = _getVisibleTabs();
    final tabKeys = ['message', 'home', 'personnel', 'room', 'tools', 'profile'];
    
    // 找到当前可见索引对应的实际tab
    int currentVisibleIndex = 0;
    for (int i = 0; i < tabKeys.length; i++) {
      if (visibleTabs[tabKeys[i]] == true) {
        if (currentVisibleIndex == visibleIndex) {
          // 如果是人员页或消息页，隐藏AppBar
          return tabKeys[i] == 'personnel' || tabKeys[i] == 'message';
        }
        currentVisibleIndex++;
      }
    }
    return false;
  }

  @override
  StreamSubscription<void>? _badgeRefreshSubscription;
  StreamSubscription<void>? _personnelBadgeRefreshSubscription;

  void initState() {
    super.initState();
    _dashboardState = this;
    _loadSettings();
    _loadUnreadCount();
    _loadPendingCount();
    
    // 监听全局刷新消息badge事件
    _badgeRefreshSubscription = _badgeRefreshController.stream.listen((_) {
      print('🔄 Dashboard 收到刷新消息 badge 事件');
      _loadUnreadCount();
    });
    
    // 监听全局刷新人员badge事件
    _personnelBadgeRefreshSubscription = _personnelBadgeRefreshController.stream.listen((_) {
      print('🔄 Dashboard 收到刷新人员 badge 事件');
      _loadPendingCount();
    });
    
    // 初始化 SSE 连接（无论消息Tab是否显示，都要连接SSE）
    _initNotificationService();
    
    // 初始化系统通知服务
    _notificationDisplayService.initialize();
  }
  
  /// 初始化 SSE 通知服务
  void _initNotificationService() {
    print('📡 Dashboard 初始化 SSE 连接');
    
    // 监听连接状态
    _connectionStatusSubscription = _notificationService.connectionStatusStream.listen((connected) {
      print('📡 Dashboard SSE 连接状态: $connected');
    });
    
    // 监听新消息
    _messageSubscription = _notificationService.messageStream.listen(
      (newMessage) async {
        print('收到消息: ${newMessage.content}');

        // 保存消息到本地
        await LocalMessageService.saveMessage(newMessage);
        await LocalMessageService.saveChatMessage(newMessage.assistantId, newMessage);

        // 刷新消息badge
        _loadUnreadCount();

        // 显示系统通知（即使应用在后台也能收到）
        await _notificationDisplayService.showMessageNotification(newMessage);

        // 如果是入住登记消息，刷新人员页面
        if (newMessage.type == 'room_checkin') {
          print('🏨 Dashboard 收到入住登记消息，刷新人员页面');
          _currentKey.currentState?.refreshData();
          _loadPendingCount();
        }
      },
      onError: (error) {
        print('📨 Dashboard SSE 错误: $error');
      },
    );
    
    // 连接 SSE
    _notificationService.connect();
  }

  // 加载未读消息数量
  Future<void> _loadUnreadCount() async {
    final count = await LocalMessageService.getTotalUnreadCount();
    setState(() {
      _messageBadgeCount = count;
    });
  }

  // 加载待审核人员数量
  Future<void> _loadPendingCount() async {
    try {
      final response = await RoomService.getCurrentCheckIns();
      if (response.isSuccess && response.data != null) {
        final pendingCount = response.data!.where((checkIn) => checkIn.status == 'PENDING').length;
        setState(() {
          _personnelBadgeCount = pendingCount;
        });
        print('👥 Dashboard 待审核数量: $pendingCount');
      }
    } catch (e) {
      print('❌ 加载待审核数量失败: $e');
    }
  }

  // 刷新未读消息数量（供外部调用）
  void refreshUnreadCount() {
    _loadUnreadCount();
  }
  
  // 刷新待审核数量（供外部调用）
  void refreshPendingCount() {
    _loadPendingCount();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableTabSwipe = prefs.getBool('enableTabSwipe') ?? false;
      _showMessageTab = prefs.getBool('showMessageTab') ?? false;
      _showHomeTab = prefs.getBool('showHomeTab') ?? true;
      _showPersonnelTab = prefs.getBool('showPersonnelTab') ?? true;
      _showRoomTab = prefs.getBool('showRoomTab') ?? false;
      _showToolsTab = prefs.getBool('showToolsTab') ?? true;
      _showProfileTab = prefs.getBool('showProfileTab') ?? true;
    });
  }

  // 构建页面列表
  List<Widget> _buildPageList() {
    final List<Widget> pages = [];
    
    if (_showMessageTab) {
      pages.add(KeepAliveWrapper(child: MessagePage(key: _messageKey)));
    }
    
    if (_showHomeTab) {
      pages.add(KeepAliveWrapper(child: HomePage(
        key: _homeKey,
        onDataChanged: () {
          // 首页数据变更时刷新人员和房间
          _currentKey.currentState?.refreshData();
          _roomGridKey.currentState?.refreshRooms();
        },
      )));
    }
    
    if (_showPersonnelTab) {
      pages.add(KeepAliveWrapper(child: CurrentCheckInsPage(
        key: _currentKey,
        onDataChanged: () {
          _homeKey.currentState?.refreshData();
        },
      )));
    }
    
    if (_showRoomTab) {
      pages.add(KeepAliveWrapper(child: RoomGridPage(
        key: _roomGridKey,
        onDataChanged: () {
          _homeKey.currentState?.refreshData();
        },
      )));
    }
    
    if (_showToolsTab) {
      pages.add(KeepAliveWrapper(child: ToolsPage(key: _toolsKey)));
    }
    
    if (_showProfileTab) {
      pages.add(KeepAliveWrapper(child: _buildProfilePage()));
    }
    
    return pages;
  }

  // 处理导航点击
  void _onItemTapped(int visibleIndex) {
    final actualIndex = _getActualPageIndex(visibleIndex);
    setState(() {
      _currentIndex = visibleIndex;
    });
    // 直接跳转，不使用滑动动画
    _pageController.jumpToPage(actualIndex);
    
    // 如果切换到消息页面，刷新未读数量；切换到人员页面，刷新待审核数量
    final visibleTabs = _getVisibleTabs();
    final tabKeys = ['message', 'home', 'personnel', 'room', 'tools', 'profile'];
    int currentVisibleIndex = 0;
    for (int i = 0; i < tabKeys.length; i++) {
      if (visibleTabs[tabKeys[i]] == true) {
        if (currentVisibleIndex == visibleIndex) {
          if (tabKeys[i] == 'message') {
            // 切换到消息页面，延迟刷新未读数量
            Future.delayed(const Duration(milliseconds: 500), () {
              _loadUnreadCount();
            });
          } else if (tabKeys[i] == 'personnel') {
            // 切换到人员页面，重置分类到待审核并刷新数据
            Future.delayed(const Duration(milliseconds: 100), () {
              _currentKey.currentState?.resetToPendingCategory();
              _loadPendingCount();
            });
          }
          break;
        }
        currentVisibleIndex++;
      }
    }
  }

  // 处理页面切换
  void _onPageChanged(int actualIndex) {
    final visibleIndex = _getVisibleIndex(actualIndex);
    setState(() {
      _currentIndex = visibleIndex;
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
    _dashboardState = null;
    _badgeRefreshSubscription?.cancel();
    _personnelBadgeRefreshSubscription?.cancel();
    _messageSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    _notificationService.dispose();
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
        appBar: _shouldHideAppBar(_currentIndex)
            ? null
            : RoomAppBar(
                title: _getTitle(_currentIndex),
                actions: _buildActions(),
              ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: _enableTabSwipe
            ? const ClampingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        allowImplicitScrolling: _enableTabSwipe,
        children: _buildPageList(),
      ),
      bottomNavigationBar: RoomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        showMessage: _showMessageTab,
        showHome: _showHomeTab,
        showPersonnel: _showPersonnelTab,
        showRoom: _showRoomTab,
        showTools: _showToolsTab,
        showProfile: _showProfileTab,
        messageBadgeCount: _messageBadgeCount,
        personnelBadgeCount: _personnelBadgeCount,
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
    // 获取当前可见的tab列表
    final visibleTabs = _getVisibleTabs();
    final tabKeys = ['message', 'home', 'personnel', 'room', 'tools', 'profile'];
    
    // 找到当前索引对应的tab类型
    String currentTab = '';
    int visibleIndex = 0;
    for (int i = 0; i < tabKeys.length; i++) {
      if (visibleTabs[tabKeys[i]] == true) {
        if (visibleIndex == _currentIndex) {
          currentTab = tabKeys[i];
          break;
        }
        visibleIndex++;
      }
    }
    
    switch (currentTab) {
      case 'home':
        // 首页 - 显示主题切换按钮
        return [
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
      case 'personnel':
        // 当前人员页
        return [
          IconButton(
            icon: Icon(Icons.refresh, color: RoomColors.textPrimary),
            onPressed: () {
              _currentKey.currentState?.refreshData();
            },
          ),
        ];
      case 'room':
        // 房间页
        return [
          IconButton(
            icon: Icon(Icons.refresh, color: RoomColors.textPrimary),
            onPressed: () {
              _roomGridKey.currentState?.refreshRooms();
            },
          ),
        ];
      case 'tools':
        // 工具页
        return [
          IconButton(
            icon: Icon(Icons.refresh, color: RoomColors.textPrimary),
            onPressed: () {
              _toolsKey.currentState?.refreshSettings();
            },
          ),
        ];
      default:
        return null;
    }
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
              MenuItem(
                icon: Icons.tab_outlined,
                title: 'Tab显示设置',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TabSettingsPage()),
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
