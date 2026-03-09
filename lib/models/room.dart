import 'package:flutter/material.dart';

class Room {
  final int id;
  final String roomArea;
  final String roomNumber;
  final String roomGender;
  final int roomBeds;
  final int roomFloorMattress;
  final String status;
  final String? remark;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int availableBeds;
  final int totalCapacity;

  Room({
    required this.id,
    required this.roomArea,
    required this.roomNumber,
    required this.roomGender,
    required this.roomBeds,
    required this.roomFloorMattress,
    required this.status,
    this.remark,
    required this.createdAt,
    required this.updatedAt,
    required this.availableBeds,
    required this.totalCapacity,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      roomArea: json['roomArea'],
      roomNumber: json['roomNumber'],
      roomGender: json['roomGender'],
      roomBeds: json['roomBeds'],
      roomFloorMattress: json['roomFloorMattress'],
      status: json['status'],
      remark: json['remark'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      availableBeds: json['availableBeds'],
      totalCapacity: json['totalCapacity'],
    );
  }

  // 获取区域显示名称
  String get areaDisplayName => getAreaDisplayName(roomArea);

  // 静态方法：获取区域显示名称
  static String getAreaDisplayName(String areaCode) {
    switch (areaCode) {
      case 'hy':
        return '华严殿';
      case 'be':
        return '报恩楼';
      case 'zts':
        return '斋堂上';
      case 'ktx':
        return '客堂下';
      case 'cz':
        return '常住';
      case 'ld':
        return '老殿';
      default:
        return areaCode;
    }
  }

  // 获取区域代码
  String get areaCode => roomArea;

  // 获取性别显示名称
  String get genderDisplayName {
    switch (roomGender) {
      case 'male':
        return '男众';
      case 'female':
        return '女众';
      default:
        return roomGender;
    }
  }

  // 获取性别颜色
  Color get genderColor {
    switch (roomGender) {
      case 'male':
        return const Color(0xFF4A90E2); // 蓝色
      case 'female':
        return const Color(0xFFE24A8D); // 粉色
      default:
        return const Color(0xFF999999);
    }
  }

  // 获取性别背景色
  Color get genderBgColor {
    switch (roomGender) {
      case 'male':
        return const Color(0xFFE3F2FD); // 浅蓝
      case 'female':
        return const Color(0xFFFCE4EC); // 浅粉
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  // 获取性别图标
  IconData get genderIcon {
    switch (roomGender) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      default:
        return Icons.person;
    }
  }

  // 获取状态显示名称
  String get statusDisplayName {
    switch (status) {
      case 'available':
        return '可入住';
      case 'full':
        return '已满';
      case 'maintenance':
        return '维修中';
      default:
        return status;
    }
  }

  // 是否已满（有床位且没有空床位才算满）
  bool get isFull => roomBeds > 0 && availableBeds == 0;

  // 是否空房
  bool get isEmpty => availableBeds == totalCapacity;

  // 已入住床位数
  int get occupiedBeds => totalCapacity - availableBeds;

  // 入住率
  double get occupancyRate => totalCapacity > 0 ? occupiedBeds / totalCapacity : 0.0;
}

class RoomResponse {
  final int code;
  final List<Room> data;
  final String message;

  RoomResponse({
    required this.code,
    required this.data,
    required this.message,
  });

  factory RoomResponse.fromJson(Map<String, dynamic> json) {
    return RoomResponse(
      code: json['code'],
      data: (json['data'] as List).map((e) => Room.fromJson(e)).toList(),
      message: json['message'],
    );
  }

  bool get isSuccess => code == 200;
}

// 区域配置类
class AreaConfig {
  final String code;
  final String name;
  final IconData icon;
  final Color color;

  const AreaConfig({
    required this.code,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<AreaConfig> allAreas = [
    AreaConfig(
      code: 'hy',
      name: '华严殿',
      icon: Icons.temple_buddhist,
      color: Color(0xFF07C160),
    ),
    AreaConfig(
      code: 'be',
      name: '报恩楼',
      icon: Icons.account_balance,
      color: Color(0xFF10AEFF),
    ),
    AreaConfig(
      code: 'zts',
      name: '斋堂上',
      icon: Icons.restaurant,
      color: Color(0xFFFFC300),
    ),
    AreaConfig(
      code: 'ktx',
      name: '客堂下',
      icon: Icons.meeting_room,
      color: Color(0xFFFA5151),
    ),
    AreaConfig(
      code: 'cz',
      name: '常住',
      icon: Icons.home,
      color: Color(0xFF8B5CF6),
    ),
    AreaConfig(
      code: 'ld',
      name: '老殿',
      icon: Icons.history,
      color: Color(0xFFF59E0B),
    ),
  ];

  static AreaConfig? getByCode(String code) {
    try {
      return allAreas.firstWhere((area) => area.code == code);
    } catch (e) {
      return null;
    }
  }

  static String getAreaName(String code) {
    final area = getByCode(code);
    return area?.name ?? code;
  }
}
