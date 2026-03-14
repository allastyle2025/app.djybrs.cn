import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import 'room_service.dart';

/// 聊天消息模型
class ChatMessage {
  final String id;
  final String content;
  final bool isMe;
  final DateTime timestamp;
  final String? senderId;
  final String? senderName;
  final String? senderAvatar;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isMe,
    required this.timestamp,
    this.senderId,
    this.senderName,
    this.senderAvatar,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? json['message']?.toString() ?? '',
      isMe: json['isMe'] ?? json['is_me'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      senderId: json['senderId']?.toString() ?? json['sender_id']?.toString(),
      senderName: json['senderName']?.toString() ?? json['sender_name']?.toString(),
      senderAvatar: json['senderAvatar']?.toString() ?? json['sender_avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isMe': isMe,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
    };
  }
}

/// 聊天服务
class ChatService {
  /// 获取聊天记录
  static Future<ApiResponse<List<ChatMessage>>> getChatHistory({
    required String senderId,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final url = '${RoomService.baseUrl}/api/chat/history?senderId=$senderId&page=$page&size=$size';
      print('获取聊天记录: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('获取聊天记录响应: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));

        if (jsonData['code'] == 200) {
          final List<dynamic> data = jsonData['data']['content'] ?? jsonData['data'] ?? [];
          final messages = data.map((item) => ChatMessage.fromJson(item)).toList();

          return ApiResponse(
            code: 200,
            data: messages,
            message: jsonData['message'] ?? '获取成功',
          );
        } else {
          return ApiResponse(
            code: jsonData['code'] ?? 500,
            message: jsonData['message'] ?? '获取聊天记录失败',
          );
        }
      } else {
        return ApiResponse(
          code: response.statusCode,
          message: '获取聊天记录失败: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('获取聊天记录异常: $e');
      return ApiResponse(code: 500, message: '网络错误: $e');
    }
  }

  /// 发送消息
  static Future<ApiResponse<ChatMessage>> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      final url = '${RoomService.baseUrl}/api/chat/send';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'receiverId': receiverId,
          'content': content,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['code'] == 200) {
          final message = ChatMessage.fromJson(jsonData['data']);
          return ApiResponse(code: 200, data: message, message: '发送成功');
        }
      }
      return ApiResponse(code: 500, message: '发送失败');
    } catch (e) {
      return ApiResponse(code: 500, message: '网络错误: $e');
    }
  }
}
