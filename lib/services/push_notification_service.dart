import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/message.dart' as app_message;

/// 推送通知服务
/// 使用 Firebase Cloud Messaging (FCM) 实现离线推送
/// 即使 App 完全关闭也能收到通知
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 初始化推送服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('📱 初始化推送通知服务...');

    // 初始化 Firebase
    await Firebase.initializeApp();

    // 请求通知权限
    await _requestPermission();

    // 初始化本地通知（用于显示 FCM 消息）
    await _initLocalNotifications();

    // 设置 FCM 消息监听
    _setupFCMListeners();

    // 获取 FCM Token
    await _getFCMToken();

    _isInitialized = true;
    print('✅ 推送通知服务初始化完成');
  }

  /// 请求通知权限
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('📱 通知权限状态: ${settings.authorizationStatus}');
  }

  /// 初始化本地通知
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 创建通知渠道
    await _createNotificationChannel();
  }

  /// 创建通知渠道
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'fcm_channel',
        '推送通知',
        description: '接收义工申请和入住登记等推送通知',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// 设置 FCM 消息监听
  void _setupFCMListeners() {
    // 前台消息监听
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 收到前台 FCM 消息: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 后台/关闭状态点击通知打开 App
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 用户点击了通知打开 App: ${message.notification?.title}');
      // 这里可以处理跳转逻辑
    });
  }

  /// 显示本地通知
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fcm_channel',
      '推送通知',
      channelDescription: '接收义工申请和入住登记等推送通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/launcher_icon',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: message.data['assistantId'],
    );
  }

  /// 获取 FCM Token
  Future<String?> _getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $token');
      // 这里需要将 token 发送到你的后端服务器
      // 后端使用这个 token 来发送推送通知
      return token;
    } catch (e) {
      print('❌ 获取 FCM Token 失败: $e');
      return null;
    }
  }

  /// 订阅主题
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('📱 订阅主题: $topic');
  }

  /// 取消订阅主题
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('📱 取消订阅主题: $topic');
  }

  /// 处理通知点击
  void _onNotificationTap(NotificationResponse response) {
    print('📱 用户点击了通知: ${response.payload}');
    // 这里可以添加跳转到对应聊天页面的逻辑
  }
}

/// 后台消息处理函数
/// 必须在 main 函数外部定义
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 收到后台 FCM 消息: ${message.notification?.title}');
  // 这里可以处理后台消息，比如保存到本地存储
}
