import 'package:flutter/material.dart';
import '../models/room_check_in.dart';
import '../room_colors.dart';

/// 入住人员汇总弹窗组件
/// 显示所有在住人员的房间、姓名、性别信息
class OccupancySummaryDialog extends StatelessWidget {
  final List<RoomCheckIn> checkIns;
  final String title;

  const OccupancySummaryDialog({
    super.key,
    required this.checkIns,
    this.title = '在住人员汇总',
  });

  static Future<void> show({
    required BuildContext context,
    required List<RoomCheckIn> checkIns,
    String title = '在住人员汇总',
  }) {
    return showDialog(
      context: context,
      builder: (context) => OccupancySummaryDialog(
        checkIns: checkIns,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 按区域和房间号排序
    final sortedCheckIns = List<RoomCheckIn>.from(checkIns)
      ..sort((a, b) {
        // 先按区域排序
        final areaCompare = (a.areaDisplayName ?? '').compareTo(b.areaDisplayName ?? '');
        if (areaCompare != 0) return areaCompare;
        // 再按房间号排序
        return (a.roomNumber ?? '').compareTo(b.roomNumber ?? '');
      });

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: RoomColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '共 ${checkIns.length} 人',
                          style: TextStyle(
                            fontSize: 14,
                            color: RoomColors.textSecondary,
                          ),
                        ),
                      ],
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
              // 表头
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: RoomColors.background,
                  border: Border(
                    bottom: BorderSide(color: RoomColors.divider),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        '房间',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: RoomColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '姓名',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: RoomColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '性别',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: RoomColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 表格内容
              Flexible(
                child: sortedCheckIns.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.hotel_outlined,
                              size: 48,
                              color: RoomColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '暂无在住人员',
                              style: TextStyle(
                                fontSize: 14,
                                color: RoomColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: sortedCheckIns.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: RoomColors.divider.withOpacity(0.5),
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final checkIn = sortedCheckIns[index];
                          return _buildTableRow(checkIn);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(RoomCheckIn checkIn) {
    // 获取性别显示文本和颜色
    String genderText = '未知';
    Color genderColor = RoomColors.textSecondary;
    
    if (checkIn.cgender == 'male') {
      genderText = '男';
      genderColor = Colors.blue;
    } else if (checkIn.cgender == 'female') {
      genderText = '女';
      genderColor = Colors.pink;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '${checkIn.areaDisplayName ?? ''}-${checkIn.roomNumber ?? ''}',
              style: TextStyle(
                fontSize: 14,
                color: RoomColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              checkIn.cname ?? '',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: RoomColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: genderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                genderText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: genderColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
