import 'package:flutter/material.dart';
import '../room_colors.dart';

class RoomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? bottom;

  const RoomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBack = false,
    this.onBack,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: RoomColors.cardBg,
      elevation: 0,
      centerTitle: true,
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios, color: RoomColors.textPrimary, size: 20),
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: RoomColors.textPrimary,
        ),
      ),
      actions: actions,
      bottom: bottom != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: RoomColors.divider,
                height: 0.5,
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(bottom != null ? 57 : 56);
}
