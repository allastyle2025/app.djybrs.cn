import 'package:flutter/material.dart';

class RoomCheckIn {
  final int id;
  final int roomId;
  final String roomArea;
  final String roomNumber;
  final int userId;
  final int bedNumber;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? status;
  final String? remark;
  final String cname;
  final String cgender;
  final String cphone;
  final int? cage;
  final String? purpose;
  final String? emergencyContactName;
  final String? emergencyContactRelation;
  final String? emergencyContactPhone;

  RoomCheckIn({
    required this.id,
    required this.roomId,
    required this.roomArea,
    required this.roomNumber,
    required this.userId,
    required this.bedNumber,
    required this.checkInTime,
    this.checkOutTime,
    this.status,
    this.remark,
    required this.cname,
    required this.cgender,
    required this.cphone,
    this.cage,
    this.purpose,
    this.emergencyContactName,
    this.emergencyContactRelation,
    this.emergencyContactPhone,
  });

  factory RoomCheckIn.fromJson(Map<String, dynamic> json) {
    return RoomCheckIn(
      id: json['id'],
      roomId: json['roomId'],
      roomArea: json['roomArea'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      userId: json['userId'],
      bedNumber: json['bedNumber'],
      checkInTime: DateTime.parse(json['checkInTime']),
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      status: json['status'],
      remark: json['remark'],
      cname: json['cname'],
      cgender: json['cgender'],
      cphone: json['cphone'],
      cage: json['cage'],
      purpose: json['purpose'],
      emergencyContactName: json['emergencyContactName'],
      emergencyContactRelation: json['emergencyContactRelation'],
      emergencyContactPhone: json['emergencyContactPhone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'roomArea': roomArea,
      'roomNumber': roomNumber,
      'userId': userId,
      'bedNumber': bedNumber,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'status': status,
      'remark': remark,
      'cname': cname,
      'cgender': cgender,
      'cphone': cphone,
      'cage': cage,
      'purpose': purpose,
      'emergencyContactName': emergencyContactName,
      'emergencyContactRelation': emergencyContactRelation,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }

  // 获取区域显示名称
  String get areaDisplayName {
    switch (roomArea) {
      case 'hy':
        return '华严殿';
      case 'yd':
        return '圆通殿';
      case 'be':
        return '报恩';
      case 'zts':
        return '斋堂上';
      case 'ktx':
        return '客堂下';
      case 'cz':
        return '常住';
      case 'ld':
        return '老殿';
      case 'other':
        return '其他';
      default:
        return roomArea;
    }
  }

  // 获取性别显示文本
  String get genderDisplayName {
    switch (cgender) {
      case 'male':
        return '男';
      case 'female':
        return '女';
      default:
        return cgender;
    }
  }

  // 获取性别颜色
  Color get genderColor {
    switch (cgender) {
      case 'male':
        return const Color(0xff42A5F5); // 男众亮蓝色
      case 'female':
        return const Color.fromARGB(255, 255, 107, 164); // 女众亮粉色
      default:
        return const Color(0xff999999);
    }
  }
}

class RoomCheckInResponse {
  final int code;
  final List<RoomCheckIn> data;
  final String message;

  RoomCheckInResponse({
    required this.code,
    required this.data,
    required this.message,
  });

  factory RoomCheckInResponse.fromJson(Map<String, dynamic> json) {
    return RoomCheckInResponse(
      code: json['code'],
      data: (json['data'] as List).map((item) => RoomCheckIn.fromJson(item)).toList(),
      message: json['message'],
    );
  }

  bool get isSuccess => code == 200;
}

// 历史入住记录模型
class CheckInHistory {
  final int id;
  final String roomArea;
  final String roomNumber;
  final int bedNumber;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status;

  CheckInHistory({
    required this.id,
    required this.roomArea,
    required this.roomNumber,
    required this.bedNumber,
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
  });

  factory CheckInHistory.fromJson(Map<String, dynamic> json) {
    // 优先从嵌套 room 对象解析，如果没有则直接从 json 解析
    final room = json['room'] ?? {};
    return CheckInHistory(
      id: json['id'],
      roomArea: room['roomArea'] ?? json['roomArea'] ?? '',
      roomNumber: room['roomNumber'] ?? json['roomNumber'] ?? '',
      bedNumber: json['bedNumber'],
      checkInTime: DateTime.parse(json['checkInTime']),
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      status: json['status'] ?? '',
    );
  }

  // 获取区域显示名称
  String get areaDisplayName {
    switch (roomArea) {
      case 'hy':
        return '华严殿';
      case 'yd':
        return '圆通殿';
      case 'other':
        return '其他';
      default:
        return roomArea;
    }
  }

  // 获取状态显示文本
  String get statusDisplayName {
    switch (status) {
      case 'CHECKED_IN':
        return '入住中';
      case 'CHECKED_OUT':
        return '已退房';
      default:
        return status;
    }
  }

  // 计算入住天数
  int get stayDays {
    final endTime = checkOutTime ?? DateTime.now();
    final difference = endTime.difference(checkInTime);
    return difference.inDays;
  }
}

// 历史入住记录响应模型
class CheckInHistoryResponse {
  final int code;
  final List<CheckInHistory> data;
  final String message;

  CheckInHistoryResponse({
    required this.code,
    required this.data,
    required this.message,
  });

  factory CheckInHistoryResponse.fromJson(Map<String, dynamic> json) {
    return CheckInHistoryResponse(
      code: json['code'],
      data: (json['data'] as List).map((item) => CheckInHistory.fromJson(item)).toList(),
      message: json['message'],
    );
  }

  bool get isSuccess => code == 200;
}
