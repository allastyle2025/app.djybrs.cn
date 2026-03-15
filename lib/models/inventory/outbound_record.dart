import 'goods.dart';

/// 出库记录模型
class OutboundRecord {
  final int? outboundId;
  final int goodsId;
  final int quantity;
  final String destination;
  final int? operatorId;
  final DateTime? outboundDate;
  final String? remark;
  final DateTime? createTime;
  final Goods? goods;

  OutboundRecord({
    this.outboundId,
    required this.goodsId,
    required this.quantity,
    required this.destination,
    this.operatorId,
    this.outboundDate,
    this.remark,
    this.createTime,
    this.goods,
  });

  factory OutboundRecord.fromJson(Map<String, dynamic> json) {
    return OutboundRecord(
      outboundId: json['outboundId'],
      goodsId: json['goodsId'] ?? 0,
      quantity: json['quantity'] ?? 0,
      destination: json['destination'] ?? '',
      operatorId: json['operatorId'],
      outboundDate: json['outboundDate'] != null
          ? DateTime.tryParse(json['outboundDate'])
          : null,
      remark: json['remark'],
      createTime: json['createTime'] != null
          ? DateTime.tryParse(json['createTime'])
          : null,
      goods: json['goods'] != null ? Goods.fromJson(json['goods']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'outboundId': outboundId,
      'goodsId': goodsId,
      'quantity': quantity,
      'destination': destination,
      'operatorId': operatorId,
      'outboundDate': outboundDate?.toIso8601String().split('T')[0],
      'remark': remark,
      'createTime': createTime?.toIso8601String(),
    };
  }

  OutboundRecord copyWith({
    int? outboundId,
    int? goodsId,
    int? quantity,
    String? destination,
    int? operatorId,
    DateTime? outboundDate,
    String? remark,
    DateTime? createTime,
    Goods? goods,
  }) {
    return OutboundRecord(
      outboundId: outboundId ?? this.outboundId,
      goodsId: goodsId ?? this.goodsId,
      quantity: quantity ?? this.quantity,
      destination: destination ?? this.destination,
      operatorId: operatorId ?? this.operatorId,
      outboundDate: outboundDate ?? this.outboundDate,
      remark: remark ?? this.remark,
      createTime: createTime ?? this.createTime,
      goods: goods ?? this.goods,
    );
  }
}
