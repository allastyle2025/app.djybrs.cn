import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/cgh_user.dart';
import '../services/cgh_user_service.dart';
import '../services/auth_service.dart';
import '../room_colors.dart';
import 'login_page.dart';
import 'room/select_room_page.dart';
import 'room/check_in_registration_page.dart';

class CghUserManagementPage extends StatefulWidget {
  const CghUserManagementPage({super.key});

  @override
  State<CghUserManagementPage> createState() => _CghUserManagementPageState();
}

class _CghUserManagementPageState extends State<CghUserManagementPage> {
  List<CghUser> _users = [];
  bool _isLoading = true; // 首次进入显示加载动画
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _total = 0;
  final int _pageSize = 10;
  bool _hasMore = true;

  final TextEditingController _searchController = TextEditingController();
  String? _keyword;

  @override
  void initState() {
    super.initState();
    if (!AuthService.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      });
      return;
    }
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      _keyword = value.trim().isEmpty ? null : value.trim();
      _currentPage = 0;
      _users = [];
      _hasMore = true;
    });
    _loadUsers();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _users = [];
        _hasMore = true;
      });
    }

    // 首次加载时 _isLoading 为 true，需要允许执行
    if ((_isLoading && _users.isNotEmpty) || (_isLoadingMore && !refresh)) {
      return;
    }

    setState(() {
      if (refresh) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
      _errorMessage = null;
    });

    try {
      print('=== 开始加载人员列表 ===');
      print('页码: $_currentPage, 每页数量: $_pageSize, 关键词: $_keyword');
      
      final response = await CghUserService.getUsers(
        page: _currentPage,
        size: _pageSize,
        keyword: _keyword,
      );

      print('=== 加载人员列表成功 ===');
      print('获取到 ${response.content.length} 条记录，总计: ${response.totalElements}');
      
      setState(() {
        // 分页模式：直接替换数据，不是追加
        _users = response.content;
        _total = response.totalElements;
        _hasMore = response.content.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      print('=== 加载人员列表失败 ===');
      print('错误信息: $e');
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Widget _buildBody() {
    return Stack(
      children: [
        Column(
          children: [
            // 搜索栏
            _buildSearchBar(),
            // 统计信息
            _buildStatsBar(),
            // 内容区域
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
        // 分页按钮 - 悬浮于底部中央
        Positioned(
          left: 0,
          right: 0,
          bottom: 12,
          child: Center(
            child: _buildPagination(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: RoomColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索姓名、身份证号或手机号',
          hintStyle: TextStyle(
            fontSize: 14,
            color: RoomColors.textGrey,
          ),
          prefixIcon: Icon(Icons.search, size: 20, color: RoomColors.textGrey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18, color: RoomColors.textGrey),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: _onSearch,
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RoomColors.primary.withOpacity(0.08),
            RoomColors.primary.withOpacity(0.03),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: RoomColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people_outline,
            size: 18,
            color: RoomColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '共 $_total 条记录',
            style: TextStyle(
              fontSize: 13,
              color: RoomColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_keyword != null && _keyword!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: RoomColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 12, color: RoomColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    _keyword!,
                    style: TextStyle(
                      fontSize: 12,
                      color: RoomColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // 如果是分页加载（不是首次加载），显示列表和底部加载指示器
    if (_isLoading && _users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(RoomColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              '加载中...',
              style: TextStyle(
                fontSize: 14,
                color: RoomColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade400, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: RoomColors.textGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _keyword != null ? '未找到相关记录' : '暂无人员记录',
              style: TextStyle(
                fontSize: 16,
                color: RoomColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadUsers(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: _users.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _buildUserCard(_users[index]);
        },
      ),
    );
  }

  Widget _buildUserCard(CghUser user) {
    return Container(
      decoration: BoxDecoration(
        color: RoomColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _showUserDetail(user),
            borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // 性别图标（替代头像）
                    _buildGenderAvatar(user),
                    const SizedBox(width: 14),
                    // 信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 姓名行
                          Row(
                            children: [
                              Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: RoomColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildGenderBadge(user),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: RoomColors.textGrey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${user.calculatedAge}岁',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: RoomColors.textGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 电话
                          _buildInfoRow(
                            icon: Icons.phone_outlined,
                            text: user.formattedPhone,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 时间 - 右上角
              Positioned(
                right: 8,
                top: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 10,
                      color: RoomColors.textGrey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatRelativeTime(user.updateTime),
                      style: TextStyle(
                        fontSize: 10,
                        color: RoomColors.textGrey,
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

  Widget _buildGenderAvatar(CghUser user) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            user.genderColor.withOpacity(0.15),
            user.genderColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Icon(
            user.gender == 'male' ? Icons.male : Icons.female,
            size: 32,
            color: user.genderColor.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderBadge(CghUser user) {
    final isMale = user.gender == 'male';

    Color bgColor;
    Color textColor;
    String text;

    if (isMale) {
      bgColor = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF1976D2);
      text = '男';
    } else {
      bgColor = const Color(0xFFFCE4EC);
      textColor = const Color(0xFFC2185B);
      text = '女';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    Color? iconColor,
    Color? textColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor ?? RoomColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: textColor ?? RoomColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}周前';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}个月前';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}年前';
    }
  }

  void _showUserDetail(CghUser user) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 900,
                constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 头部
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
                      child: Stack(
                        children: [
                          // 关闭按钮
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
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
                          ),
                          // 内容
                          Column(
                            children: [
                              // 性别图标头像
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      user.genderColor.withOpacity(0.2),
                                      user.genderColor.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: Icon(
                                      user.gender == 'male' ? Icons.male : Icons.female,
                                      size: 44,
                                      color: user.genderColor.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: RoomColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.schedule_outlined,
                                    size: 14,
                                    color: RoomColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatRelativeTime(user.updateTime),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: RoomColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 内容
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailSection('基本信息', [
                              _buildDetailItem('ID', user.id.toString()),
                              _buildDetailItem('姓名', user.name),
                              _buildDetailItem('性别', user.genderDisplayName),
                              _buildDetailItem('年龄', '${user.calculatedAge}岁'),
                              _buildDetailItem('民族', user.ethnicity),
                            ]),
                            const SizedBox(height: 16),
                            _buildDetailSection('联系方式', [
                              _buildDetailItem('手机号', user.formattedPhone),
                              _buildDetailItem('地址', user.address),
                            ]),
                            const SizedBox(height: 16),
                            _buildDetailSection('证件信息', [
                              _buildDetailItem('身份证号', user.formattedIdCard),
                            ]),
                            const SizedBox(height: 16),
                            _buildDetailSection('时间信息', [
                              _buildDetailItem('创建时间', _formatDateTime(user.createTime)),
                              _buildDetailItem('更新时间', _formatDateTime(user.updateTime)),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    // 底部按钮区域
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: RoomColors.divider),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop(); // 关闭弹窗
                              final userInfo = UserInfo.fromJson(user.toUserInfoJson());
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SelectRoomPage(
                                    user: userInfo,
                                    initialGender: user.gender,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.hotel_outlined, size: 20),
                            label: const Text(
                              '登记入住',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RoomColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: RoomColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: RoomColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                RoomColors.cardBg,
                RoomColors.background.withOpacity(0.5),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RoomColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: RoomColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: RoomColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (!_hasMore) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMore
            ? CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(RoomColors.primary),
              )
            : ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentPage++;
                  });
                  _loadUsers();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoomColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('加载更多'),
              ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_users.isEmpty) return const SizedBox.shrink();
    
    final totalPages = (_total / _pageSize).ceil();
    final currentPage = _currentPage + 1;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: RoomColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadUsers();
                  }
                : null,
            icon: Icon(Icons.chevron_left, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: _currentPage > 0 ? RoomColors.primary : RoomColors.textGrey,
            ),
          ),
          Text(
            '$currentPage / $totalPages',
            style: TextStyle(
              fontSize: 13,
              color: RoomColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadUsers();
                  }
                : null,
            icon: Icon(Icons.chevron_right, size: 20),
            style: IconButton.styleFrom(
              foregroundColor: _currentPage < totalPages - 1 ? RoomColors.primary : RoomColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('人员管理'),
        backgroundColor: RoomColors.cardBg,
        elevation: 0,
        foregroundColor: RoomColors.textPrimary,
      ),
      backgroundColor: RoomColors.background,
      body: _buildBody(),
    );
  }
}