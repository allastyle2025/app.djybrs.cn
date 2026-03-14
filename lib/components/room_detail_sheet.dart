import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/room_check_in.dart';
import '../room_colors.dart';
import '../services/room_service.dart';
import '../services/room_data_notifier.dart';
import 'change_room_sheet.dart';
import 'check_in_detail_sheet.dart';

/// 房间详情底部抽屉组件
/// 显示房间信息和床位入住情况
class RoomDetailSheet extends StatelessWidget {
  final Room room;
  final String areaName;
  final Color genderColor;
  final ValueChanged<Room>? onRoomChanged;

  const RoomDetailSheet({
    super.key,
    required this.room,
    required this.areaName,
    required this.genderColor,
    this.onRoomChanged,
  });

  /// 显示房间详情底部抽屉
  static Future<void> show({
    required BuildContext context,
    required Room room,
    required String areaName,
    required Color genderColor,
    ValueChanged<Room>? onRoomChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RoomDetailSheet(
        room: room,
        areaName: areaName,
        genderColor: genderColor,
        onRoomChanged: onRoomChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _RoomDetailContent(
      room: room,
      areaName: areaName,
      genderColor: genderColor,
      onRoomChanged: onRoomChanged,
    );
  }
}

/// 房间详情内容（StatefulWidget 管理状态）
class _RoomDetailContent extends StatefulWidget {
  final Room room;
  final String areaName;
  final Color genderColor;
  final ValueChanged<Room>? onRoomChanged;

  const _RoomDetailContent({
    required this.room,
    required this.areaName,
    required this.genderColor,
    this.onRoomChanged,
  });

  @override
  State<_RoomDetailContent> createState() => _RoomDetailContentState();
}

enum _RoomDetailMenuAction {
  editRemark,
  clearRemark,
}

class _RoomDetailContentState extends State<_RoomDetailContent> {
  late Future<RoomCheckInResponse> _future;
  late Room _room;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _future = RoomService.getRoomCheckIns(_room.id);
  }

  /// 刷新入住信息
  void _refreshCheckIns() {
    setState(() {
      _future = RoomService.getRoomCheckIns(_room.id);
    });
  }

  /// 显示编辑备注对话框
  void _showEditRemarkDialog() {
    final TextEditingController controller = TextEditingController(text: _room.remark ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: const Text('编辑房间备注'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '请输入备注内容...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            maxLength: 200,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newRemark = controller.text.trim();
              
              final response = await RoomService.updateRoomRemark(_room.id, newRemark);
              
              if (!mounted) return;
              
              Navigator.pop(context);
              
              if (response.isSuccess) {
                setState(() {
                  _room = Room(
                    id: _room.id,
                    roomArea: _room.roomArea,
                    roomNumber: _room.roomNumber,
                    roomGender: _room.roomGender,
                    roomBeds: _room.roomBeds,
                    roomFloorMattress: _room.roomFloorMattress,
                    status: _room.status,
                    remark: newRemark.isEmpty ? null : newRemark,
                    createdAt: _room.createdAt,
                    updatedAt: _room.updatedAt,
                    availableBeds: _room.availableBeds,
                    totalCapacity: _room.totalCapacity,
                  );
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('备注更新成功'),
                    backgroundColor: RoomColors.available,
                  ),
                );
                
                RoomDataNotifier().notifyDataChanged();
                widget.onRoomChanged?.call(_room);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(response.message),
                    backgroundColor: RoomColors.occupied,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RoomColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示入住人详情
  void _showCheckInDetail(RoomCheckIn checkIn) async {
    final historyResponse = await RoomService.getUserCheckInHistory(checkIn.userId);
    
    if (!mounted) return;
    
    CheckInDetailSheet.show(
      context: context,
      checkIn: checkIn,
      historyCheckIns: historyResponse.data,
      showCheckOutButton: true,
      showChangeRoomButton: true,
      onCheckOut: () => _handleCheckOut(checkIn),
      onChangeRoom: () => _showChangeRoomSheet(checkIn),
      onPurposeUpdated: () {
        _refreshCheckIns();
        widget.onRoomChanged?.call(_room);
      },
    );
  }

  /// 处理退房
  void _handleCheckOut(RoomCheckIn checkIn) {
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
              await _performCheckOut(checkIn);
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

  /// 执行退房
  Future<void> _performCheckOut(RoomCheckIn checkIn) async {
    final response = await RoomService.checkOut(checkIn.id);

    if (response.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${checkIn.cname} 退房成功'),
            backgroundColor: RoomColors.available,
          ),
        );
        _refreshCheckIns();
        RoomDataNotifier().notifyDataChanged();
        widget.onRoomChanged?.call(_room);
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

  /// 显示更换房间抽屉
  void _showChangeRoomSheet(RoomCheckIn checkIn) {
    ChangeRoomSheet.show(
      context: context,
      checkIn: checkIn,
      onRoomChanged: () {
        _refreshCheckIns();
        widget.onRoomChanged?.call(widget.room);
      },
    );
  }

  /// 获取状态颜色
  Color _getStatusColor(String status) {
    return switch (status) {
      'available' => RoomColors.available,
      'full' => RoomColors.occupied,
      'maintenance' => RoomColors.partial,
      _ => RoomColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RoomCheckInResponse>(
      future: _future,
      builder: (context, snapshot) {
        List<RoomCheckIn> checkIns = [];
        bool isLoading = snapshot.connectionState == ConnectionState.waiting;
        String errorMessage = '';

        if (snapshot.hasError) {
          errorMessage = '加载失败: ${snapshot.error}';
        } else if (snapshot.hasData) {
          final response = snapshot.data!;
          if (response.isSuccess) {
            checkIns = response.data;
          } else {
            errorMessage = response.message;
          }
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: RoomColors.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 顶部拖动条
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
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
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${widget.areaName}-${_room.roomNumber}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: RoomColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _room.isFull 
                                      ? const Color(0xFFFFEBEE)
                                      : _room.status == 'maintenance'
                                          ? const Color(0xFFFFF8E1)
                                          : _getStatusColor(_room.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _room.isFull 
                                        ? const Color(0xFFEF9A9A)
                                        : _room.status == 'maintenance'
                                            ? const Color(0xFFFFE082)
                                            : _getStatusColor(_room.status).withOpacity(0.3),
                                    width:1,
                                  ),
                                ),
                                child: Text(
                                  _room.statusDisplayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _room.statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.bed_outlined,
                                size: 14,
                                color: RoomColors.textSecondary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${_room.roomBeds}  ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: RoomColors.textSecondary,
                                ),
                              ),
                              if (_room.roomFloorMattress > 0) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.layers_outlined,
                                  size: 14,
                                  color: RoomColors.textSecondary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${_room.roomFloorMattress}   ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: RoomColors.textSecondary,
                                  ),
                                ),
                              ],
                              Text(
                                '  ID:${_room.id}',
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
                    Row(
                      children: [
                        _buildGenderBadge(_room.roomGender),
                        const SizedBox(width: 8),
                        _buildMoreMenu(),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(color: RoomColors.divider, height: 1),
              // 房间备注
              if (_room.remark != null && _room.remark!.isNotEmpty)
                GestureDetector(
                  onTap: () => _showEditRemarkDialog(),
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 0),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.note_outlined,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _room.remark!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_room.remark != null && _room.remark!.isNotEmpty)
                Divider(color: RoomColors.divider, height: 1),
              // 床位列表
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isLoading
                      ? Center(child: CircularProgressIndicator(color: RoomColors.primary))
                      : errorMessage.isNotEmpty
                          ? Center(
                              child: Text(
                                errorMessage,
                                style: TextStyle(color: RoomColors.occupied),
                              ),
                            )
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _room.totalCapacity,
                              itemBuilder: (context, index) {
                                final isBed = index < _room.roomBeds;
                                final bedNumber = index + 1;
                                
                                RoomCheckIn? checkIn;
                                if (checkIns.isNotEmpty) {
                                  checkIn = checkIns.cast<RoomCheckIn?>().firstWhere(
                                    (item) => item?.bedNumber == bedNumber,
                                    orElse: () => null,
                                  );
                                }
                                
                                final isOccupied = checkIn != null;
                                
                                return _buildBedItem(
                                  number: bedNumber,
                                  isBed: isBed,
                                  isOccupied: isOccupied,
                                  genderColor: widget.genderColor,
                                  checkIn: checkIn,
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenderBadge(String gender) {
    Color bgColor;
    Color textColor;
    String text;

    if (gender == 'male') {
      bgColor = const Color(0xffE3F2FD);
      textColor = const Color(0xff1976D2);
      text = '男';
    } else if (gender == 'female') {
      bgColor = const Color(0xffFCE4EC);
      textColor = const Color(0xffC2185B);
      text = '女';
    } else {
      bgColor = Colors.indigo.withOpacity(0.1);
      textColor = Colors.indigo;
      text = '外';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMoreMenu() {
    final hasRemark = _room.remark?.isNotEmpty ?? false;
    return PopupMenuButton<_RoomDetailMenuAction>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert, color: RoomColors.textSecondary),
      color: RoomColors.cardBg,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: RoomColors.divider.withOpacity(0.5)),
      ),
      onSelected: (action) {
        switch (action) {
          case _RoomDetailMenuAction.editRemark:
            _showEditRemarkDialog();
            break;
          case _RoomDetailMenuAction.clearRemark:
            _clearRemark();
            break;
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: _RoomDetailMenuAction.editRemark,
            child: Text(
              hasRemark ? '编辑备注' : '添加备注',
              style: TextStyle(color: RoomColors.textPrimary),
            ),
          ),
          if (hasRemark)
            PopupMenuItem(
              value: _RoomDetailMenuAction.clearRemark,
              child: Text(
                '清除备注',
                style: TextStyle(color: RoomColors.textPrimary),
              ),
            ),
        ];
      },
    );
  }

  Future<void> _clearRemark() async {
    final response = await RoomService.updateRoomRemark(_room.id, '');
    if (!mounted) return;

    if (response.isSuccess) {
      setState(() {
        _room = Room(
          id: _room.id,
          roomArea: _room.roomArea,
          roomNumber: _room.roomNumber,
          roomGender: _room.roomGender,
          roomBeds: _room.roomBeds,
          roomFloorMattress: _room.roomFloorMattress,
          status: _room.status,
          remark: null,
          createdAt: _room.createdAt,
          updatedAt: _room.updatedAt,
          availableBeds: _room.availableBeds,
          totalCapacity: _room.totalCapacity,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('备注已清除'),
          backgroundColor: RoomColors.available,
        ),
      );
      RoomDataNotifier().notifyDataChanged();
      widget.onRoomChanged?.call(widget.room);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('清除备注失败: ${response.message}'),
          backgroundColor: RoomColors.occupied,
        ),
      );
    }
  }

  Widget _buildBedItem({
    required int number,
    required bool isBed,
    required bool isOccupied,
    required Color genderColor,
    RoomCheckIn? checkIn,
  }) {
    return GestureDetector(
      onTap: checkIn != null ? () => _showCheckInDetail(checkIn!) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isOccupied ? genderColor.withOpacity(0.1) : RoomColors.divider.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isOccupied ? genderColor : RoomColors.divider.withOpacity(0.5),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 10,
                    color: isOccupied ? genderColor : RoomColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  isBed ? Icons.bed_outlined : Icons.layers_outlined,
                  size: 16,
                  color: isOccupied ? genderColor : RoomColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    checkIn?.cname ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: isOccupied ? genderColor : RoomColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (checkIn != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      checkIn.cphone,
                      style: TextStyle(
                        fontSize: 11,
                        color: RoomColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
