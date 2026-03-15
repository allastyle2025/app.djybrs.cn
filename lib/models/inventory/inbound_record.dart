import 'goods.dart';

/// 入库记录模型
class InboundRecord {
  final int? inboundId;
  final int goodsId;
  final int quantity;
  final double? purchasePrice;
  final String? supplier;
  final double? totalAmount;
  final int? operatorId;
  final DateTime? inboundDate;
  final String? remark;
  final DateTime? createTime;
  final Goods? goods;

  InboundRecord({
    this.inboundId,
    required this.goodsId,
    required this.quantity,
    this.purchasePrice,
    this.supplier,
    this.totalAmount,
    this.operatorId,
    this.inboundDate,
    this.remark,
    this.createTime,
    this.goods,
  });

  factory InboundRecord.fromJson(Map<String, dynamic> json) {
    return InboundRecord(
      inboundId: json['inboundId'],
      goodsId: json['goodsId'] ?? 0,
      quantity: json['quantity'] ?? 0,
      purchasePrice: json['purchasePrice'] != null
          ? double.tryParse(json['purchasePrice'].toString())
          : null,
      supplier: json['supplier'],
      totalAmount: json['totalAmount'] != null
          ? double.tryParse(json['totalAmount'].toString())
          : null,
      operatorId: json['operatorId'],
      inboundDate: json['inboundDate'] != null
          ? DateTime.tryParse(json['inboundDate'])
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
      'inboundId': inboundId,
      'goodsId': goodsId,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'supplier': supplier,
      'totalAmount': totalAmount,
      'operatorId': operatorId,
      'inboundDate': inboundDate?.toIso8601String().split('T')[0],
      'remark': remark,
      'createTime': createTime?.toIso8601String(),
    };
  }

  /// 计算总金额
  double get calculatedTotalAmount {
    if (purchasePrice == null) return 0;
    return purchasePrice! * quantity;
  }

  InboundRecord copyWith({
    int? inboundId,
    int? goodsId,
    int? quantity,
    double? purchasePrice,
    String? supplier,
    double? totalAmount,
    int? operatorId,
    DateTime? inboundDate,
    String? remark,
    DateTime? createTime,
    Goods? goods,
  }) {
    return InboundRecord(
      inboundId: inboundId ?? this.inboundId,
      goodsId: goodsId ?? this.goodsId,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      supplier: supplier ?? this.supplier,
      totalAmount: totalAmount ?? this.totalAmount,
      operatorId: operatorId ?? this.operatorId,
      inboundDate: inboundDate ?? this.inboundDate,
      remark: remark ?? this.remark,
      createTime: createTime ?? this.createTime,
      goods: goods ?? this.goods,
    );
  }
}
