import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

/// 本地消息存储服务
class LocalMessageService {
  static const String _messagesKey = 'local_messages';
  static const String _chatHistoryKey = 'chat_history_';

  /// 保存消息到本地存储
  static Future<void> saveMessage(Message message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 获取现有的消息列表
      final existingMessagesJson = prefs.getStringList(_messagesKey) ?? [];
      final List<Message> existingMessages = existingMessagesJson
          .map((json) => Message.fromJson(jsonDecode(json)))
          .toList();
      
      // 检查是否已有相同ID的消息
      final existingIndex = existingMessages.indexWhere(
        (msg) => msg.id == message.id
      );
      
      if (existingIndex >= 0) {
        // 更新现有消息（使用传入的完整状态）
        existingMessages[existingIndex] = message;
      } else {
        // 添加新消息
        existingMessages.add(message);
      }
      
      // 保存回本地存储
      final updatedMessagesJson = existingMessages
          .map((msg) => jsonEncode(msg.toJson()))
          .toList();
      
      await prefs.setStringList(_messagesKey, updatedMessagesJson);
      
      print('✅ 消息已保存到本地: ${message.content} (ID: ${message.id}, 已读: ${message.isRead}, 未读: ${message.unreadCount})');
    } catch (e) {
      print('❌ 保存消息到本地失败: $e');
    }
  }

  /// 从本地存储加载所有消息
  static Future<List<Message>> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getStringList(_messagesKey) ?? [];
      
      final messages = messagesJson
          .map((json) => Message.fromJson(jsonDecode(json)))
          .toList();
      
      // 按时间倒序排序
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      print('📥 从本地加载消息: ${messages.length} 条');
      for (final msg in messages) {
        print('   - ${msg.assistantName}: 已读=${msg.isRead}, 未读=${msg.unreadCount}');
      }
      return messages;
    } catch (e) {
      print('❌ 从本地加载消息失败: $e');
      return [];
    }
  }

  /// 获取总未读消息数
  static Future<int> getTotalUnreadCount() async {
    try {
      final messages = await loadMessages();
      // 消息列表中每个助手只有一条汇总记录，直接累加所有记录的unreadCount
      int total = 0;
      for (final msg in messages) {
        total += msg.unreadCount;
      }
      print('📊 总未读消息数: $total (来自 ${messages.length} 个助手)');
      return total;
    } catch (e) {
      print('❌ 获取总未读消息数失败: $e');
      return 0;
    }
  }

  /// 更新特定助手的所有消息的已读状态
  static Future<void> updateMessageStatus(String assistantId, {bool? isRead, int? unreadCount}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getStringList(_messagesKey) ?? [];
      
      final List<Message> messages = messagesJson
          .map((json) => Message.fromJson(jsonDecode(json)))
          .toList();
      
      // 更新该助手的所有消息的已读状态
      int updatedCount = 0;
      for (int i = 0; i < messages.length; i++) {
        if (messages[i].assistantId == assistantId) {
          messages[i] = Message(
            id: messages[i].id,
            senderId: messages[i].senderId,
            senderName: messages[i].senderName,
            senderAvatar: messages[i].senderAvatar,
            content: messages[i].content,
            timestamp: messages[i].timestamp,
            isRead: isRead ?? messages[i].isRead,
            type: messages[i].type,
            unreadCount: unreadCount ?? messages[i].unreadCount,
            assistantType: messages[i].assistantType,
            sourceId: messages[i].sourceId,
            extraData: messages[i].extraData,
          );
          updatedCount++;
        }
      }
      
      // 保存回本地存储
      final updatedMessagesJson = messages
          .map((msg) => jsonEncode(msg.toJson()))
          .toList();
      
      await prefs.setStringList(_messagesKey, updatedMessagesJson);
      
      print('📝 更新消息状态 (助手: $assistantId): 已读=$isRead, 未读=$unreadCount, 更新了 $updatedCount 条消息');
    } catch (e) {
      print('❌ 更新消息状态失败: $e');
    }
  }

  /// 保存聊天记录到特定助手
  static Future<void> saveChatMessage(String assistantId, Message message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_chatHistoryKey$assistantId';

      print('🐛 saveChatMessage - 助手ID: $assistantId, 消息ID: ${message.id}, 内容: ${message.content}');

      // 获取现有的聊天记录
      final existingChatJson = prefs.getStringList(key) ?? [];
      print('🐛 saveChatMessage - 现有 ${existingChatJson.length} 条消息');

      final List<Message> existingChat = existingChatJson
          .map((json) => Message.fromJson(jsonDecode(json)))
          .toList();

      // 检查是否已存在相同 ID 的消息（避免重复保存）
      final exists = existingChat.any((msg) => msg.id == message.id);
      if (exists) {
        print('🐛 saveChatMessage - 消息ID ${message.id} 已存在，跳过保存');
        return;
      }

      // 添加新消息
      existingChat.add(message);

      // 保存回本地存储
      final updatedChatJson = existingChat
          .map((msg) => jsonEncode(msg.toJson()))
          .toList();

      await prefs.setStringList(key, updatedChatJson);

      print('💬 聊天消息已保存 (助手: $assistantId): ${message.content}, 总共 ${existingChat.length} 条');
    } catch (e) {
      print('❌ 保存聊天消息失败: $e');
    }
  }

  /// 从本地存储加载特定助手的聊天记录
  static Future<List<Message>> loadChatHistory(String assistantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_chatHistoryKey$assistantId';
      final chatJson = prefs.getStringList(key) ?? [];
      
      print('🐛 loadChatHistory - 助手ID: $assistantId, 原始JSON条数: ${chatJson.length}');
      for (int i = 0; i < chatJson.length; i++) {
        print('🐛 loadChatHistory - JSON[$i]: ${chatJson[i]}');
      }
      
      final chatHistory = chatJson
          .map((json) => Message.fromJson(jsonDecode(json)))
          .toList();
      
      // 按时间正序排序（聊天记录应该按时间顺序显示）
      chatHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      print('🐛 loadChatHistory - 解析后 ${chatHistory.length} 条消息');
      for (int i = 0; i < chatHistory.length; i++) {
        final msg = chatHistory[i];
        print('🐛 loadChatHistory - 消息[$i]: ID=${msg.id}, content=${msg.content}');
      }
      
      print('💬 从本地加载聊天记录 (助手: $assistantId): ${chatHistory.length} 条');
      return chatHistory;
    } catch (e) {
      print('❌ 从本地加载聊天记录失败: $e');
      return [];
    }
  }

  /// 清空所有消息
  static Future<void> clearAllMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 清空消息列表
      await prefs.remove(_messagesKey);
      
      // 清空所有聊天记录
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_chatHistoryKey)) {
          await prefs.remove(key);
        }
      }
      
      print('🗑️ 所有本地消息已清空');
    } catch (e) {
      print('❌ 清空消息失败: $e');
    }
  }

  /// 清空特定助手的聊天记录
  static Future<void> clearChatHistory(String assistantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_chatHistoryKey$assistantId';
      
      // 清空该助手的聊天记录
      await prefs.remove(key);
      
      print('🗑️ 助手 $assistantId 的聊天记录已清空');
    } catch (e) {
      print('❌ 清空聊天记录失败: $e');
      throw e;
    }
  }
}