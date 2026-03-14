import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// 消息发送服务
/// 用于发送各种类型的消息到后端
class MessageSenderService {
  /// 发送 allasGroup 消息
  static Future<bool> sendAllasGroupMessage({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final baseUrl = AuthService.baseUrl;
      final url = Uri.parse('$baseUrl/api/notifications/send');
      final token = AuthService.getToken();

      final body = {
        'type': 'allas_group',
        'title': title,
        'message': message,
        'data': data ?? {},
      };

      print('📤 发送 allasGroup 消息: $body');

      final headers = {
        'Content-Type': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('✅ allasGroup 消息发送成功');
        return true;
      } else {
        print('❌ allasGroup 消息发送失败: ${response.statusCode}');
        print('响应: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ allasGroup 消息发送异常: $e');
      return false;
    }
  }
}
