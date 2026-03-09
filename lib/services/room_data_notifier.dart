import 'dart:async';

/// 房间数据变更通知器
/// 用于跨页面通知房间数据变更
class RoomDataNotifier {
  static final RoomDataNotifier _instance = RoomDataNotifier._internal();
  factory RoomDataNotifier() => _instance;
  RoomDataNotifier._internal();

  final _controller = StreamController<void>.broadcast();

  /// 数据变更流
  Stream<void> get onDataChanged => _controller.stream;

  /// 通知数据变更
  void notifyDataChanged() {
    print('=== RoomDataNotifier: notifyDataChanged 被调用 ===');
    _controller.add(null);
    print('=== RoomDataNotifier: 通知已发送 ===');
  }

  /// 释放资源
  void dispose() {
    _controller.close();
  }
}
