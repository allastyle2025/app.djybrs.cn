import 'package:flutter/material.dart';
import '../models/room_check_in.dart';
import '../room_colors.dart';

class TodayActivityDialog extends StatelessWidget {
  final List<RoomCheckIn> todayCheckIns;
  final List<RoomCheckIn> todayCheckOuts;
  final String title;

  const TodayActivityDialog({
    super.key,
    required this.todayCheckIns,
    this.todayCheckOuts = const [],
    this.title = '今日动态',
  });

  static Future<void> show({
    required BuildContext context,
    required List<RoomCheckIn> todayCheckIns,
    List<RoomCheckIn> todayCheckOuts = const [],
    String title = '今日动态',
  }) {
    return showDialog(
      context: context,
      builder: (context) => TodayActivityDialog(
        todayCheckIns: todayCheckIns,
        todayCheckOuts: todayCheckOuts,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      RoomColors.primary.withOpacity(0.1),
                      RoomColors.primary.withOpacity(0.02),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: RoomColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: RoomColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 内容区域
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 今日入住
                      _buildDetailSection(
                        title: '今日入住',
                        count: todayCheckIns.length,
                        icon: Icons.login,
                        color: Colors.green,
                        items: todayCheckIns.map((checkIn) => _buildCheckInItem(checkIn, true)).toList(),
                      ),
                      const SizedBox(height: 20),
                      // 今日离开
                      _buildDetailSection(
                        title: '今日离开',
                        count: todayCheckOuts.length,
                        icon: Icons.logout,
                        color: Colors.orange,
                        items: todayCheckOuts.isEmpty
                            ? []
                            : todayCheckOuts.map((checkIn) => _buildCheckInItem(checkIn, false)).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: RoomColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count人',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: RoomColors.background.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: RoomColors.divider),
          ),
          child: items.isEmpty
              ? Center(
                  child: Text(
                    '暂无记录',
                    style: TextStyle(fontSize: 13, color: RoomColors.textGrey),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items,
                ),
        ),
      ],
    );
  }

  Widget _buildCheckInItem(RoomCheckIn checkIn, bool isCheckIn) {
    final time = '${checkIn.checkInTime.hour.toString().padLeft(2, '0')}:${checkIn.checkInTime.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: RoomColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                checkIn.cname.substring(0, 1),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: RoomColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkIn.cname,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: RoomColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${checkIn.areaDisplayName} ${checkIn.roomNumber}号',
                  style: TextStyle(
                    fontSize: 12,
                    color: RoomColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: RoomColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
