import 'package:flutter/material.dart';
import '../models/room.dart';
import '../room_colors.dart';

class RoomListCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;

  const RoomListCard({
    Key? key,
    required this.room,
    this.onTap,
  }) : super(key: key);

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: RoomColors.cardBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // 房间号
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        room.roomNumber,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 区域和性别标签
                        Row(
                          children: [
                            // 区域标签
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: RoomColors.background,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${room.areaDisplayName}-${room.roomNumber}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: RoomColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 性别标签 - 轻亮背景色
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: room.genderBgColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    room.genderIcon,
                                    size: 12,
                                    color: room.genderColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    room.genderDisplayName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: room.genderColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // 床位信息
                        Text(
                          room.roomFloorMattress > 0
                              ? '${room.roomBeds}张床 · ${room.roomFloorMattress}个地铺'
                              : '${room.roomBeds}张床',
                          style: TextStyle(
                            fontSize: 12,
                            color: RoomColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 状态标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 11,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 床位状态指示器
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildBedIndicators(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${room.occupiedBeds}/${room.totalCapacity}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: RoomColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBedIndicators() {
    List<Widget> indicators = [];
    
    // 添加床位指示器
    for (int i = 0; i < room.roomBeds; i++) {
      bool isOccupied = i < room.occupiedBeds;
      indicators.add(_buildIndicator(isOccupied, i + 1));
    }
    
    // 添加地铺指示器
    for (int i = 0; i < room.roomFloorMattress; i++) {
      bool isOccupied = (room.roomBeds + i) < room.occupiedBeds;
      indicators.add(_buildIndicator(isOccupied, room.roomBeds + i + 1, isFloor: true));
    }
    
    return Row(children: indicators);
  }

  Widget _buildIndicator(bool isOccupied, int number, {bool isFloor = false}) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: isOccupied ? RoomColors.occupied : RoomColors.available,
        borderRadius: BorderRadius.circular(4),
        border: isFloor
            ? Border.all(
                color: isOccupied ? RoomColors.occupied.withOpacity(0.3) : RoomColors.available.withOpacity(0.3),
                width: 1,
                style: BorderStyle.solid,
              )
            : null,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
