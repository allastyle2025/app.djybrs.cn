import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_version.dart';
import '../models/room.dart';
import '../models/room_check_in.dart';
import '../pages/room/check_in_registration_page.dart';
import 'auth_service.dart';

class RoomService {
  static const String _baseUrlKey = 'server_base_url';
  static const String _defaultBaseUrl = 'https://djybrs.cn';
  static String _baseUrl = _defaultBaseUrl;

  // 获取 baseUrl，优先从内存，如果没有则从本地存储加载
  static String get baseUrl => _baseUrl;

  // 设置 baseUrl 并保存到本地存储
  static set baseUrl(String value) {
    _baseUrl = value;
    _saveBaseUrl(value);
  }

  // 初始化，从本地存储加载服务器地址
  static Future<void> init() async {
    print('=== RoomService.init() 开始 ===');
    try {
      final prefs = await SharedPreferences.getInstance();
      print('SharedPreferences 实例获取成功');
      
      final savedUrl = prefs.getString(_baseUrlKey);
      print('从 SharedPreferences 读取的地址: $savedUrl');
      
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _baseUrl = savedUrl;
        print('✅ 从本地存储加载服务器地址成功: $_baseUrl');
      } else {
        print('⚠️ 本地存储中没有保存的地址，使用默认值: $_defaultBaseUrl');
        _baseUrl = _defaultBaseUrl;
      }
    } catch (e) {
      print('❌ 加载服务器地址失败: $e');
      _baseUrl = _defaultBaseUrl;
    }
    print('=== RoomService.init() 结束，当前地址: $_baseUrl ===');
  }

  // 保存服务器地址到本地存储
  static Future<void> _saveBaseUrl(String url) async {
    print('=== 保存服务器地址 ===');
    print('要保存的地址: $url');
    try {
      final prefs = await SharedPreferences.getInstance();
      print('SharedPreferences 实例获取成功');
      
      final result = await prefs.setString(_baseUrlKey, url);
      if (result) {
        print('✅ 服务器地址保存成功: $url');
      } else {
        print('❌ 服务器地址保存失败，setString 返回 false');
      }
      
      // 验证保存是否成功
      final verifyUrl = prefs.getString(_baseUrlKey);
      print('验证读取: $verifyUrl');
    } catch (e) {
      print('❌ 保存服务器地址失败: $e');
    }
    print('=== 保存服务器地址结束 ===');
  }

  // 获取认证头
  static Map<String, String> _getHeaders() {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final token = AuthService.currentUser?.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // 获取房间列表
  static Future<RoomResponse> getRooms() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rooms'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RoomResponse.fromJson(jsonData);
      } else {
        return RoomResponse(
          code: response.statusCode,
          data: [],
          message: '请求失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      return RoomResponse(
        code: 500,
        data: [],
        message: '网络错误: $e',
      );
    }
  }

  // 获取房间入住信息
  static Future<RoomCheckInResponse> getRoomCheckIns(int roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/room-check-ins/room/$roomId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RoomCheckInResponse.fromJson(jsonData);
      } else {
        return RoomCheckInResponse(
          code: response.statusCode,
          data: [],
          message: '请求失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      return RoomCheckInResponse(
        code: 500,
        data: [],
        message: '网络错误: $e',
      );
    }
  }

  // 获取所有在寺人员列表
  static Future<RoomCheckInResponse> getCurrentCheckIns() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/room-check-ins/current'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RoomCheckInResponse.fromJson(jsonData);
      } else {
        return RoomCheckInResponse(
          code: response.statusCode,
          data: [],
          message: '请求失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      return RoomCheckInResponse(
        code: 500,
        data: [],
        message: '网络错误: $e',
      );
    }
  }

  // 获取今日入住列表
  static Future<RoomCheckInResponse> getTodayCheckIns() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/room-check-ins/search?checkInToday=true'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RoomCheckInResponse.fromJson(jsonData);
      } else {
        return RoomCheckInResponse(
          code: response.statusCode,
          data: [],
          message: '请求失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      return RoomCheckInResponse(
        code: 500,
        data: [],
        message: '网络错误: $e',
      );
    }
  }

  // 获取今日退房列表
  static Future<RoomCheckInResponse> getTodayCheckOuts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/room-check-ins/search?checkOutToday=true'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RoomCheckInResponse.fromJson(jsonData);
      } else {
        return RoomCheckInResponse(
          code: response.statusCode,
          data: [],
          message: '请求失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      return RoomCheckInResponse(
        code: 500,
        data: [],
        message: '网络错误: $e',
      );
    }
  }

  // 获取所有入住记录（包括已退房和未退房的）
  static Future<RoomCheckInResponse> getAllCheckIns() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/room-check-ins/search'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RoomCheckInResponse.fromJson(jsonData);
      } else {
        return RoomCheckInResponse(
          code: response.statusCode,
          data: [],
          message: '请求失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      return RoomCheckInResponse(
        code: 500,
        data: [],
        message: '网络错误: $e',
      );
    }
  }

  // 通过身份证查询用户
  static Future<UserInfoResponse> getUserByIdCard(String idCard) async {
    try {
      // 打印请求信息
      print('=== 身份证查询请求 ===');
      print('URL: $baseUrl/api/cgh-users/idcard/$idCard');

      final response = await http.get(
        Uri.parse('$baseUrl/api/cgh-users/idcard/$idCard'),
        headers: _getHeaders(),
      );

      // 打印响应信息
      print('=== 身份证查询响应 ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return UserInfoResponse.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        return UserInfoResponse(
          code: 404,
          data: null,
          message: '未找到该身份证对应的用户',
        );
      } else {
        return UserInfoResponse(
          code: response.statusCode,
          data: null,
          message: '请求失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('=== 身份证查询错误 ===');
      print('Error: $e');
      return UserInfoResponse(
        code: 500,
        data: null,
        message: '网络错误: $e',
      );
    }
  }

  // 快速入住登记
  static Future<QuickCheckInResponse> quickCheckIn({
    required int userId,
    required int roomId,
    required int bedNumber,
  }) async {
    try {
      print('=== 快速入住请求 ===');
      print('URL: $baseUrl/api/room-check-ins/quick-check-in');
      print('Body: {"userId": $userId, "roomId": $roomId, "bedNumber": $bedNumber}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/room-check-ins/quick-check-in'),
        headers: _getHeaders(),
        body: json.encode({
          'userId': userId,
          'roomId': roomId,
          'bedNumber': bedNumber,
        }),
      );

      print('=== 快速入住响应 ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return QuickCheckInResponse.fromJson(jsonData);
      } else {
        return QuickCheckInResponse(
          code: response.statusCode,
          data: null,
          message: '入住登记失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('=== 快速入住错误 ===');
      print('Error: $e');
      return QuickCheckInResponse(
        code: 500,
        data: null,
        message: '网络错误: $e',
      );
    }
  }

  // 退房
  static Future<QuickCheckInResponse> checkOut(int checkInId) async {
    try {
      print('=== 退房请求 ===');
      print('URL: $baseUrl/api/room-check-ins/check-out/$checkInId');

      final response = await http.post(
        Uri.parse('$baseUrl/api/room-check-ins/check-out/$checkInId'),
        headers: _getHeaders(),
      );

      print('=== 退房响应 ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return QuickCheckInResponse.fromJson(jsonData);
      } else {
        return QuickCheckInResponse(
          code: response.statusCode,
          data: null,
          message: '退房失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('=== 退房错误 ===');
      print('Error: $e');
      return QuickCheckInResponse(
        code: 500,
        data: null,
        message: '网络错误: $e',
      );
    }
  }

  // 更换房间 (PUT /api/room-check-ins/{id}/transfer)
  static Future<QuickCheckInResponse> changeRoom({
    required int checkInId,
    required int newRoomId,
    required int newBedNumber,
  }) async {
    try {
      final body = json.encode({
        'newRoomId': newRoomId,
        'newBedNumber': newBedNumber,
      });

      print('=== 更换房间请求 ===');
      print('URL: $baseUrl/api/room-check-ins/$checkInId/transfer');
      print('Method: PUT');
      print('Body: $body');

      final response = await http.put(
        Uri.parse('$baseUrl/api/room-check-ins/$checkInId/transfer'),
        headers: _getHeaders(),
        body: body,
      );

      print('=== 更换房间响应 ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return QuickCheckInResponse.fromJson(jsonData);
      } else {
        return QuickCheckInResponse(
          code: response.statusCode,
          data: null,
          message: '更换房间失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('=== 更换房间错误 ===');
      print('Error: $e');
      return QuickCheckInResponse(
        code: 500,
        data: null,
        message: '网络错误: $e',
      );
    }
  }

  // 获取用户历史入住记录
  static Future<CheckInHistoryResponse> getUserCheckInHistory(int userId) async {
    try {
      print('=== 获取用户历史入住记录 ===');
      final url = '$baseUrl/api/room-check-ins/user/$userId';
      print('URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );

      print('=== 历史入住记录响应 ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CheckInHistoryResponse.fromJson(jsonData);
      } else {
        return CheckInHistoryResponse(
          code: response.statusCode,
          data: [],
          message: '获取历史记录失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('=== 获取历史记录错误 ===');
      print('Error: $e');
      return CheckInHistoryResponse(
        code: 500,
        data: [],
        message: '网络错误: $e',
      );
    }
  }

  // 检查应用更新
  static Future<AppVersionResponse> checkUpdate(String currentVersion) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/app/version/check?currentVersion=$currentVersion&platform=android'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AppVersionResponse.fromJson(jsonData);
      } else {
        return AppVersionResponse(
          code: response.statusCode,
          message: '检查更新失败: ${response.statusCode}',
          data: null,
        );
      }
    } catch (e) {
      return AppVersionResponse(
        code: 500,
        message: '网络错误: $e',
        data: null,
      );
    }
  }
}
