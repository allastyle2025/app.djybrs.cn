import 'dart:async';
import 'dart:convert';
import '../models/message.dart';
import 'room_data_notifier.dart';
import 'room_service.dart';
import 'sse_client.dart';

/// SSE 实时通知服务
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  SseClient? _sseClient;
  StreamSubscription? _subscription;
  final _messageController = StreamController<Message>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  bool _isConnected = false;
  bool _isConnecting = false; // 新增：防止重复连接
  String? _pendingEventType;
  String? _pendingData;
  Timer? _keepAliveTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  /// 消息流，用于监听新消息
  Stream<Message> get messageStream => _messageController.stream;

  /// 连接状态流
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 连接 SSE 服务器
  void connect({String? token}) {
    // 防止重复连接
    if (_isConnected || _isConnecting) {
      print('📡 SSE 已经连接或正在连接中，跳过');
      return;
    }

    _isConnecting = true;
    print('📡 SSE 开始连接... (尝试 ${_reconnectAttempts + 1})');

    _sseClient = SseClient(
      url: Uri.parse('${RoomService.baseUrl}/api/notifications/subscribe'),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );

    // 连接到服务器
    _sseClient!.connect().then((_) {
      print('📡 SSE 连接建立');
      // 注意：这里只表示 HTTP 连接成功，不代表 SSE 流正常
    }).catchError((error) {
      print('📡 SSE 连接失败: $error');
      _isConnecting = false;
      _handleDisconnection();
      return null; // 必须返回 null 避免未处理的错误
    });

    // 监听 SSE 流
    _subscription = _sseClient!.stream.listen(
      (line) {
        // 收到数据表示连接真正成功
        if (!_isConnected) {
          _isConnected = true;
          _isConnecting = false;
          _reconnectAttempts = 0; // 重置重连次数
          _connectionStatusController.add(true);
          print('📡 SSE 连接成功，开始接收数据');
          _startKeepAlive();
        }
        _handleSSELine(line);
      },
      onError: (error) {
        print('📡 SSE 流错误: $error');
        _isConnecting = false;
        _handleDisconnection();
      },
      onDone: () {
        print('📡 SSE 流关闭');
        _isConnecting = false;
        _handleDisconnection();
      },
    );
  }

  /// 处理 SSE 单行数据
  void _handleSSELine(String line) {
    line = line.trim();

    print('📨 SSE 原始行: "$line"');

    // 空行表示消息结束，处理累积的数据
    if (line.isEmpty) {
      print('📨 SSE 空行 - 消息结束');
      _processPendingMessage();
      return;
    }

    // 支持 event:xxx 和 event: xxx 两种格式
    if (line.startsWith('event:')) {
      _pendingEventType = line.substring(6).trim();
      print('📨 SSE 事件类型: "$_pendingEventType"');
    } else if (line.startsWith('data:')) {
      final data = line.substring(5).trim();
      print('📨 SSE 数据: "$data"');

      // 累积数据（支持多行 data）
      if (_pendingData == null) {
        _pendingData = data;
      } else {
        _pendingData = _pendingData! + '\n' + data;
      }
    } else if (line.startsWith('id:')) {
      print('📨 SSE ID: ${line.substring(3).trim()}');
    } else if (line.startsWith('retry:')) {
      print('📨 SSE Retry: ${line.substring(6).trim()}');
    } else {
      print('📨 SSE 未知行格式: $line');
    }
  }

  /// 处理累积的消息
  void _processPendingMessage() {
    if (_pendingData == null) {
      print('📨 SSE 没有数据需要处理');
      _pendingEventType = null;
      return;
    }

    final data = _pendingData!;
    // 如果 eventType 为空，尝试从 JSON 数据中的 type 字段获取
    String? eventType = _pendingEventType;

    // 尝试解析 JSON
    dynamic jsonData;
    try {
      jsonData = jsonDecode(data);
      print('📨 SSE JSON 解析成功: $jsonData');
      // 如果 eventType 为空，从 JSON 中的 type 字段获取
      if (eventType == null || eventType.isEmpty) {
        eventType = jsonData['type'];
        print('📨 SSE 从 JSON 中获取事件类型: $eventType');
      }
    } catch (e) {
      print('📨 SSE JSON 解析失败，当作文本: $e');
      jsonData = {'message': data};
    }

    print('📨 SSE 处理消息 - 事件: $eventType, 数据: $data');

    // 处理连接成功消息
    if (data == '连接成功') {
      print('📨 SSE 服务器连接确认');
      _pendingData = null;
      _pendingEventType = null;
      return;
    }

    // 根据事件类型创建消息
    final message = _createMessageFromEvent(eventType, jsonData);
    if (message != null) {
      print('📨 SSE 消息创建成功: ${message.content}');
      _messageController.add(message);
      print('📨 SSE 消息已发送到流');
      
      // 如果是入住登记消息，通知人员页面刷新待审核列表
      if (eventType == 'room_checkin') {
        print('🏨 收到入住登记消息，通知人员页面刷新');
        RoomDataNotifier().notifyDataChanged();
      }
    } else {
      print('📨 SSE 消息创建失败或无需创建，事件类型: $eventType');
    }

    // 重置状态
    _pendingData = null;
    _pendingEventType = null;
  }

  /// 根据事件类型创建消息
  Message? _createMessageFromEvent(String? eventType, dynamic jsonData) {
    final timestamp = DateTime.now();
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    print('📨 创建消息 - 事件类型: $eventType, 数据: $jsonData');

    switch (eventType) {
      case 'volunteer_application':
        return Message(
          id: id,
          senderId: 'system',
          senderName: jsonData['title'] ?? '义工申请',
          senderAvatar: 'https://picsum.photos/seed/volunteer/100/100',
          content: jsonData['message'] ?? '新的义工申请',
          timestamp: jsonData['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(jsonData['timestamp'])
              : timestamp,
          isRead: false,
          type: MessageType.system,
          unreadCount: 1,
          assistantType: AssistantType.volunteer, // 设置助手类型为义工申请
          sourceId: jsonData['data']?['applicationId']?.toString(),
          extraData: jsonData,
        );

      case 'room_checkin':
        print('📨 创建入住登记消息');
        return Message(
          id: id,
          senderId: 'system',
          senderName: jsonData['title'] ?? '入住登记',
          senderAvatar: 'https://picsum.photos/seed/checkin/100/100',
          content: jsonData['message'] ?? '新的入住登记',
          timestamp: jsonData['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(jsonData['timestamp'])
              : timestamp,
          isRead: false,
          type: MessageType.system,
          unreadCount: 1,
          assistantType: AssistantType.room, // 设置助手类型为房间
          sourceId: jsonData['data']?['checkInId']?.toString(),
          extraData: jsonData,
        );

      case 'connect':
        print('📨 SSE 连接事件，不创建消息: $jsonData');
        return null;

      case 'notification':
      default:
        print('📨 创建默认通知消息');
        return Message(
          id: id,
          senderId: 'system',
          senderName: jsonData['title'] ?? '系统通知',
          senderAvatar: 'https://picsum.photos/seed/system/100/100',
          content: jsonData['message'] ?? jsonData.toString(),
          timestamp: timestamp,
          isRead: false,
          type: MessageType.system,
          unreadCount: 1,
          assistantType: AssistantType.system,
          extraData: jsonData,
        );
    }
  }

  /// 启动保活定时器 - 每30秒发送一次保活检查
  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        print('📡 SSE 保活检查 - 连接正常');
      }
    });
  }

  /// 处理断开连接 - 自动重连
  void _handleDisconnection() {
    // 检查是否已经在重连定时器中
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      print('📡 SSE 重连定时器已存在，跳过');
      return;
    }

    print('📡 SSE 断开连接，准备重连...');
    _isConnected = false;
    _isConnecting = false;
    _connectionStatusController.add(false);
    _keepAliveTimer?.cancel();
    _subscription?.cancel();
    _sseClient?.close();
    _sseClient = null;
    _pendingData = null;
    _pendingEventType = null;

    // 自动重连 - 无限重连，延迟递增到最大60秒
    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts * 2).clamp(2, 60); // 最小2秒，最大60秒
    final delay = Duration(seconds: delaySeconds);
    print('📡 SSE 将在 ${delay.inSeconds} 秒后重连 (尝试 $_reconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      print('📡 SSE 开始自动重连...');
      connect();
    });
  }

  /// 断开连接
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 999999; // 阻止自动重连
    _handleDisconnection();
    print('📡 SSE 手动断开连接');
  }

  /// 重新连接
  void reconnect({String? token}) {
    _reconnectAttempts = 0; // 重置重连计数
    disconnect();
    Future.delayed(const Duration(milliseconds: 500), () {
      connect(token: token);
    });
  }

  /// 释放资源
  void dispose() {
    _reconnectTimer?.cancel();
    _handleDisconnection();
    _messageController.close();
    _connectionStatusController.close();
  }
}
