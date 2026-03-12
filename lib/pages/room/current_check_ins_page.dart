import 'dart:async';
import 'package:flutter/material.dart';
import '../../components/change_room_sheet.dart';
import '../../components/check_in_detail_sheet.dart';
import '../../models/room_check_in.dart';
import '../../room_colors.dart';
import '../../services/room_service.dart';
import '../../services/room_data_notifier.dart';

class CurrentCheckInsPage extends StatefulWidget {
  final VoidCallback? onDataChanged;
  
  const CurrentCheckInsPage({super.key, this.onDataChanged});

  @override
  State<CurrentCheckInsPage> createState() => _CurrentCheckInsPageState();
}

class _CurrentCheckInsPageState extends State<CurrentCheckInsPage> {
  List<RoomCheckIn> _checkIns = [];
  List<RoomCheckIn> _filteredCheckIns = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late StreamSubscription<void> _dataChangeSubscription;

  // 分类
  final List<String> _categories = ['待审', '义工', '学修', '常住', '师父', '其它'];
  String _selectedCategory = '待审';

  //头像显示变量
  bool _showAvatar = false; // false = 隐藏, true = 显示

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // 订阅数据变更通知
    _dataChangeSubscription = RoomDataNotifier().onDataChanged.listen((_) {
      print('=== CurrentCheckInsPage: 收到数据变更通知，重新加载数据 ===');
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dataChangeSubscription.cancel();
    super.dispose();
  }

  void _filterCheckIns(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredCheckIns = _checkIns.where((checkIn) {
        // 分类过滤
        if (_selectedCategory == '待审') {
          // 待审：过滤 PENDING 状态
          if (checkIn.status != 'PENDING') return false;
        } else {
          // 其他分类：过滤 purpose 字段，并只显示 CHECKED_IN 状态
          if (checkIn.status != 'CHECKED_IN') return false;
          final purpose = checkIn.purpose ?? '';
          String category = _mapPurposeToCategory(purpose);
          if (category != _selectedCategory) return false;
        }
        
        // 搜索过滤
        if (checkIn.cname.toLowerCase().contains(lowerQuery)) return true;
        if (checkIn.cphone.toLowerCase().contains(lowerQuery)) return true;
        if (checkIn.userId.toString().contains(lowerQuery)) return true;
        if (checkIn.remark?.toLowerCase().contains(lowerQuery) ?? false) return true;
        return false;
      }).toList();
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filterCheckIns(_searchController.text);
    });
  }

  // 将 purpose 映射到分类名称
  String _mapPurposeToCategory(String purpose) {
    switch (purpose) {
      case 'volunteer':
        return '义工';
      case 'study':
        return '学修';
      case 'permanent':
        return '常住';
      case 'master':
        return '师父';
      case 'other':
        return '其它';
      default:
        return purpose;
    }
  }

  // 计算每个分类的数量
  int _getCategoryCount(String category) {
    if (category == '待审') {
      return _checkIns.where((checkIn) => checkIn.status == 'PENDING').length;
    }
    return _checkIns.where((checkIn) {
      if (checkIn.status != 'CHECKED_IN') return false;
      final purpose = checkIn.purpose ?? '';
      return _mapPurposeToCategory(purpose) == category;
    }).length;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await RoomService.getCurrentCheckIns();

    setState(() {
      _isLoading = false;
      if (response.isSuccess) {
        _checkIns = response.data;
        _filterCheckIns(_searchController.text);
      } else {
        _errorMessage = response.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoomColors.background,
      appBar: AppBar(
        backgroundColor: RoomColors.cardBg,
        elevation: 0,
        iconTheme: IconThemeData(color: RoomColors.textPrimary),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '搜索姓名、电话、身份证、备注',
                  hintStyle: TextStyle(color: RoomColors.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(color: RoomColors.textPrimary, fontSize: 16),
                onChanged: _filterCheckIns,
              )
            : Text(
                '在寺人员',
                style: TextStyle(
                  color: RoomColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _filterCheckIns('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: RoomColors.primary))
            : _errorMessage.isNotEmpty
            ? _buildErrorView()
            : Row(
                children: [
                  // 左侧分类菜单
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    margin: const EdgeInsets.only(left: 4, top: 6, bottom: 6),
                    decoration: BoxDecoration(
                      color: RoomColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        final count = _getCategoryCount(category);
                        final categoryColor = _getCategoryColor(category, isSelected);
                        return GestureDetector(
                          onTap: () => _filterByCategory(category),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? categoryColor.withOpacity(0.1) : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 选中指示器
                                if (isSelected)
                                  Container(
                                    width: 3,
                                    height: 36,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: categoryColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  )
                                else
                                  const SizedBox(width: 11),
                                // 分类名称和数量
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 分类名称（在上面）
                                      Text(
                                        category,
                                        style: TextStyle(
                                          color: isSelected ? categoryColor : RoomColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      // 数量（在下面）
                                      Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isSelected ? categoryColor : RoomColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // 右侧内容区域
                  Expanded(
                    child: _filteredCheckIns.isEmpty
                        ? _buildEmptyView()
                        : _buildListView(),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getCategoryColor(String category, bool isSelected) {
    switch (category) {
      case '待审':
        return Colors.red;
      case '义工':
        return Colors.orange;
      default:
        return Colors.indigo;
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: RoomColors.occupied),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(color: RoomColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: RoomColors.divider),
          const SizedBox(height: 16),
          Text(
            '暂无在寺人员',
            style: TextStyle(color: RoomColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    // 先过滤掉已退房和已拒绝的记录
    final activeCheckIns = _filteredCheckIns.where((checkIn) {
      return checkIn.status == 'CHECKED_IN' || checkIn.status == 'PENDING';
    }).toList();
    
    // 按入住时间倒序排序，最新入住的排在前面
    final sortedCheckIns = List<RoomCheckIn>.from(activeCheckIns)
      ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

    return RefreshIndicator(
      onRefresh: _loadData,
      color: RoomColors.primary,
      displacement: 60,
      strokeWidth: 2.5,
      child: ListView.builder(
        padding: const EdgeInsets.all(4),
        itemCount: sortedCheckIns.length,
        itemBuilder: (context, index) {
          final checkIn = sortedCheckIns[index];
          // 编号从大到小（最新的编号最大）
          final displayIndex = sortedCheckIns.length - index;
          return _buildCheckInItem(checkIn, displayIndex);
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'CHECKED_IN':
        return RoomColors.available;
      case 'CHECKED_OUT':
        return RoomColors.textSecondary;
      case 'REJECTED':
        return RoomColors.occupied;
      default:
        return RoomColors.textSecondary;
    }
  }

  Widget _buildCheckInItem(RoomCheckIn checkIn, int index) {
    // 计算已入住时间显示
    final stayTimeText = _calculateStayDays(checkIn.checkInTime);

    return GestureDetector(
      onTap: () => _showCheckInDetail(checkIn),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
        decoration: BoxDecoration(
          color: RoomColors.cardBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 使用条件判断控制头像显示
                      if (_showAvatar) ...[
                        // 头像（性别图标）
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: checkIn.genderColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Icon(
                              checkIn.cgender == 'male'
                                  ? Icons.person
                                  : Icons.person,
                              size: 28,
                              color: checkIn.genderColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 姓名、性别标签
                            Row(
                              children: [
                                // 姓名
                            Text(
                              checkIn.cname,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: RoomColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 性别标签
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: checkIn.genderColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    checkIn.cgender == 'male'
                                        ? Icons.male
                                        : Icons.female,
                                    size: 12,
                                    color: checkIn.genderColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    checkIn.genderDisplayName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: checkIn.genderColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  // 年龄
                                  if (checkIn.cage != null) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '${checkIn.cage}岁',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: RoomColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // 手机号
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: RoomColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  checkIn.cphone,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: RoomColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 占位，给右上角标签留空间
                      const SizedBox(width: 50),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 底部信息栏
                  Row(
                    children: [
                      // 区域-房间号
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: RoomColors.background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 12,
                              color: RoomColors.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${checkIn.areaDisplayName}-${checkIn.roomNumber}',
                              style: TextStyle(
                                fontSize: 11,
                                color: RoomColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 状态标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(checkIn.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          checkIn.statusDisplayName,
                          style: TextStyle(
                            fontSize: 11,
                            color: _getStatusColor(checkIn.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // 备注 Badge（如果有）
                      if (checkIn.remark != null && checkIn.remark!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.note_outlined,
                                size: 11,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '注',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // 已入住天数标签 - 右上角（使用编号原来的样式）
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RoomColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stayTimeText,
                  style: TextStyle(
                    fontSize: 11,
                    color: RoomColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // 编号标签 - 右下角（使用天数原来的样式）
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RoomColors.textGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'No.$index',
                  style: TextStyle(fontSize: 11, color: RoomColors.textGrey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  void _showCheckInDetail(RoomCheckIn checkIn) async {
    // 获取历史入住记录
    final historyResponse = await RoomService.getUserCheckInHistory(checkIn.userId);
    
    if (!mounted) return;
    
    CheckInDetailSheet.show(
      context: context,
      checkIn: checkIn,
      historyCheckIns: historyResponse.data,
      showCheckOutButton: true,
      showChangeRoomButton: true,
      onCheckOut: () => _showCheckOutConfirmDialog(context, checkIn),
      onChangeRoom: () => _showChangeRoomSheet(checkIn),
      onPurposeUpdated: () => _loadData(), // 身份更新后刷新列表
      onRoomChanged: () {
        // 房间更换后重新加载该入住信息
        _loadData();
      },
    );
  }

  void _showChangeRoomSheet(RoomCheckIn checkIn) {
    ChangeRoomSheet.show(
      context: context,
      checkIn: checkIn,
      onRoomChanged: () {
        _loadData(); // 刷新列表
        // 发送全局数据变更通知
        RoomDataNotifier().notifyDataChanged();
      },
    );
  }

  // 显示退房确认对话框
  void _showCheckOutConfirmDialog(BuildContext context, RoomCheckIn checkIn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退房'),
        content: Text('确定要为 ${checkIn.cname} 办理退房吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _checkOut(checkIn);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RoomColors.occupied,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认退房'),
          ),
        ],
      ),
    );
  }

  // 执行退房
  Future<void> _checkOut(RoomCheckIn checkIn) async {
    final response = await RoomService.checkOut(checkIn.id);

    if (response.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${checkIn.cname} 退房成功'),
            backgroundColor: RoomColors.available,
          ),
        );
        _loadData(); // 刷新列表
        // 发送全局数据变更通知
        RoomDataNotifier().notifyDataChanged();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('退房失败: ${response.message}'),
            backgroundColor: RoomColors.occupied,
          ),
        );
      }
    }
  }

  // 计算入住天数
  String _calculateStayDays(DateTime checkInTime) {
    final now = DateTime.now();
    final difference = now.difference(checkInTime);
    
    final seconds = difference.inSeconds;
    final minutes = difference.inMinutes;
    final hours = difference.inHours;
    final days = difference.inDays;
    
    if (seconds < 60) {
      return '${seconds}秒前';
    } else if (minutes < 60) {
      return '${minutes}分前';
    } else if (hours < 24) {
      return '${hours}小时前';
    } else if (days == 1) {
      return '1天';
    } else {
      return '$days天';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label：',
            style: TextStyle(
              fontSize: 14,
              color: RoomColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: RoomColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRemarks(RoomCheckIn checkIn) {
    return FutureBuilder<CheckInHistoryResponse>(
      future: RoomService.getUserCheckInHistory(checkIn.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: RoomColors.occupied,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '加载失败',
                    style: TextStyle(
                      fontSize: 14,
                      color: RoomColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 过滤掉还在入住中的记录（checkOutTime为null）
        final historyList = snapshot.data?.data
                .where((h) => h.checkOutTime != null)
                .toList() ??
            [];

        if (historyList.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 48,
                    color: RoomColors.divider,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '暂无历史入住记录',
                    style: TextStyle(
                      fontSize: 14,
                      color: RoomColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: historyList.map((history) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RoomColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: RoomColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        history.checkInTime.toString().substring(0, 10),
                        style: TextStyle(
                          fontSize: 12,
                          color: RoomColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: history.status == 'CHECKED_OUT'
                              ? RoomColors.textSecondary.withOpacity(0.1)
                              : RoomColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          history.statusDisplayName,
                          style: TextStyle(
                            fontSize: 11,
                            color: history.status == 'CHECKED_OUT'
                                ? RoomColors.textSecondary
                                : RoomColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${history.areaDisplayName}${history.roomNumber}号房${history.bedNumber}床',
                          style: TextStyle(
                            fontSize: 13,
                            color: RoomColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: RoomColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '入住${history.stayDays}天',
                          style: TextStyle(
                            fontSize: 11,
                            color: RoomColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (history.checkOutTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '退房: ${history.checkOutTime.toString().substring(0, 10)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: RoomColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // 备注 Tab 内容
  Widget _buildRemarksTab(RoomCheckIn checkIn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 当前备注
        if (checkIn.remark != null && checkIn.remark!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RoomColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RoomColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 16,
                      color: RoomColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '当前备注',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: RoomColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  checkIn.remark!,
                  style: TextStyle(
                    fontSize: 14,
                    color: RoomColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 48,
                    color: RoomColors.divider,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '暂无备注',
                    style: TextStyle(
                      fontSize: 14,
                      color: RoomColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
