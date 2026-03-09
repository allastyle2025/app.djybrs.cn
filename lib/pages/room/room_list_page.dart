import 'package:flutter/material.dart';
import '../../components/room_list_card.dart';
import '../../models/room.dart';
import '../../room_colors.dart';
import '../../services/room_service.dart';

class RoomListPage extends StatefulWidget {
  final String? initialArea;
  
  const RoomListPage({super.key, this.initialArea});

  @override
  State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  List<Room> _rooms = [];
  List<Room> _filteredRooms = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _filterStatus = 'all';
  String _filterArea = 'all';
  String _filterGender = 'male';

  @override
  void initState() {
    super.initState();
    _filterArea = widget.initialArea ?? 'all';
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await RoomService.getRooms();

    if (response.isSuccess) {
      setState(() {
        _rooms = response.data;
        _applyFilters();
        _autoSwitchGenderTab();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response.message;
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredRooms = _rooms.where((room) {
      // 状态筛选
      if (_filterStatus == 'full' && !room.isFull) return false;
      if (_filterStatus == 'empty' && !room.isEmpty) return false;
      if (_filterStatus == 'partial' && (room.isFull || room.isEmpty)) return false;
      
      // 区域筛选
      if (_filterArea != 'all' && room.roomArea != _filterArea) return false;
      
      // 性别筛选
      if (_filterGender != 'all' && room.roomGender != _filterGender) return false;
      
      return true;
    }).toList();
  }

  void _onFilterStatusChanged(String status) {
    setState(() {
      _filterStatus = status;
      _applyFilters();
    });
  }

  void _onFilterAreaChanged(String area) {
    setState(() {
      _filterArea = area;
      _applyFilters();
    });
  }

  void _onFilterGenderChanged(String gender) {
    setState(() {
      _filterGender = gender;
      _applyFilters();
    });
  }

  // 自动切换性别Tab：如果当前选中的性别没有房间，切换到另一个性别
  void _autoSwitchGenderTab() {
    // 检查当前选中的性别是否有房间
    final currentGenderCount = _filterGender == 'male' ? _maleRoomCount : _femaleRoomCount;
    
    if (currentGenderCount == 0) {
      // 当前选中的性别没有房间，切换到另一个性别
      if (_filterGender == 'male' && _femaleRoomCount > 0) {
        _filterGender = 'female';
      } else if (_filterGender == 'female' && _maleRoomCount > 0) {
        _filterGender = 'male';
      }
      // 重新应用筛选
      _applyFilters();
    }
  }

  int get _totalRooms => _rooms.length;
  int get _occupiedBeds => _rooms.fold(0, (sum, r) => sum + r.occupiedBeds);
  int get _availableBeds => _rooms.fold(0, (sum, r) => sum + r.availableBeds);
  int get _maleRoomCount => _rooms.where((r) => r.roomGender == 'male' && (_filterArea == 'all' || r.roomArea == _filterArea)).length;
  int get _femaleRoomCount => _rooms.where((r) => r.roomGender == 'female' && (_filterArea == 'all' || r.roomArea == _filterArea)).length;

  // 获取页面标题
  String get _pageTitle {
    if (widget.initialArea != null) {
      final areaName = Room.getAreaDisplayName(widget.initialArea!);
      return '$areaName';
    }
    return '房间列表';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoomColors.background,
      appBar: AppBar(
        title: Text(_pageTitle),
        backgroundColor: RoomColors.cardBg,
        foregroundColor: RoomColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 性别 Tab 切换
            Container(
              color: RoomColors.cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: RoomColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (_maleRoomCount > 0)
                      Expanded(
                        child: _buildGenderTab('男众', 'male', _maleRoomCount),
                      ),
                    if (_femaleRoomCount > 0)
                      Expanded(
                        child: _buildGenderTab('女众', 'female', _femaleRoomCount),
                      ),
                  ],
                ),
              ),
            ),
            // 状态筛选
            Container(
              color: RoomColors.cardBg,
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: Row(
                children: [
                  _buildFilterChip('全部', 'all', _filterStatus == 'all', () => _onFilterStatusChanged('all')),
                  const SizedBox(width: 8),
                  _buildFilterChip('空房', 'empty', _filterStatus == 'empty', () => _onFilterStatusChanged('empty')),
                  const SizedBox(width: 8),
                  _buildFilterChip('部分', 'partial', _filterStatus == 'partial', () => _onFilterStatusChanged('partial')),
                  const SizedBox(width: 8),
                  _buildFilterChip('满房', 'full', _filterStatus == 'full', () => _onFilterStatusChanged('full')),
                ],
              ),
            ),
        
        const SizedBox(height: 8),
        
        // 房间列表
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: RoomColors.primary,
                  ),
                )
              : _errorMessage.isNotEmpty
                  ? _buildErrorView()
                  : _filteredRooms.isEmpty
                      ? _buildEmptyView()
                      : RefreshIndicator(
                          onRefresh: _loadRooms,
                          color: RoomColors.primary,
                          displacement: 60,
                          strokeWidth: 2.5,
                          child: ListView.builder(
                            itemCount: _filteredRooms.length,
                            padding: const EdgeInsets.only(bottom: 8),
                            itemBuilder: (context, index) {
                              return RoomListCard(
                                room: _filteredRooms[index],
                                onTap: () => _showRoomDetail(_filteredRooms[index]),
                              );
                            },
                          ),
                        ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: RoomColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: RoomColors.divider,
    );
  }

  Widget _buildFilterChip(String label, String value, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? RoomColors.primary.withOpacity(0.1) : RoomColors.background,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: RoomColors.primary, width: 1)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? RoomColors.primary : RoomColors.textGrey,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderTab(String label, String gender, int count) {
    final isSelected = _filterGender == gender;
    return GestureDetector(
      onTap: () => _onFilterGenderChanged(gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? RoomColors.primary : RoomColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color: isSelected ? RoomColors.primary.withOpacity(0.8) : RoomColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 48,
            color: RoomColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无房间数据',
            style: TextStyle(
              fontSize: 14,
              color: RoomColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadRooms,
            child: Text(
              '刷新',
              style: TextStyle(color: RoomColors.primary),
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
          Icon(
            Icons.error_outline,
            size: 48,
            color: RoomColors.occupied.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: RoomColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadRooms,
            child: Text(
              '重试',
              style: TextStyle(color: RoomColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomDetail(Room room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomDetailSheet(room: room),
    );
  }

  Color _getStatusColor(Room room) {
    if (room.isFull) return RoomColors.occupied;
    if (room.isEmpty) return RoomColors.available;
    return RoomColors.partial;
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: RoomColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: RoomColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// 房间详情抽屉
class RoomDetailSheet extends StatelessWidget {
  final Room room;

  const RoomDetailSheet({Key? key, required this.room}) : super(key: key);

  Color get _statusColor {
    if (room.isFull) return RoomColors.occupied;
    if (room.isEmpty) return RoomColors.available;
    return RoomColors.partial;
  }

  String get _statusText {
    if (room.isFull) return '已满';
    if (room.isEmpty) return '空房';
    return '部分入住';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 拖动条
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: RoomColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '${room.areaDisplayName}-${room.roomNumber}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: RoomColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: RoomColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // 信息卡片
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoCard('区域', room.areaDisplayName),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard('性别', room.genderDisplayName),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoCard('床位数', '${room.roomBeds}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard('地铺数', '${room.roomFloorMattress}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 床位列表标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '床位状态',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: RoomColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${room.occupiedBeds}/${room.totalCapacity} 已入住',
                    style: TextStyle(
                      fontSize: 13,
                      color: RoomColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 床位列表 - 两列网格
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: room.totalCapacity,
                  itemBuilder: (context, index) {
                    final isBed = index < room.roomBeds;
                    final bedNumber = isBed ? index + 1 : index - room.roomBeds + 1;
                    final isOccupied = index < room.occupiedBeds;
                    
                    return _buildBedItem(
                      number: bedNumber,
                      isBed: isBed,
                      isOccupied: isOccupied,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RoomColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: RoomColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: RoomColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBedItem({
    required int number,
    required bool isBed,
    required bool isOccupied,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOccupied ? RoomColors.occupied.withOpacity(0.1) : RoomColors.available.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOccupied ? RoomColors.occupied.withOpacity(0.3) : RoomColors.available.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isOccupied ? RoomColors.occupied : RoomColors.available,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isBed ? '床位' : '地铺',
            style: TextStyle(
              fontSize: 14,
              color: RoomColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isOccupied ? RoomColors.occupied.withOpacity(0.1) : RoomColors.available.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isOccupied ? '已入住' : '空闲',
              style: TextStyle(
                fontSize: 12,
                color: isOccupied ? RoomColors.occupied : RoomColors.available,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
