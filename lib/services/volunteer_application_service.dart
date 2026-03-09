import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/volunteer_application.dart';
import 'auth_service.dart';
import 'room_service.dart';

class VolunteerApplicationService {
  static String get baseUrl => RoomService.baseUrl;

  static Map<String, String> _getHeaders() {
    final token = AuthService.getToken();
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<VolunteerApplicationResponse> getApplications({
    int page = 0,
    int size = 10,
    String? keyword,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final url = Uri.parse('$baseUrl/api/volunteer-applications?$queryString');
      print('Get applications URL: $url');
      final headers = _getHeaders();
      print('Request Headers: $headers');
      
      final response = await http.get(url, headers: headers);
      
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return VolunteerApplicationResponse.fromJson(jsonData);
      } else {
        throw Exception('获取义工申请列表失败: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('网络错误: $e');
    }
  }
}
