import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../components/change_room_sheet.dart';
import '../../components/check_in_detail_sheet.dart';
import '../../components/room_detail_sheet.dart';
import '../../room_colors.dart';
import '../../models/room.dart';
import '../../models/room_check_in.dart';
import '../../services/room_service.dart';
import '../../services/room_data_notifier.dart';
import '../../theme_manager.dart';

class RoomGridPage extends StatefulWidget {
  final String? initialArea;
  final VoidCallback? onDataChanged;
  
  const RoomGridPage({super.key, this.initialArea, this.onDataChanged});

  @override
  State<RoomGridPage> createState() => RoomGridPageState();
}

class RoomGridPageState extends State<RoomGridPage> {
  List<Room> _rooms = [];
  List<Room> _filteredRooms = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _filterArea = 'all'; // 默认显示全部区域
  String _filterGender = 'all'; // 默认显示全部性别
  bool _showRoomId = false; // 控制是否显示房间ID
  StreamSubscription<void>? _dataChangeSubscription;

  @override
  void initState() {
    super.initState();
    // 如果有传入初始区域，则使用
    if (widget.initialArea != null) {
      _filterArea = widget.initialArea!;
    }
    _loadRooms();
    _loadSettings();
    
    // 监听数据变更通知
    print('=== RoomGridPage: 开始监听数据变更通知 ===');
    _dataChangeSubscription = RoomDataNotifier().onDataChanged.listen((_) {
      print('=== RoomGridPage: 收到数据变更通知，开始刷新 ===');
      _loadRooms();
    });
    print('=== RoomGridPage: 监听设置完成 ===');
  }
  
  @override
  void dispose() {
    _dataChangeSubscription?.cancel();
    super.dispose();
  }

