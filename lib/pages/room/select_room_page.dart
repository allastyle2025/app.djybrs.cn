import 'package:flutter/material.dart';
import '../../room_colors.dart';
import '../../services/room_service.dart';
import '../../services/room_data_notifier.dart';
import '../../models/room.dart';
import 'check_in_registration_page.dart';

class SelectRoomPage extends StatefulWidget {
  final UserInfo user;
  final String initialGender;

  const SelectRoomPage({
    super.key,
    required this.user,
    this.initialGender = 'male',
  });

  @override
  State<SelectRoomPage> createState() => _SelectRoomPageState();
}

class _SelectRoomPageState extends State<SelectRoomPage> {
  List<Room> _rooms = [];
  List<String> _areas = [];
  String _selectedArea = '华严殿';
  late String _selectedGender;
  bool _isLoading = true;
  String _errorMessage = '';
  Room? _selectedRoom;
  int? _selectedBedNumber;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialGender;
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await RoomService.getRooms();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.isSuccess) {
          _rooms = response.data;
          _areas = _rooms.map((r) => r.areaDisplayName).toSet().toList();
          if (_areas.isNotEmpty && !_areas.contains(_selectedArea)) {
            _selectedArea = _areas.first;
          }
          // 如果没有男众房间，自动切换到女众
          final maleRooms = _getFilteredRooms('male');
          if (maleRooms.isEmpty) {
            _selectedGender = 'female';
          }
        } else {
          _errorMessage = response.message;
        }
      });
    }
  }

  List<Room> _getFilteredRooms(String gender) {
    return _rooms.where((room) {
      return room.areaDisplayName == _selectedArea &&
          room.roomGender == gender &&
          room.availableBeds > 0; // 只显示有空床位的房间
    }).toList();
  }

  List<Room> _getCurrentFilteredRooms() {
    return _getFilteredRooms(_selectedGender);
  }

  void _onRoomSelected(Room room) {
    setState(() {
      if (_selectedRoom?.id == room.id) {
        // 如果点击已选中的房间，则取消选择
        _selectedRoom = null;
        _selectedBedNumber = null;
      } else {
        _selectedRoom = room;
        // 自动分配床位：当前人数 + 1
        // 注意：availableBeds 可能包含地铺，所以用 max 确保床位号在有效范围内
        final occupiedBeds = room.roomBeds - room.availableBeds;
        _selectedBedNumber = (occupiedBeds + 1).clamp(1, room.roomBeds);
      }
    });
  }

  void _confirmCheckIn() {
    if (_selectedRoom == null || _selectedBedNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择房间和床位')),
      );
      return;
    }

    // TODO: 调用API完成入住登记
    // 显示确认对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认入住'),
        content: Text(
          '用户：${widget.user.name}\n'
          '房间：${_selectedArea}-${_selectedRoom!.roomNumber}\n'
          '床位：${_selectedBedNumber}号床',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 调用入住API
              _submitCheckIn();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RoomColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCheckIn() async {
    if (_selectedRoom == null || _selectedBedNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择房间')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await RoomService.quickCheckIn(
        userId: widget.user.id,
        roomId: _selectedRoom!.id,
        bedNumber: _selectedBedNumber!,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: RoomColors.available,
            ),
          );
          // 发送全局数据变更通知
          print('=== SelectRoomPage: 入住成功，发送全局通知 ===');
          RoomDataNotifier().notifyDataChanged();
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: RoomColors.occupied,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('入住登记失败: $e'),
            backgroundColor: RoomColors.occupied,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRooms = _getCurrentFilteredRooms();

    return Scaffold(
      backgroundColor: RoomColors.background,
      appBar: AppBar(
        backgroundColor: RoomColors.cardBg,
        elevation: 0,
        iconTheme: IconThemeData(color: RoomColors.textPrimary),
        title: Text(
          '选择房间',
          style: TextStyle(
            color: RoomColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // 用户信息卡片
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
                    color: widget.user.gender == 'male'
                        ? const Color(0xff42A5F5).withOpacity(0.1)
                        : const Color.fromARGB(255, 255, 107, 164).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 28,
                      color: widget.user.gender == 'male'
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
                            widget.user.name,
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
                              color: widget.user.gender == 'male'
                                  ? const Color(0xff42A5F5).withOpacity(0.1)
                                  : const Color.fromARGB(255, 255, 107, 164).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.user.gender == 'male' ? '男' : '女',
                              style: TextStyle(
                                fontSize: 11,
                                color: widget.user.gender == 'male'
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
                        widget.user.phone,
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
          // 筛选区域
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 区域选择
                Expanded(
                  flex: 2,
                  child: _buildAreaDropdown(),
                ),
                const SizedBox(width: 12),
                // 性别切换
                Expanded(
                  flex: 3,
                  child: _buildGenderTabs(),
                ),
              ],
            ),
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
                    ? _buildErrorView()
                    : filteredRooms.isEmpty
                        ? _buildEmptyView()
                        : _buildRoomGrid(filteredRooms),
          ),
        ],
      ),
      // 底部确认按钮
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedRoom != null && _selectedBedNumber != null)
                  ? _confirmCheckIn
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: RoomColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: RoomColors.divider,
              ),
              child: Text(
                _selectedRoom == null
                    ? '请选择房间'
                    : _selectedBedNumber == null
                        ? '请选择床位'
                        : '确认入住',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                _selectedRoom = null;
                _selectedBedNumber = null;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildGenderTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _selectedGender == 'male'
                    ? const Color(0xff42A5F5)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.male,
                    size: 16,
                    color: _selectedGender == 'male'
                        ? Colors.white
                        : const Color(0xff42A5F5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '男众(${_getFilteredRooms('male').length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _selectedGender == 'male'
                          ? Colors.white
                          : const Color(0xff42A5F5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _selectedGender == 'female'
                    ? const Color.fromARGB(255, 255, 107, 164)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.female,
                    size: 16,
                    color: _selectedGender == 'female'
                        ? Colors.white
                        : const Color.fromARGB(255, 255, 107, 164),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '女众(${_getFilteredRooms('female').length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _selectedGender == 'female'
                          ? Colors.white
                          : const Color.fromARGB(255, 255, 107, 164),
                    ),
                  ),
                ],
              ),
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
          Icon(Icons.error_outline, size: 48, color: RoomColors.occupied),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            style: TextStyle(color: RoomColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRooms,
            child: const Text('重试'),
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
          Icon(Icons.meeting_room_outlined, size: 48, color: RoomColors.divider),
          const SizedBox(height: 12),
          Text(
            '该区域暂无${_selectedGender == 'male' ? '男众' : '女众'}房间',
            style: TextStyle(color: RoomColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomGrid(List<Room> rooms) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return _buildRoomCard(room);
      },
    );
  }

  Widget _buildRoomCard(Room room) {
    final isSelected = _selectedRoom?.id == room.id;
    // 计算已占用床位，使用totalCapacity（包含地铺）
    final totalBeds = room.totalCapacity;
    final occupiedBeds = (totalBeds - room.availableBeds).clamp(0, totalBeds);

    return GestureDetector(
      onTap: () => _onRoomSelected(room),
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
