import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// 自定义 SSE 客户端（兼容 http 1.x）
class SseClient {
  final Uri url;
  final Map<String, String> headers;
  
  HttpClient? _httpClient;
  http.Client? _client;
  StreamSubscription? _subscription;
  final _controller = StreamController<String>.broadcast();
  bool _isClosed = false;

  SseClient({
    required this.url,
    this.headers = const {},
  });

  /// 获取数据流
  Stream<String> get stream => _controller.stream;

  /// 连接到 SSE 服务器
  Future<void> connect() async {
    if (_isClosed) {
      throw Exception('SSE client is closed');
    }

    try {
      // 创建自定义 HttpClient
      _httpClient = HttpClient();
      _httpClient!.connectionTimeout = const Duration(seconds: 30);
      // 不设置 idleTimeout，让连接保持打开
      // _httpClient!.idleTimeout = const Duration(hours: 24);
      
      // 使用 IOClient
      _client = IOClient(_httpClient!);

      // 构建请求
      final request = http.Request('GET', url);
      headers.forEach((key, value) {
        request.headers[key] = value;
      });
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['Connection'] = 'keep-alive';
      // 添加这些头部可能有助于防止代理关闭连接
      request.headers['X-Accel-Buffering'] = 'no';

      print('🔌 SSE 正在连接: $url');
      final response = await _client!.send(request);

      if (response.statusCode == 200) {
        print('🔌 SSE 连接成功，状态码: ${response.statusCode}');
        print('🔌 SSE 响应头: ${response.headers}');
        
        // 监听数据流
        _subscription = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (line) {
                print('🔌 SSE 收到原始数据: "$line"');
                if (line.isNotEmpty) {
                  _controller.add(line);
                } else {
                  print('🔌 SSE 收到空行（消息分隔符）');
                  _controller.add(''); // 发送空行表示消息结束
                }
              },
              onError: (error) {
                print('🔌 SSE 流错误: $error');
                if (!_isClosed) {
                  _controller.addError(error);
                }
              },
              onDone: () {
                print('🔌 SSE 流关闭');
                if (!_isClosed) {
                  _controller.close();
                }
              },
              cancelOnError: false,
            );
      } else {
        throw Exception('SSE 连接失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('🔌 SSE 连接异常: $e');
      throw Exception('SSE 连接失败: $e');
    }
  }

  /// 关闭连接
  void close() {
    print('🔌 SSE 关闭连接');
    _isClosed = true;
    _subscription?.cancel();
    _client?.close();
    _httpClient?.close();
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  /// 检查连接是否活跃
  bool get isClosed => _isClosed;
}
