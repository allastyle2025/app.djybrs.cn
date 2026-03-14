import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// iOS风格的页面路由 - 自带从左边缘向右滑动返回手势
class IOSPageRoute<T> extends CupertinoPageRoute<T> {
  IOSPageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
          builder: builder,
          settings: settings,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );
}

// 微信风格的页面路由动画 - 从右往左进入，从左往右返回
class WeChatPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  WeChatPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // 从右往左滑入的动画
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}
