/// 产品（货品）模型
class Goods {
  final int? goodsId;
  final String goodsName;
  final String goodsType;
  final String? specification;
  final String unit;
  final String? color;
  final double? purchasePrice;
  final double? sellingPrice;
  final int? currentStock;
  final int? safetyStock;
  final String? remark;
  final DateTime? createTime;

  Goods({
    this.goodsId,
    required this.goodsName,
    required this.goodsType,
    this.specification,
    required this.unit,
    this.color,
    this.purchasePrice,
    this.sellingPrice,
    this.currentStock,
    this.safetyStock,
    this.remark,
    this.createTime,
  });

  factory Goods.fromJson(Map<String, dynamic> json) {
    return Goods(
      goodsId: json['goodsId'],
      goodsName: json['goodsName'] ?? '',
      goodsType: json['goodsType'] ?? '',
      specification: json['specification'],
      unit: json['unit'] ?? '',
      color: json['color'],
      purchasePrice: json['purchasePrice'] != null
          ? double.tryParse(json['purchasePrice'].toString())
          : null,
      sellingPrice: json['sellingPrice'] != null
          ? double.tryParse(json['sellingPrice'].toString())
          : null,
      currentStock: json['currentStock'],
      safetyStock: json['safetyStock'],
      remark: json['remark'],
      createTime: json['createTime'] != null
          ? DateTime.tryParse(json['createTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goodsId': goodsId,
      'goodsName': goodsName,
      'goodsType': goodsType,
      'specification': specification,
      'unit': unit,
      'color': color,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'currentStock': currentStock,
      'safetyStock': safetyStock,
      'remark': remark,
      'createTime': createTime?.toIso8601String(),
    };
  }

  /// 是否库存不足
  bool get isLowStock {
    if (currentStock == null || safetyStock == null) return false;
    return currentStock! <= safetyStock!;
  }

  Goods copyWith({
    int? goodsId,
    String? goodsName,
    String? goodsType,
    String? specification,
    String? unit,
    String? color,
    double? purchasePrice,
    double? sellingPrice,
    int? currentStock,
    int? safetyStock,
    String? remark,
    DateTime? createTime,
  }) {
    return Goods(
      goodsId: goodsId ?? this.goodsId,
      goodsName: goodsName ?? this.goodsName,
      goodsType: goodsType ?? this.goodsType,
      specification: specification ?? this.specification,
      unit: unit ?? this.unit,
      color: color ?? this.color,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentStock: currentStock ?? this.currentStock,
      safetyStock: safetyStock ?? this.safetyStock,
      remark: remark ?? this.remark,
      createTime: createTime ?? this.createTime,
    );
  }
}
