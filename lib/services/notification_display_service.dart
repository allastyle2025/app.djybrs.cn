import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/message.dart' as app_message;

/// 系统通知显示服务
/// 用于在系统通知栏、锁屏、状态栏显示通知
class NotificationDisplayService {
  static final NotificationDisplayService _instance = NotificationDisplayService._internal();
  factory NotificationDisplayService() => _instance;
  NotificationDisplayService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android 初始化设置
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS 初始化设置
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 初始化设置
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 初始化插件
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 请求权限
    await _requestPermissions();

    // 创建通知渠道（Android 8.0+ 需要）
    await _createNotificationChannel();

    _isInitialized = true;
    print('✅ 系统通知服务初始化完成');
  }

  /// 请求通知权限
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ 需要请求通知权限
      final status = await Permission.notification.status;
      print('📱 Android 通知权限状态: $status');
      if (status.isDenied || status.isRestricted) {
        final result = await Permission.notification.request();
        print('📱 Android 通知权限请求结果: $result');
      }
    } else if (Platform.isIOS) {
      // iOS 权限在初始化时已经请求
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      print('📱 iOS 通知权限: $result');
    }
  }

  /// 创建通知渠道（Android）
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'message_channel', // 渠道ID
        '消息通知', // 渠道名称
        description: '接收义工申请和入住登记等消息通知', // 渠道描述
        importance: Importance.high, // 重要性级别
        enableVibration: true, // 启用震动
        enableLights: true, // 启用指示灯
        playSound: true, // 播放声音
        showBadge: true, // 显示角标
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      print('✅ 通知渠道创建完成');
    }
  }

  /// 显示消息通知
  Future<void> showMessageNotification(app_message.Message message) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 构建通知详情
    final String title = _getNotificationTitle(message);
    final String body = message.content;

    // Android 通知详情
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'message_channel',
      '消息通知',
      channelDescription: '接收义工申请和入住登记等消息通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      // 使用系统默认提示音
      icon: '@mipmap/launcher_icon',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      styleInformation: BigTextStyleInformation(body),
      category: AndroidNotificationCategory.message,
    );

    // iOS 通知详情
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // 使用系统默认提示音
      interruptionLevel: InterruptionLevel.active,
    );

    // 通知详情
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 显示通知
    try {
      print('📱 正在显示系统通知...');
      print('   标题: $title');
      print('   内容: $body');
      print('   通知ID: ${message.id.hashCode}');
      print('   助手ID: ${message.assistantId}');

      await _notificationsPlugin.show(
        message.id.hashCode, // 通知ID
        title,
        body,
        notificationDetails,
        payload: message.assistantId, // 点击通知时传递的数据
      );

      print('✅ 系统通知已显示成功');
    } catch (e) {
      print('❌ 显示系统通知失败: $e');
    }
  }

  /// 显示自定义通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'message_channel',
      '消息通知',
      channelDescription: '接收义工申请和入住登记等消息通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// 处理通知点击
  void _onNotificationTap(NotificationResponse response) {
    print('📱 用户点击了通知: ${response.payload}');
    // 这里可以添加跳转到对应聊天页面的逻辑
    // 例如：通过 navigatorKey 全局导航到 ChatPage
  }

  /// 取消特定通知
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// 测试通知（用于调试）
  Future<void> showTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    print('🧪 发送测试通知...');

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'message_channel',
      '消息通知',
      channelDescription: '接收义工申请和入住登记等消息通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/launcher_icon',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        9999,
        '测试通知',
        '这是一条测试通知，如果您看到这条消息，说明系统通知功能正常工作！',
        notificationDetails,
        payload: 'test',
      );
      print('✅ 测试通知发送成功');
    } catch (e) {
      print('❌ 测试通知发送失败: $e');
    }
  }

  /// 设置应用角标（iOS）
  Future<void> setBadge(int count) async {
    // iOS 角标设置需要使用原生代码或第三方插件
    // flutter_local_notifications 不直接支持 setBadgeCount
    print('📱 设置应用角标: $count');
  }

  /// 获取通知标题
  String _getNotificationTitle(app_message.Message message) {
    switch (message.assistantType) {
      case app_message.AssistantType.volunteer:
        return '义工申请小助手';
      case app_message.AssistantType.room:
        return '房间小助手';
      case app_message.AssistantType.allasGroup:
        return message.senderName;
      case app_message.AssistantType.system:
      default:
        return '系统通知';
    }
  }
}
