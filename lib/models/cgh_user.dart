import 'package:flutter/material.dart';

/// 人员管理 - 用户数据模型
class CghUser {
  final int id;
  final String name;
  final String gender; // 'male' 或 'female'
  final String phone;
  final int age;
  final String idCard;
  final String address;
  final String ethnicity;
  final DateTime createTime;
  final DateTime updateTime;

  const CghUser({
    required this.id,
    required this.name,
    required this.gender,
    required this.phone,
    required this.age,
    required this.idCard,
    required this.address,
    required this.ethnicity,
    required this.createTime,
    required this.updateTime,
  });

  /// 从JSON创建CghUser对象
  factory CghUser.fromJson(Map<String, dynamic> json) {
    return CghUser(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      gender: (json['gender'] ?? 'male') as String,
      phone: (json['phone'] ?? '') as String,
      age: (json['age'] ?? 0) as int,
      idCard: (json['idCard'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      ethnicity: (json['ethnicity'] ?? '汉族') as String,
      createTime: DateTime.parse((json['createTime'] ?? '2026-01-01T00:00:00') as String),
      updateTime: DateTime.parse((json['updateTime'] ?? '2026-01-01T00:00:00') as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'phone': phone,
      'age': age,
      'idCard': idCard,
      'address': address,
      'ethnicity': ethnicity,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
    };
  }

  /// 获取性别显示名称
  String get genderDisplayName {
    return gender == 'male' ? '男' : '女';
  }

  /// 获取性别颜色
  Color get genderColor {
    return gender == 'male' 
        ? const Color(0xff42A5F5)  // 男众亮蓝色
        : const Color.fromARGB(255, 255, 107, 164);  // 女众亮粉色
  }

  /// 格式化身份证号（显示前6位和后4位）
  String get formattedIdCard {
    if (idCard.length <= 10) return idCard;
    return '${idCard.substring(0, 6)}****${idCard.substring(idCard.length - 4)}';
  }

  /// 格式化电话号码
  String get formattedPhone {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 7)} ${digits.substring(7)}';
    }
    return phone;
  }

  /// 从身份证号计算年龄
  int get calculatedAge {
    if (idCard.length != 18) return age; // 如果身份证号无效，返回原始年龄
    
    try {
      // 提取出生日期 (第7-14位)
      final birthYear = int.parse(idCard.substring(6, 10));
      final birthMonth = int.parse(idCard.substring(10, 12));
      final birthDay = int.parse(idCard.substring(12, 14));
      
      final now = DateTime.now();
      var age = now.year - birthYear;
      
      // 如果今年生日还没到，年龄减1
      if (now.month < birthMonth || (now.month == birthMonth && now.day < birthDay)) {
        age--;
      }
      
      return age;
    } catch (e) {
      return age; // 解析失败时返回原始年龄
    }
  }

  @override
  String toString() {
    return 'CghUser{id: $id, name: $name, gender: $gender, phone: $phone, age: $age}';
  }

  /// 转换为UserInfo对象（用于登记入住）
  Map<String, dynamic> toUserInfoJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'phone': phone,
      'age': age,
      'idCard': idCard,
      'address': address,
      'ethnicity': ethnicity,
    };
  }
}

/// 人员列表响应模型
class CghUserResponse {
  final List<CghUser> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final int size;

  const CghUserResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
    required this.size,
  });

  /// 从JSON创建CghUserResponse对象
  factory CghUserResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final content = (data['content'] as List)
        .map((item) => CghUser.fromJson(item as Map<String, dynamic>))
        .toList();

    return CghUserResponse(
      content: content,
      totalElements: (data['totalElements'] ?? 0) as int,
      totalPages: (data['totalPages'] ?? 0) as int,
      currentPage: (data['currentPage'] ?? 0) as int,
      size: (data['size'] ?? 10) as int,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'data': {
        'content': content.map((user) => user.toJson()).toList(),
        'totalElements': totalElements,
        'totalPages': totalPages,
        'currentPage': currentPage,
        'size': size,
      }
    };
  }
}