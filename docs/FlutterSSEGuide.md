# Flutter SSE 客户端实现指南

## 为什么 Flutter 报 SSE 错误？

Flutter 没有原生的 EventSource API（浏览器才有），所以直接使用 Web 版本的代码会报错。Flutter 需要使用第三方库或自己实现 SSE 客户端。

---

## 推荐方案

### 方案一：使用 `sse_client` 库（推荐）

这是最简单和最常用的方案。

#### 1. 添加依赖

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  sse_client: ^0.1.0
  http: ^1.1.0
```

#### 2. 完整代码示例

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sse_client/sse_client.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSE Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SseNotificationScreen(),
    );
  }
}

class SseNotificationScreen extends StatefulWidget {
  @override
  _SseNotificationScreenState createState() => _SseNotificationScreenState();
}

class _SseNotificationScreenState extends State<SseNotificationScreen> {
  SseClient? _sseClient;
  List<NotificationMessage> _notifications = [];
  bool _connected = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _connectToSSE();
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  // 连接到 SSE 服务器
  void _connectToSSE() {
    try {
      // 替换为你的实际服务器地址
      final url = 'http://192.168.88.240:8080/api/notifications/subscribe';
      
      _sseClient = SseClient.connect(url);
      
      setState(() {
        _connected = true;
      });

      // 监听 SSE 流
      _subscription = _sseClient!.stream.listen(
        (data) {
          _handleSSEMessage(data);
        },
        onError: (error) {
          print('SSE 错误: $error');
          setState(() {
            _connected = false;
          });
          // 3秒后重连
          Future.delayed(Duration(seconds: 3), () {
            _connectToSSE();
          });
        },
        onDone: () {
          print('SSE 连接关闭');
          setState(() {
            _connected = false;
          });
          // 3秒后重连
          Future.delayed(Duration(seconds: 3), () {
            _connectToSSE();
          });
        },
      );

      print('SSE 连接成功');
    } catch (e) {
      print('SSE 连接失败: $e');
      setState(() {
        _connected = false;
      });
    }
  }

  // 处理 SSE 消息
  void _handleSSEMessage(String data) {
    print('收到 SSE 消息: $data');

    // 解析消息
    try {
      // SSE 格式: event: xxx\ndata: xxx
      final lines = data.split('\n');
      String? eventType;
      String? messageData;

      for (var line in lines) {
        if (line.startsWith('event:')) {
          eventType = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          messageData = line.substring(5).trim();
        }
      }

      if (messageData != null) {
        final notification = NotificationMessage(
          type: eventType ?? 'notification',
          message: messageData,
          timestamp: DateTime.now(),
        );

        setState(() {
          _notifications.insert(0, notification);
          // 只保留最近100条消息
          if (_notifications.length > 100) {
            _notifications.removeLast();
          }
        });

        // 显示通知
        _showNotification(notification);
      }
    } catch (e) {
      print('解析消息失败: $e');
    }
  }

  // 显示通知
  void _showNotification(NotificationMessage notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(notification.message),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: '查看',
          onPressed: () {
            // 处理点击事件
            print('点击通知: ${notification.type}');
          },
        ),
      ),
    );
  }

  // 断开连接
  void _disconnect() {
    _subscription?.cancel();
    _sseClient?.close();
    setState(() {
      _connected = false;
    });
  }

  // 手动重连
  void _reconnect() {
    _disconnect();
    Future.delayed(Duration(milliseconds: 500), () {
      _connectToSSE();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SSE 通知'),
        actions: [
          Icon(
            _connected ? Icons.wifi : Icons.wifi_off,
            color: _connected ? Colors.green : Colors.red,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _reconnect,
          ),
        ],
      ),
      body: Column(
        children: [
          // 连接状态
          Container(
            padding: EdgeInsets.all(16),
            color: _connected ? Colors.green[50] : Colors.red[50],
            child: Row(
              children: [
                Icon(
                  _connected ? Icons.check_circle : Icons.error,
                  color: _connected ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  _connected ? '已连接到服务器' : '未连接',
                  style: TextStyle(
                    color: _connected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // 通知列表
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Text('暂无通知'),
                  )
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return ListTile(
                        leading: _getIconForType(notification.type),
                        title: Text(notification.message),
                        subtitle: Text(
                          _formatTimestamp(notification.timestamp),
                        ),
                        trailing: _getBadgeForType(notification.type),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 根据类型获取图标
  Icon _getIconForType(String type) {
    switch (type) {
      case 'volunteer_application':
        return Icon(Icons.volunteer_activism, color: Colors.blue);
      case 'room_checkin':
        return Icon(Icons.bed, color: Colors.orange);
      default:
        return Icon(Icons.notifications, color: Colors.grey);
    }
  }

  // 根据类型获取徽章
  Widget _getBadgeForType(String type) {
    String label;
    Color color;

    switch (type) {
      case 'volunteer_application':
        label = '义工申请';
        color = Colors.blue;
        break;
      case 'room_checkin':
        label = '入住登记';
        color = Colors.orange;
        break;
      default:
        label = '通知';
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  // 格式化时间戳
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} 小时前';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

// 通知消息模型
class NotificationMessage {
  final String type;
  final String message;
  final DateTime timestamp;

  NotificationMessage({
    required this.type,
    required this.message,
    required this.timestamp,
  });
}
```

