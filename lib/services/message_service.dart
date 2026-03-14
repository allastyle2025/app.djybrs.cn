import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/message.dart';
import 'room_service.dart';

/// 消息服务 - 获取历史消息
class MessageService {
  /// 获取消息列表
  static Future<ApiResponse<List<Message>>> getMessages({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final url = '${RoomService.baseUrl}/api/messages?page=$page&size=$size';
      print('获取消息列表: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('获取消息列表响应: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (jsonData['code'] == 200) {
          final List<dynamic> data = jsonData['data']['content'] ?? jsonData['data'] ?? [];
          final messages = data.map((item) => Message.fromJson(item)).toList();
          
          return ApiResponse(
            code: 200,
            data: messages,
            message: jsonData['message'] ?? '获取成功',
          );
        } else {
          return ApiResponse(
            code: jsonData['code'] ?? 500,
            message: jsonData['message'] ?? '获取消息列表失败',
          );
        }
      } else {
        return ApiResponse(
          code: response.statusCode,
          message: '获取消息列表失败: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      print('获取消息列表异常: $e');
      return ApiResponse(code: 500, message: '网络错误: $e');
    }
  }

  /// 标记消息为已读
  static Future<ApiResponse<void>> markAsRead(String messageId) async {
    try {
      final url = '${RoomService.baseUrl}/api/messages/$messageId/read';
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['code'] == 200) {
          return ApiResponse(code: 200, message: '标记已读成功');
        }
      }
      return ApiResponse(code: 500, message: '标记已读失败');
    } catch (e) {
      return ApiResponse(code: 500, message: '网络错误: $e');
    }
  }

  /// 标记所有消息为已读
  static Future<ApiResponse<void>> markAllAsRead() async {
    try {
      final url = '${RoomService.baseUrl}/api/messages/read-all';
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['code'] == 200) {
          return ApiResponse(code: 200, message: '全部标记已读成功');
        }
      }
      return ApiResponse(code: 500, message: '标记已读失败');
    } catch (e) {
      return ApiResponse(code: 500, message: '网络错误: $e');
    }
  }

  /// 删除消息
  static Future<ApiResponse<void>> deleteMessage(String messageId) async {
    try {
      final url = '${RoomService.baseUrl}/api/messages/$messageId';
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['code'] == 200) {
          return ApiResponse(code: 200, message: '删除成功');
        }
      }
      return ApiResponse(code: 500, message: '删除失败');
    } catch (e) {
      return ApiResponse(code: 500, message: '网络错误: $e');
    }
  }

  /// 获取未读消息数量
  static Future<ApiResponse<int>> getUnreadCount() async {
    try {
      final url = '${RoomService.baseUrl}/api/messages/unread-count';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['code'] == 200) {
          final count = jsonData['data'] ?? 0;
          return ApiResponse(code: 200, data: count, message: '获取成功');
        }
      }
      return ApiResponse(code: 200, data: 0, message: '获取失败');
    } catch (e) {
      return ApiResponse(code: 200, data: 0, message: '网络错误');
    }
  }
}
