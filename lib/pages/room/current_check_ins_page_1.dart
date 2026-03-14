import 'dart:async';
import 'package:flutter/material.dart';
import '../../components/change_room_sheet.dart';
import '../../components/check_in_detail_sheet.dart';
import '../../components/pending_check_in_detail_sheet.dart';
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
  
  // 侧边栏控制
  bool _isSidebarExpanded = true; // true: 展开显示文字, false: 折叠只显示图标
  final double _expandedWidth = 240;
  final double _collapsedWidth = 72;

  // 分类
  final List<CategoryItem> _categories = [
    CategoryItem(id: 'pending', name: '待审', icon: Icons.pending_actions, color: Colors.red),
    CategoryItem(id: 'volunteer', name: '义工', icon: Icons.volunteer_activism, color: Colors.orange),
    CategoryItem(id: 'study', name: '学修', icon: Icons.school, color: Colors.blue),
    CategoryItem(id: 'permanent', name: '常住', icon: Icons.home, color: Colors.green),
    CategoryItem(id: 'master', name: '师父', icon: Icons.person, color: Colors.purple),
    CategoryItem(id: 'other', name: '其它', icon: Icons.more_horiz, color: Colors.grey),
  ];
  
  String _selectedCategoryId = 'pending';

  @override
  void initState() {
    super.initState();
    _loadData();
    
    _dataChangeSubscription = RoomDataNotifier().onDataChanged.listen((_) {
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
        final selectedCategory = _categories.firstWhere((c) => c.id == _selectedCategoryId);
        if (selectedCategory.id == 'pending') {
          if (checkIn.status != 'PENDING') return false;
        } else {
          if (checkIn.status != 'CHECKED_IN') return false;
          final purpose = checkIn.purpose ?? '';
          String categoryId = _mapPurposeToCategoryId(purpose);
          if (categoryId != selectedCategory.id) return false;
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

  void _filterByCategory(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _filterCheckIns(_searchController.text);
    });
  }

  String _mapPurposeToCategoryId(String purpose) {
    switch (purpose) {
      case 'volunteer': return 'volunteer';
      case 'study': return 'study';
      case 'permanent': return 'permanent';
      case 'master': return 'master';
      case 'other': return 'other';
      default: return 'other';
    }
  }

  int _getCategoryCount(String categoryId) {
    if (categoryId == 'pending') {
      return _checkIns.where((checkIn) => checkIn.status == 'PENDING').length;
    }
    return _checkIns.where((checkIn) {
      if (checkIn.status != 'CHECKED_IN') return false;
      final purpose = checkIn.purpose ?? '';
      return _mapPurposeToCategoryId(purpose) == categoryId;
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
        elevation: 0.5,
        iconTheme: IconThemeData(color: RoomColors.textPrimary),
        leading: IconButton(
          icon: Icon(_isSidebarExpanded ? Icons.menu_open : Icons.menu),
          onPressed: () {
            setState(() {
              _isSidebarExpanded = !_isSidebarExpanded;
            });
          },
        ),
        title: _isSearching
            ? _buildSearchField()
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
        child: Row(
          children: [
            // 左侧可折叠侧边栏
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              width: _isSidebarExpanded ? _expandedWidth : _collapsedWidth,
              child: _buildCategorySidebar(),
            ),
            
            // 右侧内容区域
            Expanded(
              child: _isLoading
                  ? _buildLoadingView()
                  : _errorMessage.isNotEmpty
                  ? _buildErrorView()
                  : _filteredCheckIns.isEmpty
                  ? _buildEmptyView()
                  : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySidebar() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: RoomColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类标题（展开时显示）
          if (_isSidebarExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                '分类',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: RoomColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            const SizedBox(height: 16),
          
          // 分类列表
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: _isSidebarExpanded ? 8 : 4,
                vertical: 8,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryItem(_categories[index]);
              },
            ),
          ),
          
          // 底部折叠/展开提示（可选）
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarExpanded ? 16 : 8,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: RoomColors.divider.withOpacity(0.3)),
              ),
            ),
            child: _isSidebarExpanded
                ? Row(
                    children: [
                      Icon(Icons.keyboard_double_arrow_left, size: 16, color: RoomColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        '折叠侧边栏',
                        style: TextStyle(
                          fontSize: 12,
                          color: RoomColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      Icons.keyboard_double_arrow_right,
                      size: 16,
                      color: RoomColors.textSecondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategoryItem category) {
    final isSelected = _selectedCategoryId == category.id;
    final count = _getCategoryCount(category.id);
    
    return _isSidebarExpanded
        ? _buildExpandedCategoryItem(category, isSelected, count)
        : _buildCollapsedCategoryItem(category, isSelected, count);
  }

  Widget _buildExpandedCategoryItem(CategoryItem category, bool isSelected, int count) {
    return GestureDetector(
      onTap: () => _filterByCategory(category.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? category.color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: category.color.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            // 图标
            Icon(
              category.icon,
              size: 20,
              color: isSelected ? category.color : RoomColors.textSecondary,
            ),
            const SizedBox(width: 12),
            // 分类名称
            Expanded(
              child: Text(
                category.name,
                style: TextStyle(
                  color: isSelected ? category.color : RoomColors.textSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            // 数量徽章
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected 
                  ? category.color.withOpacity(0.2)
                  : RoomColors.divider.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? category.color : RoomColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedCategoryItem(CategoryItem category, bool isSelected, int count) {
    return GestureDetector(
      onTap: () => _filterByCategory(category.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? category.color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: category.color.withOpacity(0.3))
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 图标居中
            Center(
              child: Icon(
                category.icon,
                size: 24,
                color: isSelected ? category.color : RoomColors.textSecondary,
              ),
            ),
            // 徽章 - 右上角
            if (count > 0)
              Positioned(
                top: -4,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: RoomColors.cardBg, width: 2),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: RoomColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '搜索姓名、电话、身份证、备注',
          hintStyle: TextStyle(color: RoomColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18, color: RoomColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    _filterCheckIns('');
                  },
                )
              : null,
        ),
        style: TextStyle(color: RoomColors.textPrimary, fontSize: 14),
        onChanged: _filterCheckIns,
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(RoomColors.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '加载中...',
            style: TextStyle(color: RoomColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: RoomColors.divider.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 40,
              color: RoomColors.divider,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无在寺人员',
            style: TextStyle(
              color: RoomColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击刷新按钮更新数据',
            style: TextStyle(
              color: RoomColors.textSecondary.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: RoomColors.occupied.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: RoomColors.occupied,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              color: RoomColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              color: RoomColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RoomColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final sortedCheckIns = List<RoomCheckIn>.from(_filteredCheckIns)
      ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

    return RefreshIndicator(
      onRefresh: _loadData,
      color: RoomColors.primary,
      backgroundColor: RoomColors.cardBg,
      displacement: 40,
      strokeWidth: 2.5,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: sortedCheckIns.length,
        itemBuilder: (context, index) {
          final checkIn = sortedCheckIns[index];
          final selectedCategory = _categories.firstWhere((c) => c.id == _selectedCategoryId);
          return selectedCategory.id == 'pending'
              ? _buildPendingCheckInItem(checkIn, index)
              : _buildCheckInItem(checkIn, index);
        },
      ),
    );
  }

  Widget _buildCheckInItem(RoomCheckIn checkIn, int index) {
    final stayTimeText = _calculateStayDays(checkIn.checkInTime);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: RoomColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: RoomColors.divider.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _showCheckInDetail(checkIn),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：姓名、性别、入住时间
              Row(
                children: [
                  // 姓名
                  Text(
                    checkIn.cname,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: RoomColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 性别标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: checkIn.genderColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          checkIn.cgender == 'male' ? Icons.male : Icons.female,
                          size: 12,
                          color: checkIn.genderColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          checkIn.genderDisplayName,
                          style: TextStyle(
                            fontSize: 11,
                            color: checkIn.genderColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // 入住时间
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: RoomColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
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
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 第二行：手机号
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: RoomColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    checkIn.cphone,
                    style: TextStyle(
                      fontSize: 13,
                      color: RoomColors.textSecondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 第三行：标签区域
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // 区域-房间号
                  _buildTag(
                    icon: Icons.meeting_room_outlined,
                    label: '${checkIn.areaDisplayName}-${checkIn.roomNumber}',
                    color: RoomColors.textSecondary,
                    backgroundColor: RoomColors.background,
                  ),
                  // 身份标签
                  if (checkIn.purpose != null && checkIn.purpose!.isNotEmpty)
                    _buildTag(
                      label: _getPurposeDisplayName(checkIn.purpose!),
                      color: _getPurposeColor(checkIn.purpose!),
                      backgroundColor: _getPurposeColor(checkIn.purpose!).withOpacity(0.1),
                    ),
                  // 备注标签
                  if (checkIn.remark != null && checkIn.remark!.isNotEmpty)
                    _buildTag(
                      icon: Icons.note_outlined,
                      label: '备注',
                      color: Colors.orange.shade600,
                      backgroundColor: Colors.orange.withOpacity(0.1),
                    ),
                  // 床号标签
                  _buildTag(
                    label: 'No.${checkIn.bedNumber}',
                    color: RoomColors.textGrey,
                    backgroundColor: RoomColors.textGrey.withOpacity(0.1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingCheckInItem(RoomCheckIn checkIn, int index) {
    final stayTimeText = _calculateStayDays(checkIn.checkInTime);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: RoomColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade100.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: () => _showPendingCheckInDetail(checkIn),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：姓名、待审标签、入住时间
              Row(
                children: [
                  Text(
                    checkIn.cname,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: RoomColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 待审标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pending_outlined, size: 12, color: Colors.red.shade400),
                        const SizedBox(width: 4),
                        Text(
                          '待审核',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // 入住时间
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      stayTimeText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 第二行：手机号
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: RoomColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    checkIn.cphone,
                    style: TextStyle(
                      fontSize: 13,
                      color: RoomColors.textSecondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 第三行：标签区域
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // 区域-房间号
                  _buildTag(
                    icon: Icons.meeting_room_outlined,
                    label: '${checkIn.areaDisplayName}-${checkIn.roomNumber}',
                    color: RoomColors.textSecondary,
                    backgroundColor: RoomColors.background,
                  ),
                  // 身份标签
                  if (checkIn.purpose != null && checkIn.purpose!.isNotEmpty)
                    _buildTag(
                      label: _getPurposeDisplayName(checkIn.purpose!),
                      color: _getPurposeColor(checkIn.purpose!),
                      backgroundColor: _getPurposeColor(checkIn.purpose!).withOpacity(0.1),
                    ),
                  // 备注标签
                  if (checkIn.remark != null && checkIn.remark!.isNotEmpty)
                    _buildTag(
                      icon: Icons.note_outlined,
                      label: '备注',
                      color: Colors.orange.shade600,
                      backgroundColor: Colors.orange.withOpacity(0.1),
                    ),
                  // 床号标签
                  _buildTag(
                    label: 'No.${checkIn.bedNumber}',
                    color: RoomColors.textGrey,
                    backgroundColor: RoomColors.textGrey.withOpacity(0.1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    IconData? icon,
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateStayDays(DateTime checkInTime) {
    final now = DateTime.now();
    final difference = now.difference(checkInTime);
    
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    
    if (days == 0) {
      return '$hours小时前';
    } else if (days == 1) {
      return '昨天';
    } else if (days < 30) {
      return '$days天前';
    } else {
      final months = (days / 30).floor();
      return '$months个月前';
    }
  }

  Color _getPurposeColor(String? purpose) {
    switch (purpose) {
      case 'volunteer': return Colors.orange.shade400;
      case 'study': return Colors.blue.shade400;
      case 'permanent': return Colors.green.shade400;
      case 'master': return Colors.purple.shade400;
      case 'other': return Colors.grey.shade500;
      default: return RoomColors.textSecondary;
    }
  }

  String _getPurposeDisplayName(String? purpose) {
    switch (purpose) {
      case 'volunteer': return '义工';
      case 'study': return '学修';
      case 'permanent': return '常住';
      case 'master': return '师父';
      case 'other': return '其它';
      default: return purpose ?? '未知';
    }
  }

  void _showPendingCheckInDetail(RoomCheckIn checkIn) {
    PendingCheckInDetailSheet.show(
      context: context,
      checkIn: checkIn,
      onApproved: () => _loadData(),
      onRejected: () => _loadData(),
    );
  }

  void _showCheckInDetail(RoomCheckIn checkIn) async {
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
      onPurposeUpdated: () => _loadData(),
      onRoomChanged: () => _loadData(),
    );
  }

  void _showChangeRoomSheet(RoomCheckIn checkIn) {
    ChangeRoomSheet.show(
      context: context,
      checkIn: checkIn,
      onRoomChanged: () {
        _loadData();
        RoomDataNotifier().notifyDataChanged();
      },
    );
  }

  void _showCheckOutConfirmDialog(BuildContext context, RoomCheckIn checkIn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退房'),
        content: Text('确定要为 ${checkIn.cname} 办理退房吗？'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: RoomColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _checkOut(checkIn);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RoomColors.occupied,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('确认退房'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkOut(RoomCheckIn checkIn) async {
    final response = await RoomService.checkOut(checkIn.id);

    if (response.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${checkIn.cname} 退房成功'),
            backgroundColor: RoomColors.available,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadData();
        RoomDataNotifier().notifyDataChanged();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('退房失败: ${response.message}'),
            backgroundColor: RoomColors.occupied,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

// 分类数据模型
class CategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}