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
          width: 500,
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
                        items: todayCheckIns,
                      ),
                      const SizedBox(height: 20),
                      // 今日离开
                      _buildDetailSection(
                        title: '今日离开',
                        count: todayCheckOuts.length,
                        icon: Icons.logout,
                        color: Colors.orange,
                        items: todayCheckOuts,
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
    required List<RoomCheckIn> items,
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
          decoration: BoxDecoration(
            color: RoomColors.background.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: RoomColors.divider),
          ),
          child: items.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      '暂无记录',
                      style: TextStyle(fontSize: 13, color: RoomColors.textGrey),
                    ),
                  ),
                )
              : Column(
                  children: [
                    // 表头和表格内容（支持水平和垂直滚动）
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 460,
                        child: Column(
                          children: [
                            _buildTableHeader(),
                            Divider(height: 1, color: RoomColors.divider),
                            Column(
                              children: items.asMap().entries.map((entry) {
                                final index = entry.key;
                                final checkIn = entry.value;
                                return _buildTableRow(checkIn, index + 1, index % 2 == 1);
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RoomColors.primary.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('序号', 40),
          _buildHeaderCell('姓名', 70),
          _buildHeaderCell('性别', 50),
          _buildHeaderCell('电话', 100),
          _buildHeaderCell('房间', 120),
          _buildHeaderCell('时间', 50),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: RoomColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(RoomCheckIn checkIn, int index, bool isAlternate) {
    final time = '${checkIn.checkInTime.hour.toString().padLeft(2, '0')}:${checkIn.checkInTime.minute.toString().padLeft(2, '0')}';
    final genderText = checkIn.cgender == 'male' ? '男' : (checkIn.cgender == 'female' ? '女' : checkIn.cgender);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isAlternate ? RoomColors.cardBg.withOpacity(0.5) : Colors.transparent,
      ),
      child: Row(
        children: [
          _buildDataCell('$index', 40, color: RoomColors.textSecondary),
          _buildDataCell(checkIn.cname, 70, isBold: true),
          _buildDataCell(genderText, 50),
          _buildDataCell(checkIn.cphone, 100),
          _buildDataCell('${checkIn.areaDisplayName} ${checkIn.roomNumber}号', 120),
          _buildDataCell(time, 50, color: RoomColors.textGrey),
        ],
      ),
    );
  }

  Widget _buildDataCell(String text, double width, {bool isBold = false, Color? color}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w500 : FontWeight.normal,
          color: color ?? RoomColors.textPrimary,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
