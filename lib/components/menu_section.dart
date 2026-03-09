import 'package:flutter/material.dart';
import '../room_colors.dart';

class MenuSection extends StatelessWidget {
  final String title;
  final List<MenuItem> items;

  const MenuSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: RoomColors.cardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: RoomColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                ListTile(
                  leading: Icon(item.icon, color: RoomColors.textPrimary, size: 22),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      color: item.color ?? RoomColors.textPrimary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: RoomColors.textSecondary,
                    size: 20,
                  ),
                  onTap: item.onTap,
                ),
                if (index < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 56,
                    color: RoomColors.divider,
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

class MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });
}
