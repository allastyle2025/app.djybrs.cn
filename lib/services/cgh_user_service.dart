import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cgh_user.dart';
import 'auth_service.dart';
import 'room_service.dart';

class CghUserService {
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

  /// 获取人员列表
  static Future<CghUserResponse> getUsers({
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
      final url = Uri.parse('$baseUrl/api/cgh-users?$queryString');
      
      print('=== CghUserService.getUsers ===');
      print('请求URL: $url');
      final headers = _getHeaders();
      print('请求Headers: $headers');
      
      final response = await http.get(url, headers: headers);
      
      print('响应状态码: ${response.statusCode}');
      print('响应体: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        print('API响应结构: $jsonData');
        
        if (jsonData['code'] == 200) {
          final data = jsonData['data'];
          if (data != null) {
            print('data字段类型: ${data.runtimeType}');
            print('data字段内容: $data');
            if (data is Map<String, dynamic>) {
              print('content字段类型: ${data['content']?.runtimeType}');
              print('content字段内容: ${data['content']}');
              print('totalElements字段: ${data['totalElements']}');
              print('totalPages字段: ${data['totalPages']}');
              print('currentPage字段: ${data['currentPage']}');
              print('size字段: ${data['size']}');
            }
          }
          
          print('获取人员列表成功，共 ${jsonData['data']?['content']?.length ?? 0} 条记录');
          return CghUserResponse.fromJson(jsonData);
        } else {
          print('API返回错误: ${jsonData['message']}');
          throw Exception('获取失败: ${jsonData['message']}');
        }
      } else {
        print('HTTP请求失败: ${response.statusCode}');
        throw Exception('网络请求失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取人员列表异常: $e');
      throw Exception('获取人员列表失败: $e');
    }
  }

  /// 创建新人员
  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cgh-users'),
        headers: _getHeaders(),
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData;
      } else {
        throw Exception('创建失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('创建人员失败: $e');
    }
  }

  /// 更新人员信息
  static Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/cgh-users/$id'),
        headers: _getHeaders(),
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData;
      } else {
        throw Exception('更新失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('更新人员失败: $e');
    }
  }

  /// 删除人员
  static Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/cgh-users/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData;
      } else {
        throw Exception('删除失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('删除人员失败: $e');
    }
  }
}