---

### 方案二：使用 `http` 库自己实现

如果不想使用第三方库，可以使用 `http` 库自己实现：

```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SseClient {
  final String url;
  final Map<String, String> headers;
  http.Client? _client;
  StreamSubscription? _subscription;
  final _controller = StreamController<String>.broadcast();

  SseClient({
    required this.url,
    this.headers = const {},
  });

  Stream<String> get stream => _controller.stream;

  Future<void> connect() async {
    _client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      headers.forEach((key, value) {
        request.headers[key] = value;
      });
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await _client!.send(request);

      _subscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (line.isNotEmpty) {
                _controller.add(line);
              }
            },
            onError: (error) {
              _controller.addError(error);
            },
            onDone: () {
              _controller.close();
            },
          );
    } catch (e) {
      _controller.addError(e);
    }
  }

  void close() {
    _subscription?.cancel();
    _client?.close();
    _controller.close();
  }
}
```

---

## 常见错误和解决方案

### 1. CORS 错误

**错误信息**: `Access to fetch at 'xxx' from origin 'xxx' has been blocked by CORS policy`

**原因**: 服务器没有配置允许跨域请求

**解决方案**:

在后端添加 CORS 配置：

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(false)
                .maxAge(3600);
    }
}
```

### 2. 连接超时错误

**错误信息**: `Connection timeout` 或 `SocketException`

**原因**: 网络问题或服务器地址错误

**解决方案**:

```dart
// 1. 检查服务器地址是否正确
final url = 'http://192.168.88.240:8080/api/notifications/subscribe';

// 2. 添加超时处理
try {
  await _sseClient!.stream.timeout(Duration(seconds: 30)).first;
} on TimeoutException {
  print('连接超时');
  _reconnect();
}

