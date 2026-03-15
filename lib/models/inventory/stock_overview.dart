import 'goods.dart';
import 'inbound_record.dart';
import 'outbound_record.dart';

/// 库存总览统计
class StockOverview {
  final int totalGoods;
  final int warningCount;
  final int todayInbound;
  final int todayOutbound;

  StockOverview({
    required this.totalGoods,
    required this.warningCount,
    required this.todayInbound,
    required this.todayOutbound,
  });

  factory StockOverview.fromJson(Map<String, dynamic> json) {
    return StockOverview(
      totalGoods: json['totalGoods'] ?? 0,
      warningCount: json['warningCount'] ?? 0,
      todayInbound: json['todayInbound'] ?? 0,
      todayOutbound: json['todayOutbound'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalGoods': totalGoods,
      'warningCount': warningCount,
      'todayInbound': todayInbound,
      'todayOutbound': todayOutbound,
    };
  }
}

/// 库存详情（包含出入库记录）
class StockDetail {
  final Goods goods;
  final List<InboundRecord> inboundRecords;
  final List<OutboundRecord> outboundRecords;

  StockDetail({
    required this.goods,
    required this.inboundRecords,
    required this.outboundRecords,
  });

  factory StockDetail.fromJson(Map<String, dynamic> json) {
    return StockDetail(
      goods: Goods.fromJson(json['goods']),
      inboundRecords: (json['inboundRecords'] as List?)
              ?.map((e) => InboundRecord.fromJson(e))
              .toList() ??
          [],
      outboundRecords: (json['outboundRecords'] as List?)
              ?.map((e) => OutboundRecord.fromJson(e))
              .toList() ??
          [],
    );
  }
}
