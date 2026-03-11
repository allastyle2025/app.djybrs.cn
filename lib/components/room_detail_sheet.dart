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
  final VoidCallback? onRoomChanged;

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
    VoidCallback? onRoomChanged,
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
  final VoidCallback? onRoomChanged;

  const _RoomDetailContent({
    required this.room,
    required this.areaName,
    required this.genderColor,
    this.onRoomChanged,
  });

  @override
  State<_RoomDetailContent> createState() => _RoomDetailContentState();
}

class _RoomDetailContentState extends State<_RoomDetailContent> {
  late Future<RoomCheckInResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = RoomService.getRoomCheckIns(widget.room.id);
  }

  /// 刷新入住信息
  void _refreshCheckIns() {
    setState(() {
      _future = RoomService.getRoomCheckIns(widget.room.id);
    });
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
        widget.onRoomChanged?.call();
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
        widget.onRoomChanged?.call();
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
        widget.onRoomChanged?.call();
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
                                '${widget.areaName}-${widget.room.roomNumber}',
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
                                  color: widget.room.isFull 
                                      ? const Color(0xFFFFEBEE)
                                      : widget.room.status == 'maintenance'
                                          ? const Color(0xFFFFF8E1)
                                          : _getStatusColor(widget.room.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: widget.room.isFull 
                                        ? const Color(0xFFEF9A9A)
                                        : widget.room.status == 'maintenance'
                                            ? const Color(0xFFFFE082)
                                            : _getStatusColor(widget.room.status).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  widget.room.statusDisplayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: widget.room.statusColor,
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
                                '${widget.room.roomBeds}  ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: RoomColors.textSecondary,
                                ),
                              ),
                              if (widget.room.roomFloorMattress > 0) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.layers_outlined,
                                  size: 14,
                                  color: RoomColors.textSecondary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${widget.room.roomFloorMattress}   ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: RoomColors.textSecondary,
                                  ),
                                ),
                              ],
                              Text(
                                '  ID:${widget.room.id}',
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
                    _buildGenderBadge(widget.room.roomGender),
                  ],
                ),
              ),
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
                              itemCount: widget.room.totalCapacity,
                              itemBuilder: (context, index) {
                                final isBed = index < widget.room.roomBeds;
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
