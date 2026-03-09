import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/room_check_in.dart';
import '../room_colors.dart';
import '../services/room_service.dart';
import '../services/room_data_notifier.dart';

/// 更换房间底部抽屉弹窗组件
class ChangeRoomSheet extends StatefulWidget {
  final RoomCheckIn checkIn;
  final VoidCallback? onRoomChanged;

  const ChangeRoomSheet({
    super.key,
    required this.checkIn,
    this.onRoomChanged,
  });

  /// 显示更换房间弹窗
  static Future<void> show({
    required BuildContext context,
    required RoomCheckIn checkIn,
    VoidCallback? onRoomChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ChangeRoomSheet(
        checkIn: checkIn,
        onRoomChanged: onRoomChanged,
      ),
    );
  }

  @override
  State<ChangeRoomSheet> createState() => _ChangeRoomSheetState();
}

class _ChangeRoomSheetState extends State<ChangeRoomSheet> {
  List<Room> _rooms = [];
  List<Room> _filteredRooms = [];
  Map<int, Set<int>> _roomOccupiedBeds = {}; // roomId -> occupied bed numbers
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedArea = 'all';
  Room? _selectedRoom;
  int? _selectedBedNumber;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // 并行加载房间列表和入住信息
    await Future.wait([
      _loadRooms(),
      _loadOccupiedBeds(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadOccupiedBeds() async {
    try {
      final response = await RoomService.getCurrentCheckIns();
      if (response.isSuccess) {
        final checkIns = response.data;
        final occupiedBeds = <int, Set<int>>{};
        
        for (final checkIn in checkIns) {
          occupiedBeds.putIfAbsent(checkIn.roomId, () => <int>{});
          occupiedBeds[checkIn.roomId]!.add(checkIn.bedNumber);
        }
        
        setState(() {
          _roomOccupiedBeds = occupiedBeds;
        });
      }
    } catch (e) {
      print('加载入住信息失败: $e');
    }
  }

  Future<void> _loadRooms() async {
    final response = await RoomService.getRooms();

    if (response.isSuccess) {
      setState(() {
        _rooms = response.data;
        _applyFilter();
      });
    } else {
      setState(() {
        _errorMessage = response.message;
      });
    }
  }

  void _applyFilter() {
    // 筛选同性别且有空床位的房间
    _filteredRooms = _rooms.where((room) {
      // 必须是同性别
      if (room.roomGender != widget.checkIn.cgender) return false;
      // 必须有空床位
      if (room.availableBeds <= 0) return false;
      // 排除当前房间
      if (room.id == widget.checkIn.roomId) return false;
      // 区域筛选
      if (_selectedArea != 'all' && room.roomArea != _selectedArea) return false;
      return true;
    }).toList();
  }

  Future<void> _changeRoom() async {
    if (_selectedRoom == null || _selectedBedNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择房间和床位')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // 调用更换房间API
    final response = await RoomService.changeRoom(
      checkInId: widget.checkIn.id,
      newRoomId: _selectedRoom!.id,
      newBedNumber: _selectedBedNumber!,
    );

    setState(() {
      _isSubmitting = false;
    });

    print('=== ChangeRoomSheet: response.isSuccess = ${response.isSuccess} ===');
    print('=== ChangeRoomSheet: response.code = ${response.code} ===');

    if (response.isSuccess) {
      if (mounted) {
        print('=== ChangeRoomSheet: 准备关闭抽屉并发送通知 ===');
        Navigator.pop(context);
        print('=== ChangeRoomSheet: 抽屉已关闭，准备发送全局通知 ===');
        // 发送全局数据变更通知
        RoomDataNotifier().notifyDataChanged();
        print('=== ChangeRoomSheet: 全局通知发送完成 ===');
        // 调用回调（如果有）
        widget.onRoomChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更换房间成功！${_selectedRoom!.roomNumber}号房 第${_selectedBedNumber}床'),
            backgroundColor: RoomColors.available,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更换房间失败: ${response.message}'),
            backgroundColor: RoomColors.occupied,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RoomColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖动条
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: RoomColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 标题
            Row(
              children: [
                Text(
                  '更换房间',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: RoomColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('取消'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 当前入住信息
            _buildCurrentInfo(),
            const SizedBox(height: 16),
            // 区域筛选
            _buildAreaFilter(),
            const SizedBox(height: 16),
            // 房间列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage,
                                style: TextStyle(color: RoomColors.occupied),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('重试'),
                              ),
                            ],
                          ),
                        )
                      : _filteredRooms.isEmpty
                          ? Center(
                              child: Text(
                                '暂无可用房间',
                                style: TextStyle(
                                  color: RoomColors.textGrey,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredRooms.length,
                              itemBuilder: (context, index) {
                                final room = _filteredRooms[index];
                                return _buildRoomCard(room);
                              },
                            ),
            ),
            const SizedBox(height: 16),
            // 确认按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _changeRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoomColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(_isSubmitting ? '更换中...' : '确认更换'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建当前入住信息
  Widget _buildCurrentInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RoomColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RoomColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: RoomColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '当前: ${widget.checkIn.areaDisplayName} ${widget.checkIn.roomNumber}号房 第${widget.checkIn.bedNumber}床',
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

  /// 构建区域筛选
  Widget _buildAreaFilter() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildAreaChip('all', '全部'),
          ...AreaConfig.allAreas.map((area) => _buildAreaChip(area.code, area.name)),
        ],
      ),
    );
  }

  /// 构建区域芯片
  Widget _buildAreaChip(String code, String name) {
    final isSelected = _selectedArea == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedArea = code;
              _applyFilter();
              _selectedRoom = null;
              _selectedBedNumber = null;
            });
          }
        },
        selectedColor: RoomColors.primary.withOpacity(0.1),
        labelStyle: TextStyle(
          color: isSelected ? RoomColors.primary : RoomColors.textSecondary,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isSelected ? RoomColors.primary : RoomColors.divider,
          ),
        ),
      ),
    );
  }

  /// 构建房间卡片
  Widget _buildRoomCard(Room room) {
    final isSelected = _selectedRoom?.id == room.id;
    final area = AreaConfig.getByCode(room.roomArea);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? RoomColors.primary.withOpacity(0.05) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? RoomColors.primary : RoomColors.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRoom = room;
            _selectedBedNumber = null;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: area?.color.withOpacity(0.1) ?? RoomColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      area?.name ?? room.roomArea,
                      style: TextStyle(
                        fontSize: 11,
                        color: area?.color ?? RoomColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${room.roomNumber}号房',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: RoomColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: RoomColors.available.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '空${room.availableBeds}床',
                      style: TextStyle(
                        fontSize: 12,
                        color: RoomColors.available,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 床位选择
              if (isSelected) _buildBedSelection(room),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建床位选择
  Widget _buildBedSelection(Room room) {
    // 获取已占用的床位号
    final occupiedBeds = _roomOccupiedBeds[room.id] ?? <int>{};

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(room.totalCapacity, (index) {
        final bedNumber = index < room.roomBeds ? index + 1 : index - room.roomBeds + 1;
        final isOccupied = occupiedBeds.contains(bedNumber);
        final isSelected = _selectedBedNumber == bedNumber;

        return ChoiceChip(
          label: Text('第$bedNumber床'),
          selected: isSelected,
          onSelected: isOccupied
              ? null
              : (selected) {
                  setState(() {
                    _selectedBedNumber = selected ? bedNumber : null;
                  });
                },
          selectedColor: RoomColors.primary,
          labelStyle: TextStyle(
            color: isOccupied
                ? RoomColors.textGrey
                : isSelected
                    ? Colors.white
                    : RoomColors.textPrimary,
            fontSize: 12,
          ),
          backgroundColor: isOccupied ? RoomColors.divider.withOpacity(0.3) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: isOccupied
                  ? Colors.transparent
                  : isSelected
                      ? RoomColors.primary
                      : RoomColors.divider,
            ),
          ),
        );
      }),
    );
  }
}