// 3. 添加重连逻辑
void _reconnect() {
  Future.delayed(Duration(seconds: 3), () {
    _connectToSSE();
  });
}
```

### 3. JSON 解析错误

**错误信息**: `FormatException: Unexpected character`

**原因**: SSE 消息格式不正确

**解决方案**:

```dart
// 正确解析 SSE 消息格式
void _handleSSEMessage(String data) {
  final lines = data.split('\n');
  String? eventType;
  String? messageData;

  for (var line in lines) {
    if (line.startsWith('event:')) {
      eventType = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      messageData = line.substring(5).trim();
    }
  }

  // 只有当 data 字段存在时才解析 JSON
  if (messageData != null && messageData.startsWith('{')) {
    try {
      final jsonData = jsonDecode(messageData);
      // 处理 JSON 数据
    } catch (e) {
      // 处理普通文本消息
    }
  }
}
```

### 4. 权限错误

**错误信息**: `SocketException: Connection refused`

**原因**: Android 需要网络权限

**解决方案**:

在 `android/app/src/main/AndroidManifest.xml` 中添加：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 5. iOS 网络安全配置

**错误信息**: iOS 应用无法连接 HTTP 服务器

**原因**: iOS 默认只允许 HTTPS 连接

**解决方案**:

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## 完整的 SSE 服务类封装

```dart
import 'dart:async';
import 'package:sse_client/sse_client.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  SseClient? _sseClient;
  StreamSubscription? _subscription;
  final _notificationController = StreamController<Notification>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<Notification> get notificationStream => _notificationController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  bool _connected = false;
  bool get connected => _connected;

  void connect(String url) {
    if (_connected) return;

    try {
      _sseClient = SseClient.connect(url);
      _connected = true;
      _connectionStatusController.add(true);

      _subscription = _sseClient!.stream.listen(
        (data) {
          _parseMessage(data);
        },
        onError: (error) {
          print('SSE 错误: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('SSE 连接关闭');
          _handleDisconnection();
        },
      );

      print('SSE 连接成功');
    } catch (e) {
      print('SSE 连接失败: $e');
      _handleDisconnection();
    }
  }

  void _parseMessage(String data) {
    try {
      final lines = data.split('\n');
      String? eventType;
      String? messageData;

      for (var line in lines) {
        if (line.startsWith('event:')) {
          eventType = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          messageData = line.substring(5).trim();
        }
      }

      if (messageData != null) {
        final notification = Notification(
          type: eventType ?? 'notification',
          message: messageData,
          timestamp: DateTime.now(),
        );

        _notificationController.add(notification);
      }
    } catch (e) {
      print('解析消息失败: $e');
    }
  }

  void _handleDisconnection() {
    _connected = false;
    _connectionStatusController.add(false);
    
    // 3秒后自动重连
    Future.delayed(Duration(seconds: 3), () {
      if (!_connected) {
        // 需要重新调用 connect 方法
      }
    });
  }

  void disconnect() {
    _subscription?.cancel();
    _sseClient?.close();
    _connected = false;
    _connectionStatusController.add(false);
  }

  void dispose() {
    disconnect();
    _notificationController.close();
    _connectionStatusController.close();
  }
}

class Notification {
  final String type;
  final String message;
  final DateTime timestamp;

  Notification({
    required this.type,
    required this.message,
    required this.timestamp,
  });
}
```

---

## 使用示例

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final NotificationService _notificationService = NotificationService();
  List<Notification> _notifications = [];

  @override
  void initState() {
    super.initState();
    
    // 连接到 SSE 服务器
    _notificationService.connect('http://192.168.88.240:8080/api/notifications/subscribe');
    
    // 监听通知
    _notificationService.notificationStream.listen((notification) {
      setState(() {
        _notifications.insert(0, notification);
      });
    });
    
    // 监听连接状态
    _notificationService.connectionStatusStream.listen((connected) {
      print('连接状态: $connected');
    });
  }

  @override
  void dispose() {
    _notificationService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return ListTile(
            title: Text(notification.message),
            subtitle: Text(notification.timestamp.toString()),
          );
        },
      ),
    );
  }
}
```

---

## 总结

1. **Flutter 可以使用 SSE**，但需要使用第三方库或自己实现
2. **推荐使用 `sse_client` 库**，简单易用
3. **常见错误**：
   - CORS 错误：配置后端允许跨域
   - 连接超时：添加重连逻辑
   - JSON 解析错误：正确解析 SSE 消息格式
   - 权限错误：添加网络权限
   - iOS 网络安全：配置允许 HTTP 连接
4. **建议封装成服务类**，便于复用和管理

如果还有问题，请提供具体的错误信息，我可以帮你进一步解决！
