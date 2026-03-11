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

  /// 显示更换房间页面
  static Future<void> show({
    required BuildContext context,
    required RoomCheckIn checkIn,
    VoidCallback? onRoomChanged,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeRoomSheet(
          checkIn: checkIn,
          onRoomChanged: onRoomChanged,
        ),
      ),
    );
  }

  @override
  State<ChangeRoomSheet> createState() => _ChangeRoomSheetState();
}

class _ChangeRoomSheetState extends State<ChangeRoomSheet> {
  List<Room> _rooms = [];
  List<Room> _filteredRooms = [];
  List<String> _areas = []; // 区域名称列表
  Map<int, Set<int>> _roomOccupiedBeds = {}; // roomId -> occupied bed numbers
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedArea = '华严殿'; // 默认选择华严殿
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
        // 收集所有区域名称
        _areas = _rooms.map((r) => r.areaDisplayName).toSet().toList();
        // 确保默认区域存在
        if (_areas.isNotEmpty && !_areas.contains(_selectedArea)) {
          _selectedArea = _areas.first;
        }
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
      // 必须是同性别或外住区域
      if (room.roomGender != widget.checkIn.cgender && room.roomGender != 'other') return false;
      // 必须有空床位
      if (room.availableBeds <= 0) return false;
      // 排除当前房间
      if (room.id == widget.checkIn.roomId) return false;
      // 区域筛选
      if (room.areaDisplayName != _selectedArea) return false;
      return true;
    }).toList();
  }

  Future<void> _changeRoom() async {
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择房间')),
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
      newBedNumber: _selectedBedNumber, // 允许为null，API会自动分配
    );

    setState(() {
      _isSubmitting = false;
    });

    print('=== ChangeRoomSheet: response.isSuccess = ${response.isSuccess} ===');
    print('=== ChangeRoomSheet: response.code = ${response.code} ===');

    if (response.isSuccess) {
      if (mounted) {
        print('=== ChangeRoomSheet: 准备发送通知并关闭页面 ===');
        // 发送全局数据变更通知
        RoomDataNotifier().notifyDataChanged();
        print('=== ChangeRoomSheet: 全局通知发送完成 ===');
        // 调用回调（如果有）
        widget.onRoomChanged?.call();
        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更换房间成功！${_selectedRoom!.roomNumber}号房'),
            backgroundColor: RoomColors.available,
          ),
        );
        // 关闭页面
        print('=== ChangeRoomSheet: 关闭页面 ===');
        Navigator.pop(context);
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
    return Scaffold(
      backgroundColor: RoomColors.background,
      appBar: AppBar(
        backgroundColor: RoomColors.cardBg,
        elevation: 0,
        iconTheme: IconThemeData(color: RoomColors.textPrimary),
        title: Text(
          '更换房间',
          style: TextStyle(
            color: RoomColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 当前入住信息
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.checkIn.cgender == 'male'
                          ? const Color(0xff42A5F5).withOpacity(0.1)
                          : const Color.fromARGB(255, 255, 107, 164).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person,
                        size: 28,
                        color: widget.checkIn.cgender == 'male'
                            ? const Color(0xff42A5F5)
                            : const Color.fromARGB(255, 255, 107, 164),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.checkIn.cname,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: RoomColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.checkIn.cgender == 'male'
                                    ? const Color(0xff42A5F5).withOpacity(0.1)
                                    : const Color.fromARGB(255, 255, 107, 164).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.checkIn.cgender == 'male' ? '男' : '女',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.checkIn.cgender == 'male'
                                      ? const Color(0xff42A5F5)
                                      : const Color.fromARGB(255, 255, 107, 164),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.checkIn.cphone,
                          style: TextStyle(
                            fontSize: 13,
                            color: RoomColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '当前: ${widget.checkIn.areaDisplayName} ${widget.checkIn.roomNumber}号房 第${widget.checkIn.bedNumber}床',
                          style: TextStyle(
                            fontSize: 13,
                            color: RoomColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 区域筛选
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAreaDropdown(),
            ),
            const SizedBox(height: 16),
            // 房间列表
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: RoomColors.primary,
                      ),
                    )
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
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.5,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _filteredRooms.length,
                              itemBuilder: (context, index) {
                                final room = _filteredRooms[index];
                                return _buildRoomCard(room);
                              },
                            ),
            ),
          ],
        ),
      ),
      // 底部确认按钮
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _changeRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: RoomColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: RoomColors.divider,
              ),
              child: _isSubmitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('更换中...'),
                      ],
                    )
                  : Text(
                      _selectedRoom == null ? '请选择房间' : '确认更换',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建区域下拉选择器
  Widget _buildAreaDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: RoomColors.cardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedArea,
          isDense: true,
          icon: Icon(Icons.arrow_drop_down, color: RoomColors.textSecondary),
          style: TextStyle(
            fontSize: 14,
            color: RoomColors.textPrimary,
          ),
          items: _areas.map((area) {
            return DropdownMenuItem(
              value: area,
              child: Text(area),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedArea = value;
                _applyFilter();
                _selectedRoom = null;
                _selectedBedNumber = null;
              });
            }
          },
        ),
      ),
    );
  }

  /// 构建房间卡片
  Widget _buildRoomCard(Room room) {
    final isSelected = _selectedRoom?.id == room.id;
    // 计算已占用床位，使用totalCapacity（包含地铺）
    final totalBeds = room.totalCapacity;
    final occupiedBeds = (totalBeds - room.availableBeds).clamp(0, totalBeds);

    // 判断是否为外住区域（gender为other）
    final isOtherGender = room.roomGender == 'other';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRoom = room;
          _selectedBedNumber = null; // 自动分配床位
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? RoomColors.primary.withOpacity(0.1) : RoomColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? RoomColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  room.roomNumber,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: RoomColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    // 外住区域显示性别标识
                    if (isOtherGender)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: RoomColors.textGrey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '外',
                          style: TextStyle(
                            fontSize: 10,
                            color: RoomColors.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: room.availableBeds > 0
                            ? RoomColors.available.withOpacity(0.1)
                            : RoomColors.occupied.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        room.availableBeds > 0 ? '空闲' : '满员',
                        style: TextStyle(
                          fontSize: 11,
                          color: room.availableBeds > 0 ? RoomColors.available : RoomColors.occupied,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$occupiedBeds/$totalBeds床',
              style: TextStyle(
                fontSize: 13,
                color: RoomColors.textSecondary,
              ),
            ),
            const Spacer(),
            // 显示自动分配的床位
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: RoomColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
