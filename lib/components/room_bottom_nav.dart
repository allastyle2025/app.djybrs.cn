import 'package:flutter/material.dart';
import '../room_colors.dart';

class RoomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const RoomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RoomColors.tabBg,
        border: Border(
          top: BorderSide(
            color: RoomColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, '首页', 0),
              _buildNavItem(Icons.meeting_room_outlined, '房间', 1),
              _buildNavItem(Icons.apps_outlined, '工具', 2),
              _buildNavItem(Icons.person_outline, '我的', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? RoomColors.tabSelected : RoomColors.tabNormal,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? RoomColors.tabSelected : RoomColors.tabNormal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
