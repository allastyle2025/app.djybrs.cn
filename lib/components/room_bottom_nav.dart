import 'package:flutter/material.dart';
import '../room_colors.dart';

class RoomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool showMessage;
  final bool showHome;
  final bool showPersonnel;
  final bool showRoom;
  final bool showTools;
  final bool showProfile;
  final int messageBadgeCount; // 消息tab的badge数量
  final int personnelBadgeCount; // 人员tab的badge数量（待审核数量）

  const RoomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.showMessage = true,
    this.showHome = true,
    this.showPersonnel = true,
    this.showRoom = false,
    this.showTools = true,
    this.showProfile = true,
    this.messageBadgeCount = 0, // 默认为0
    this.personnelBadgeCount = 0, // 默认为0
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
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final items = _buildItems();
              final itemWidth = constraints.maxWidth / items.length;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: items.map((item) {
                  return SizedBox(
                    width: itemWidth,
                    child: item,
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItems() {
    final List<Widget> items = [];
    int idx = 0;

    // helper to append and increment index
    void addItem(IconData outlineIcon, IconData filledIcon, String label, {int badgeCount = 0}) {
      items.add(_buildNavItem(outlineIcon, filledIcon, label, idx, badgeCount: badgeCount));
      idx++;
    }

    if (showMessage) addItem(Icons.chat_bubble_outline, Icons.chat_bubble, '消息', badgeCount: messageBadgeCount);
    if (showHome) addItem(Icons.home_outlined, Icons.home, '首页');
    if (showPersonnel) addItem(Icons.people_outline, Icons.people, '人员', badgeCount: personnelBadgeCount);
    if (showRoom) addItem(Icons.meeting_room_outlined, Icons.meeting_room, '房间');
    if (showTools) addItem(Icons.apps_outlined, Icons.apps, '工具');
    if (showProfile) addItem(Icons.person_outline, Icons.person, '我的');

    return items;
  }

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, String label, int index, {int badgeCount = 0}) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标带Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? filledIcon : outlineIcon,
                  size: 28,
                  color: isSelected ? RoomColors.tabSelected : RoomColors.tabNormal,
                ),
                // Badge
                if (badgeCount > 0)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      width: badgeCount > 9 ? 28 : 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFA5151),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: RoomColors.tabBg, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? RoomColors.tabSelected : RoomColors.tabNormal,
              ),
            ),
          ],
        ),
    );
  }
}
