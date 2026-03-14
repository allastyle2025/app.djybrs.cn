import 'package:flutter/material.dart';

/// 助手类型
enum AssistantType {
  volunteer,   // 义工申请小助手
  room,        // 房间小助手
  allasGroup,  // allas群消息
  system,      // 系统通知
}

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final int unreadCount;
  
  // 新增：助手相关字段
  final AssistantType assistantType;  // 助手类型
  final String? sourceId;             // 关联ID（义工申请ID或入住登记ID）
  final Map<String, dynamic>? extraData; // 额外数据

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.unreadCount = 0,
    this.assistantType = AssistantType.system,
    this.sourceId,
    this.extraData,
  });

  // 格式化时间显示
  String get timeDisplay {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 7) {
      return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  // 获取助手ID（用于分组）
  String get assistantId {
    switch (assistantType) {
      case AssistantType.volunteer:
        return 'assistant_volunteer';
      case AssistantType.room:
        return 'assistant_room';
      case AssistantType.allasGroup:
        return 'assistant_allas_group';
      case AssistantType.system:
        return senderId;
    }
  }

  // 获取助手名称 - 使用 AssistantConfig 避免重复定义
  String get assistantName => AssistantConfig.getConfig(assistantType).name;

  // 获取助手头像 - 使用 AssistantConfig 避免重复定义
  String get assistantAvatar => AssistantConfig.getConfig(assistantType).avatar;

  // 从 JSON 创建消息对象
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? json['sender_id']?.toString() ?? 'system',
      senderName: json['senderName']?.toString() ?? json['sender_name']?.toString() ?? '系统通知',
      senderAvatar: json['senderAvatar']?.toString() ?? json['sender_avatar']?.toString() ?? 
          'https://picsum.photos/seed/system/100/100',
      content: json['content']?.toString() ?? json['message']?.toString() ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      type: _parseMessageType(json['type']?.toString()),
      unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
      assistantType: _parseAssistantType(json['assistantType']?.toString() ?? json['eventType']?.toString() ?? json['type']?.toString()),
      sourceId: json['sourceId']?.toString() ?? json['data']?['applicationId']?.toString() ?? json['data']?['checkInId']?.toString(),
      extraData: json['extraData'] as Map<String, dynamic>? ?? json['data'] as Map<String, dynamic>?,
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'type': type.toString().split('.').last,
      'unreadCount': unreadCount,
      'assistantType': assistantType.toString().split('.').last,
      'sourceId': sourceId,
      'extraData': extraData,
    };
  }

  // 解析消息类型
  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'voice':
        return MessageType.voice;
      case 'system':
        return MessageType.system;
      case 'text':
      default:
        return MessageType.text;
    }
  }

  // 解析助手类型
  static AssistantType _parseAssistantType(String? type) {
    switch (type) {
      case 'volunteer':
      case 'volunteer_application':
        return AssistantType.volunteer;
      case 'room':
      case 'room_checkin':
        return AssistantType.room;
      case 'allas_group':
      case 'allasGroup':
        return AssistantType.allasGroup;
      case 'system':
        return AssistantType.system;
      default:
        return AssistantType.system;
    }
  }
}

enum MessageType {
  text,    // 文本消息
  image,   // 图片消息
  voice,   // 语音消息
  system,  // 系统消息
}

/// 助手配置
class AssistantConfig {
  final AssistantType type;
  final String id;
  final String name;
  final String avatar;
  final String description;

  const AssistantConfig({
    required this.type,
    required this.id,
    required this.name,
    required this.avatar,
    required this.description,
  });

  static const volunteer = AssistantConfig(
    type: AssistantType.volunteer,
    id: 'assistant_volunteer',
    name: '新的义工申请',
    avatar: 'https://picsum.photos/seed/volunteer_assistant/100/100',
    description: '处理义工申请相关消息',
  );

  static const room = AssistantConfig(
    type: AssistantType.room,
    id: 'assistant_room',
    name: '房间小助手',
    avatar: 'https://picsum.photos/seed/room_assistant/100/100',
    description: '处理入住登记相关消息',
  );

  static const allasGroup = AssistantConfig(
    type: AssistantType.allasGroup,
    id: 'assistant_allas_group',
    name: 'Allas群消息',
    avatar: 'https://picsum.photos/seed/allas_group/100/100',
    description: 'Allas群组消息通知',
  );

  static AssistantConfig getConfig(AssistantType type) {
    switch (type) {
      case AssistantType.volunteer:
        return volunteer;
      case AssistantType.room:
        return room;
      case AssistantType.allasGroup:
        return allasGroup;
      case AssistantType.system:
        return const AssistantConfig(
          type: AssistantType.system,
          id: 'system',
          name: '系统通知',
          avatar: 'https://picsum.photos/seed/system/100/100',
          description: '系统消息',
        );
    }
  }
}
