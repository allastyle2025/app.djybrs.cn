import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/inventory/goods.dart';
import '../../models/inventory/inbound_record.dart';
import '../../models/inventory/outbound_record.dart';
import '../../models/inventory/stock_overview.dart';
import '../auth_service.dart';

/// 库存管理服务
class InventoryService {
  static String get baseUrl => AuthService.baseUrl;

  // ==================== 产品管理 ====================

  /// 获取所有产品
  static Future<List<Goods>> getAllGoods() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/inventory/goods'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => Goods.fromJson(e)).toList();
    }
    throw Exception('获取产品列表失败: ${response.statusCode}');
  }

  /// 根据ID获取产品
  static Future<Goods> getGoodsById(int id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/inventory/goods/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Goods.fromJson(json.decode(response.body));
    }
    throw Exception('获取产品详情失败: ${response.statusCode}');
  }

  /// 创建产品
  static Future<Goods> createGoods(Goods goods) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/inventory/goods'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(goods.toJson()),
    );

    if (response.statusCode == 201) {
      return Goods.fromJson(json.decode(response.body));
    }
    throw Exception('创建产品失败: ${response.statusCode}');
  }

  /// 更新产品
  static Future<Goods> updateGoods(int id, Goods goods) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/inventory/goods/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(goods.toJson()),
    );

    if (response.statusCode == 200) {
      return Goods.fromJson(json.decode(response.body));
    }
    throw Exception('更新产品失败: ${response.statusCode}');
  }

  /// 删除产品
  static Future<void> deleteGoods(int id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/inventory/goods/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('删除产品失败: ${response.statusCode}');
    }
  }

  /// 搜索产品
  static Future<List<Goods>> searchGoods(String keyword) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/inventory/goods/search?keyword=$keyword'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => Goods.fromJson(e)).toList();
    }
    throw Exception('搜索产品失败: ${response.statusCode}');
  }

  // ==================== 入库管理 ====================

  /// 创建入库记录
  static Future<InboundRecord> createInbound(InboundRecord record) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/inventory/inbound'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(record.toJson()),
    );

    if (response.statusCode == 201) {
      return InboundRecord.fromJson(json.decode(response.body));
    }
    throw Exception('创建入库记录失败: ${response.body}');
  }

  /// 查询入库记录
  static Future<List<InboundRecord>> getInboundRecords({
    int? goodsId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await _getToken();
    final queryParams = <String, String>{};
    if (goodsId != null) queryParams['goodsId'] = goodsId.toString();
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }

    final uri = Uri.parse('$baseUrl/api/inventory/inbound')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => InboundRecord.fromJson(e)).toList();
    }
    throw Exception('获取入库记录失败: ${response.statusCode}');
  }

  /// 删除入库记录
  static Future<void> deleteInbound(int id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/inventory/inbound/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('删除入库记录失败: ${response.statusCode}');
    }
  }

  // ==================== 出库管理 ====================

  /// 创建出库记录
  static Future<OutboundRecord> createOutbound(OutboundRecord record) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/inventory/outbound'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(record.toJson()),
    );

    if (response.statusCode == 201) {
      return OutboundRecord.fromJson(json.decode(response.body));
    }
    throw Exception('创建出库记录失败: ${response.body}');
  }

  /// 查询出库记录
  static Future<List<OutboundRecord>> getOutboundRecords({
    int? goodsId,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await _getToken();
    final queryParams = <String, String>{};
    if (goodsId != null) queryParams['goodsId'] = goodsId.toString();
    if (destination != null) queryParams['destination'] = destination;
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }

    final uri = Uri.parse('$baseUrl/api/inventory/outbound')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => OutboundRecord.fromJson(e)).toList();
    }
    throw Exception('获取出库记录失败: ${response.statusCode}');
  }

  /// 删除出库记录
  static Future<void> deleteOutbound(int id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/inventory/outbound/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('删除出库记录失败: ${response.statusCode}');
    }
  }

  // ==================== 库存查询 ====================

  /// 查询所有产品库存
  static Future<List<Goods>> getStock({bool warning = false}) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/inventory/stock')
        .replace(queryParameters: {'warning': warning.toString()});

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => Goods.fromJson(e)).toList();
    }
    throw Exception('获取库存失败: ${response.statusCode}');
  }

  /// 查询单个产品库存详情
  static Future<StockDetail> getStockDetail(int goodsId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/inventory/stock/$goodsId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return StockDetail.fromJson(json.decode(response.body));
    }
    throw Exception('获取库存详情失败: ${response.statusCode}');
  }

  // ==================== 统计报表 ====================

  /// 库存总览
  static Future<StockOverview> getStockOverview() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/inventory/stats/overview'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return StockOverview.fromJson(json.decode(response.body));
    }
    throw Exception('获取库存总览失败: ${response.statusCode}');
  }

  /// 殿堂出库统计
  static Future<List<List<dynamic>>> getHallStats(int goodsId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/inventory/stats/hall?goodsId=$goodsId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => e as List<dynamic>).toList();
    }
    throw Exception('获取殿堂统计失败: ${response.statusCode}');
  }

  /// 获取殿堂列表
  static Future<List<String>> getHalls() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/inventory/halls'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => e.toString()).toList();
    }
    throw Exception('获取殿堂列表失败: ${response.statusCode}');
  }

  /// 同步库存
  static Future<void> syncStock() async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/inventory/sync'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('同步库存失败: ${response.statusCode}');
    }
  }

  // ==================== 辅助方法 ====================

  static Future<String?> _getToken() async {
    final user = AuthService.currentUser;
    return user?.token;
  }
}