  // 从本地存储加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final newShowRoomId = prefs.getBool('showRoomId') ?? false;
    // 只在值变化时才 setState，避免不必要的重建
    if (newShowRoomId != _showRoomId) {
      setState(() {
        _showRoomId = newShowRoomId;
      });
    }
  }

  Future<void> _loadRooms() async {
    print('=== _loadRooms 开始加载房间数据 ===');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await RoomService.getRooms();
    print('=== _loadRooms 请求完成，是否成功: ${response.isSuccess} ===');

    if (response.isSuccess) {
      setState(() {
        _rooms = response.data;
        _applyFilters();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response.message;
        _isLoading = false;
      });
    }
  }

  // 公共刷新方法，供外部调用
  Future<void> refreshRooms() async {
    await _loadRooms();
  }

  void _applyFilters() {
    _filteredRooms = _rooms.where((room) {
      if (_filterArea != 'all' && room.roomArea != _filterArea) return false;
      if (_filterGender != 'all' && room.roomGender != _filterGender) return false;
      return true;
    }).toList();

    // 按房间号排序（数字部分升序）
    _filteredRooms.sort((a, b) {
      // 提取房间号中的数字部分
      final aNum = int.tryParse(a.roomNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final bNum = int.tryParse(b.roomNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return aNum.compareTo(bNum);
    });

    // 按入住人数从多到少排序（已注释掉）
    // _filteredRooms.sort((a, b) => b.occupiedBeds.compareTo(a.occupiedBeds));
  }

  void _onFilterAreaChanged(String area) {
    setState(() {
      _filterArea = area;
      _applyFilters();
    });
  }

  void _onFilterGenderChanged(String gender) {
    setState(() {
      // 如果点击的是当前选中的，则取消筛选显示全部
      if (_filterGender == gender) {
        _filterGender = 'all';
      } else {
        _filterGender = gender;
      }
      _applyFilters();
    });
  }

  // 获取该区男众入住人数
  int get _maleOccupiedCount => _rooms
      .where((r) => r.roomGender == 'male' && (_filterArea == 'all' || r.roomArea == _filterArea))
      .fold(0, (sum, r) => sum + r.occupiedBeds);
  
  // 获取该区女众入住人数
  int get _femaleOccupiedCount => _rooms
      .where((r) => r.roomGender == 'female' && (_filterArea == 'all' || r.roomArea == _filterArea))
      .fold(0, (sum, r) => sum + r.occupiedBeds);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoomColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // 房间网格 - 占满全屏，在筛选区下方滚动
            _isLoading
                ? Center(child: CircularProgressIndicator(color: RoomColors.primary))
                : _errorMessage.isNotEmpty
                    ? _buildErrorView(_errorMessage, _loadRooms)
                    : _buildRoomGrid(),
            // 区域和性别筛选 - 悬浮在顶部
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: RoomColors.cardBg.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: RoomColors.divider.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildAreaFilter(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildGenderTabs(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 区域筛选下拉菜单
            if (_isAreaDropdownOpen)
              Stack(
                children: [
                  // 点击外部关闭下拉菜单
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isAreaDropdownOpen = false;
                      });
                    },
                    child: Container(
                      color: Colors.transparent,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                    ),
                  ),
                  // 下拉菜单内容
                  Positioned(
                    top: 64,
                    left: 12,
                    width: MediaQuery.of(context).size.width * 0.33 - 18,
                    child: Container(
                      decoration: BoxDecoration(
                        color: RoomColors.cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: RoomColors.divider,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ...AreaConfig.allAreas.map((area) => _buildDropdownItem(area.name, area.code)),
                          _buildDropdownItem('全部', 'all'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownItem(String label, String areaCode) {
    final isSelected = _filterArea == areaCode;
    return GestureDetector(
      onTap: () {
        _onFilterAreaChanged(areaCode);
        _isAreaDropdownOpen = false;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? RoomColors.primary.withOpacity(0.1) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: RoomColors.divider,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? RoomColors.primary : RoomColors.textPrimary,
                fontSize: 14,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: RoomColors.primary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderTabs() {
    final maleCount = _maleOccupiedCount;
    final femaleCount = _femaleOccupiedCount;
    
    List<Widget> tabs = [];
    
    // 总是显示男众和女众标签
    tabs.add(_buildGenderTab('男众', 'male', maleCount));
    tabs.add(_buildGenderTab('女众', 'female', femaleCount));

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: RoomColors.tabBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: tabs.map((tab) => Expanded(child: tab)).toList(),
      ),
    );
  }

  Widget _buildGenderTab(String label, String gender, int count) {
    final isSelected = _filterGender == gender;
    // 男众使用亮蓝色，女众使用亮粉色
    final genderColor = gender == 'male' ? const Color(0xff42A5F5) : const Color.fromARGB(255, 255, 107, 164);
    return GestureDetector(
      onTap: () => _onFilterGenderChanged(gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? genderColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: genderColor.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$label($count)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : RoomColors.tabNormal,
            ),
          ),
        ),
      ),
    );
  }

  bool _isAreaDropdownOpen = false;

  void _toggleAreaDropdown() {
    setState(() {
      _isAreaDropdownOpen = !_isAreaDropdownOpen;
    });
  }

  Widget _buildAreaFilter() {
    final areas = AreaConfig.allAreas;
    final currentAreaName = _filterArea == 'all' ? '全部' : AreaConfig.getAreaName(_filterArea);
    
    return GestureDetector(
      onTap: () {
        print('Area filter tapped');
        setState(() {
          _isAreaDropdownOpen = !_isAreaDropdownOpen;
          print('Dropdown open: $_isAreaDropdownOpen');
        });
      },
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: RoomColors.cardBg.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: RoomColors.divider.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      currentAreaName,
                      style: TextStyle(
                        color: RoomColors.textPrimary,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isAreaDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: RoomColors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomGrid() {
    if (_filteredRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room_outlined, size: 64, color: RoomColors.divider),
            const SizedBox(height: 16),
            Text(
              '暂无房间',
              style: TextStyle(color: RoomColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRooms,
      color: RoomColors.primary,
      displacement: 60,
      strokeWidth: 2.5,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 88, 12, 12), // 顶部留出更多空间，避免被筛选区遮挡
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _filteredRooms.length,
        itemBuilder: (context, index) {
          final room = _filteredRooms[index];
          return _buildRoomCard(room);
        },
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    final areaName = AreaConfig.getAreaName(room.roomArea);
    final isFull = room.isFull;
    final isEmpty = room.isEmpty;
    
    // 根据主题设置顶部边框颜色：日间白色，夜间使用divider
    final topBorderColor = ThemeManager.currentTheme == AppTheme.day 
        ? Colors.white 
        : RoomColors.divider;

    return GestureDetector(
      onTap: () => _showRoomDetail(room),
      child: Container(
        decoration: BoxDecoration(
          color: RoomColors.cardBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态指示条 - 日间白色，夜间使用divider颜色
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: topBorderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 房间号
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                room.roomNumber,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: RoomColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // 状态标签：维护中 > 满 > 地铺
                            if (room.status == 'maintenance')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: RoomColors.partial,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  '维',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            else if (isFull)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: RoomColors.occupied,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  '满',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            else if (room.roomFloorMattress > 0)
                              Icon(
                                Icons.layers_outlined,
                                size: 14,
                                color: RoomColors.textSecondary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // 区域
                        Text(
                          areaName,
                          style: TextStyle(
                            fontSize: 11,
                            color: RoomColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // 床位方格图
                        _buildBedGrid(room),
                        const Spacer(),
                        // 床位状态
                        Row(
                          children: [
                            Icon(
                              Icons.bed_outlined,
                              size: 14,
                              color: room.genderColor.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${room.occupiedBeds}/${room.totalCapacity}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: RoomColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // 房间ID（右下角）
                    if (_showRoomId) // 根据设置显示或隐藏房间ID
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Text(
                          '#${room.id}',
                          style: TextStyle(
                            fontSize: 10,
                            color: RoomColors.textSecondary.withOpacity(0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomDetail(Room room) {
    final areaName = AreaConfig.getAreaName(room.roomArea);
    // 根据房间性别获取颜色
    Color genderColor;
    if (room.roomGender == 'male') {
      genderColor = const Color(0xff42A5F5);  // 男众亮蓝色
    } else if (room.roomGender == 'female') {
      genderColor = const Color.fromARGB(255, 255, 107, 164);  // 女众亮粉色
    } else {
      genderColor = Colors.indigo;  // 外住区域使用靛蓝色
    }

    RoomDetailSheet.show(
      context: context,
      room: room,
      areaName: areaName,
      genderColor: genderColor,
      onRoomChanged: () {
        _loadRooms(); // 刷新 Grid
        widget.onDataChanged?.call(); // 通知首页刷新
      },
    );
  }

  // 构建床位方格图（用于房间卡片）
  Widget _buildBedGrid(Room room) {
    final totalBeds = room.totalCapacity;
    final occupiedBeds = room.occupiedBeds;

    // 限制最大显示数量，最多6列4行，共24个
    const maxBedsToShow = 24;
    final bedsToShow = totalBeds > maxBedsToShow ? maxBedsToShow : totalBeds;

    // 正方形大小
    const squareSize = 8.0;
    const spacing = 1.0;

    // 根据房间性别获取颜色
    Color genderColor;
    if (room.roomGender == 'male') {
      genderColor = const Color(0xff42A5F5);  // 男众亮蓝色
    } else if (room.roomGender == 'female') {
      genderColor = const Color.fromARGB(255, 255, 107, 164);  // 女众亮粉色
    } else {
      genderColor = Colors.indigo;  // 外住区域使用靛蓝色
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(bedsToShow, (index) {
          final isOccupied = index < occupiedBeds;
          return Container(
            width: squareSize,
            height: squareSize,
            decoration: BoxDecoration(
              color: isOccupied ? genderColor : RoomColors.divider, // 已占用床位使用性别颜色，空闲床位使用灰色
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }

  // 构建错误视图
  Widget _buildErrorView(String errorMessage, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: RoomColors.occupied),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: TextStyle(color: RoomColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
