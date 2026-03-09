import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'room_service.dart';

class AuthService {
  static User? _currentUser;
  static const String _userKey = 'user_data';

  // 获取 baseUrl，使用 RoomService 的设置
  static String get baseUrl => RoomService.baseUrl;

  // 获取当前登录用户
  static User? get currentUser => _currentUser;

  // 检查是否已登录
  static bool get isLoggedIn => _currentUser != null;

  // 初始化，从本地存储加载用户信息
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null && userJson.isNotEmpty) {
        final userData = json.decode(userJson);
        _currentUser = User.fromJson(userData);
      }
    } catch (e) {
      print('加载用户信息失败: $e');
    }
  }

  // 登录
  static Future<LoginResponse> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final loginResponse = LoginResponse.fromJson(jsonData);
        
        if (loginResponse.success && loginResponse.user != null) {
          _currentUser = loginResponse.user;
          await _saveUserToStorage(_currentUser!);
        }
        
        return loginResponse;
      } else {
        final jsonData = json.decode(response.body);
        return LoginResponse(
          message: jsonData['message'] ?? '登录失败',
          success: false,
        );
      }
    } catch (e) {
      return LoginResponse(
        message: '网络错误: $e',
        success: false,
      );
    }
  }

  // 保存用户信息到本地存储
  static Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(user.toJson()));
    } catch (e) {
      print('保存用户信息失败: $e');
    }
  }

  // 登出
  static Future<void> logout() async {
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      print('清除用户信息失败: $e');
    }
  }

  // 获取token
  static String? getToken() {
    return _currentUser?.token;
  }

  // 验证token有效性
  // 返回 Map: { 'valid': bool, 'serverError': bool, 'message': String }
  static Future<Map<String, dynamic>> verifyToken() async {
    final token = getToken();
    if (token == null || token.isEmpty) {
      print('Token 为空，需要重新登录');
      return {'valid': false, 'serverError': false, 'message': 'Token 为空'};
    }

    try {
      print('=== 验证 Token ===');
      print('URL: $baseUrl/api/auth/verify');

      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/verify'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10)); // 添加10秒超时

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Token 验证成功');
        return {'valid': true, 'serverError': false, 'message': '验证成功'};
      } else {
        print('❌ Token 验证失败，清除用户信息');
        await logout();
        return {'valid': false, 'serverError': false, 'message': 'Token 已过期'};
      }
    } on http.ClientException catch (e) {
      // 网络连接错误（服务器未开启、无法连接等）
      print('❌ 无法连接到服务器: $e');
      return {
        'valid': false,
        'serverError': true,
        'message': '无法连接到服务器，请检查服务器地址或网络连接'
      };
    } on Exception catch (e) {
      // 其他错误（超时等）
      print('❌ Token 验证出错: $e');
      return {
        'valid': false,
        'serverError': true,
        'message': '连接超时或网络错误，请稍后重试'
      };
    }
  }
}
