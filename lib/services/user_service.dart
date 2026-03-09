import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'auth_service.dart';

class UserService {
  static const String baseUrl = 'https://djybrs.cn';

  // 获取请求头（带token）
  static Map<String, String> _getHeaders() {
    final token = AuthService.getToken();
    print('Token: $token');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('Authorization header: Bearer $token');
    }
    return headers;
  }

  // 获取用户列表
  static Future<UserListResponse> getUsers({int page = 1, int perPage = 20}) async {
    try {
      final url = Uri.parse('$baseUrl/api/users?page=$page&per_page=$perPage');
      print('Request URL: $url');
      final headers = _getHeaders();
      print('Request Headers: $headers');
      
      final response = await http.get(url, headers: headers);
      
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return UserListResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('未授权，请重新登录');
      } else {
        throw Exception('获取用户列表失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      
      if (e.toString().contains('Failed to fetch') || e.toString().contains('ClientException')) {
        throw Exception('CORS跨域错误或网络连接失败，请检查服务器CORS配置');
      }
      throw Exception('网络错误: $e');
    }
  }

  // 获取单个用户详情
  static Future<User> getUserDetail(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is Map<String, dynamic>) {
          return User.fromJson(jsonData);
        }
        throw Exception('用户不存在');
      } else if (response.statusCode == 401) {
        throw Exception('未授权，请重新登录');
      } else {
        throw Exception('获取用户详情失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  // 更新用户信息
  static Future<User> updateUser(int userId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: _getHeaders(),
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return User.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('未授权，请重新登录');
      } else {
        throw Exception('更新用户信息失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  // 删除用户
  static Future<bool> deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('未授权，请重新登录');
      } else {
        throw Exception('删除用户失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  // 搜索用户
  static Future<UserListResponse> searchUsers(String keyword, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users?search=$keyword&page=$page'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return UserListResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('未授权，请重新登录');
      } else {
        throw Exception('搜索用户失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络错误: $e');
    }
  }

  // 创建用户
  static Future<User> createUser(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/api/users');
      print('Create user URL: $url');
      print('Create user data: $data');
      
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: json.encode(data),
      );
      
      print('Create user response status: ${response.statusCode}');
      print('Create user response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return User.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('未授权，请重新登录');
      } else {
        throw Exception('创建用户失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Create user error: $e');
      throw Exception('网络错误: $e');
    }
  }
}

class UserListResponse {
  final List<User> users;
  final int total;
  final int currentPage;
  final int lastPage;

  UserListResponse({
    required this.users,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  factory UserListResponse.fromJson(dynamic json) {
    List<dynamic> data = [];
    
    // 支持多种返回格式
    if (json is List) {
      data = json;
    } else if (json is Map) {
      data = json['data'] ?? json['list'] ?? json['users'] ?? [];
    }
    
    return UserListResponse(
      users: data.map((item) => User.fromJson(item)).toList(),
      total: json is Map ? (json['total'] ?? json['meta']?['total'] ?? data.length) : data.length,
      currentPage: json is Map ? (json['current_page'] ?? json['page'] ?? 1) : 1,
      lastPage: json is Map ? (json['last_page'] ?? json['total_pages'] ?? 1) : 1,
    );
  }
}
