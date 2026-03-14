import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../room_colors.dart';
import '../services/message_service.dart';
import '../services/notification_service.dart';
import '../services/local_message_service.dart';
import '../utils/page_route.dart';
import 'chat_page.dart';
import 'dashboard_page.dart' show dashboardState, refreshBadge;

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => MessagePageState();
}

class MessagePageState extends State<MessagePage> {
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isConnected = false;
  StreamSubscription? _notificationSubscription;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenToNotifications();
  }

  /// 监听 SSE 通知（SSE连接由 Dashboard 统一管理）
  void _listenToNotifications() {
    // 监听连接状态
    _notificationService.connectionStatusStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });

    // 监听新消息
    _notificationSubscription = _notificationService.messageStream.listen(
      (newMessage) async {
        print('MessagePage 收到新消息: ${newMessage.content}');
        print('MessagePage 助手类型: ${newMessage.assistantType}');

        Message updatedMessage = newMessage; // 默认使用新消息
        
        setState(() {
          // 查找是否已有该助手的消息
          final existingIndex = _messages.indexWhere(
            (msg) => msg.assistantId == newMessage.assistantId,
          );

          if (existingIndex >= 0) {
            // 更新现有助手消息
            final existing = _messages[existingIndex];
            // 只有在消息是真正的新消息时才增加未读数量
            // 如果消息内容和时间都相同，说明是重复消息，不增加未读
            final isDuplicate = existing.content == newMessage.content && 
                               existing.timestamp == newMessage.timestamp;
            
            if (!isDuplicate) {
              // 新消息，增加未读数量
              updatedMessage = Message(
                id: existing.id,
                senderId: existing.senderId,
                senderName: existing.senderName,
                senderAvatar: existing.senderAvatar,
                content: newMessage.content,
                timestamp: newMessage.timestamp,
                isRead: false,
                type: existing.type,
                unreadCount: existing.unreadCount + 1,
                assistantType: existing.assistantType,
                sourceId: newMessage.sourceId,
                extraData: newMessage.extraData,
              );
            } else {
              // 重复消息，保持原有状态
              updatedMessage = existing;
            }
            
            _messages[existingIndex] = updatedMessage;
            // 移到顶部
            final updated = _messages.removeAt(existingIndex);
            _messages.insert(0, updated);
          } else {
            // 添加新助手消息
            updatedMessage = newMessage;
            _messages.insert(0, updatedMessage);
          }
        });

        // 保存更新后的消息到本地存储（消息列表）
        await LocalMessageService.saveMessage(updatedMessage);
        
        // 保存原始消息到聊天记录（聊天页面）
        print('🐛 MessagePage - 保存聊天记录: assistantId=${newMessage.assistantId}, id=${newMessage.id}');
        await LocalMessageService.saveChatMessage(newMessage.assistantId, newMessage);
        
        // 刷新 Dashboard 的 badge
        refreshBadge();
        
        // 显示通知提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newMessage.assistantName}: ${newMessage.content}'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: '查看',
                onPressed: () {
                  _openChat(newMessage);
                },
              ),
            ),
          );
        }
      },
      onError: (error) {
        print('MessagePage 通知流错误: $error');
      },
    );
    
    // 注意：SSE 连接由 Dashboard 统一管理，这里只监听消息流
    print('📡 MessagePage 只监听消息流，SSE连接由 Dashboard 管理');
  }

  /// 从本地存储或服务器加载消息列表
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 首先尝试从本地存储加载消息
      final localMessages = await LocalMessageService.loadMessages();
      
      if (localMessages.isNotEmpty) {
        // 按助手分组
        final groupedMessages = _groupMessagesByAssistant(localMessages);
        setState(() {
          _messages = groupedMessages;
          _isLoading = false;
        });
        print('📥 从本地加载消息成功: ${_messages.length} 个助手对话');
      } else {
        // 如果本地没有消息，尝试从服务器加载
        print('📡 本地无消息，尝试从服务器加载');
        final response = await MessageService.getMessages();

        if (response.isSuccess && response.data != null) {
          // 按助手分组
          final groupedMessages = _groupMessagesByAssistant(response.data!);
          setState(() {
            _messages = groupedMessages;
            _isLoading = false;
          });
          print('🌐 从服务器加载消息成功: ${_messages.length} 个助手对话');
        } else {
          // 如果 API 不存在或失败，使用空列表
          setState(() {
            _messages = [];
            _isLoading = false;
          });
          print('❌ 加载消息失败: ${response.message}');
        }
      }
    } catch (e) {
      print('❌ 加载消息异常: $e');
      setState(() {
        _messages = [];
        _isLoading = false;
      });
    }
  }

  /// 按助手分组消息
  List<Message> _groupMessagesByAssistant(List<Message> messages) {
    final Map<String, Message> assistantMap = {};

    for (final msg in messages) {
      final assistantId = msg.assistantId;

      if (assistantMap.containsKey(assistantId)) {
        // 更新该助手的最新消息
        final existing = assistantMap[assistantId]!;
        if (msg.timestamp.isAfter(existing.timestamp)) {
          assistantMap[assistantId] = Message(
            id: existing.id,
            senderId: existing.senderId,
            senderName: existing.senderName,
            senderAvatar: existing.senderAvatar,
            content: msg.content,
            timestamp: msg.timestamp,
            isRead: existing.isRead, // 保持原有的已读状态
            type: existing.type,
            unreadCount: existing.unreadCount, // 保持原有的未读数量
            assistantType: msg.assistantType,
            sourceId: msg.sourceId,
            extraData: msg.extraData,
          );
        }
      } else {
        assistantMap[assistantId] = msg;
      }
    }

    // 转换为列表并按时间排序
    final result = assistantMap.values.toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  /// 打开聊天页面
  void _openChat(Message message) async {
    _markAsRead(message);

    await Navigator.push(
      context,
      IOSPageRoute(
        builder: (context) => ChatPage(
          assistantType: message.assistantType,
          assistantId: message.assistantId,
          assistantName: message.assistantName,
          assistantAvatar: message.assistantAvatar,
          sourceId: message.sourceId,
        ),
      ),
    );
    
    // 从聊天页面返回后，刷新消息列表和Dashboard的badge
    _loadMessages();
    refreshBadge();
  }

  void _markAsRead(Message message) async {
    setState(() {
      final index = _messages.indexWhere((msg) => msg.assistantId == message.assistantId);
      if (index >= 0) {
        final msg = _messages[index];
        _messages[index] = Message(
          id: msg.id,
          senderId: msg.senderId,
          senderName: msg.senderName,
          senderAvatar: msg.senderAvatar,
          content: msg.content,
          timestamp: msg.timestamp,
          isRead: true,
          type: msg.type,
          unreadCount: 0,
          assistantType: msg.assistantType,
          sourceId: msg.sourceId,
          extraData: msg.extraData,
        );
      }
    });
    
    // 保存已读状态到本地存储
    await LocalMessageService.updateMessageStatus(
      message.assistantId,
      isRead: true,
      unreadCount: 0,
    );
  }

  void _deleteMessage(Message message) {
    setState(() {
      _messages.removeWhere((msg) => msg.assistantId == message.assistantId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('对话已删除'),
        backgroundColor: RoomColors.available,
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    return Dismissible(
      key: Key(message.assistantId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      onDismissed: (direction) => _deleteMessage(message),
      child: GestureDetector(
        onTap: () => _openChat(message),
        child: Container(
          color: Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // 头像带Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 头像 - 系统通知使用随机图片，其他使用图标
                        if (message.assistantType == AssistantType.system)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              'https://picsum.photos/seed/${message.id}/100/100',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.person, size: 24),
                                  ),
                            ),
                          )
                        else
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: message.assistantType == AssistantType.volunteer
                                  ? Colors.amber.withOpacity(0.15)
                                  : message.assistantType == AssistantType.room
                                      ? Colors.green.withOpacity(0.15)
                                      : RoomColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              message.assistantType == AssistantType.volunteer
                                  ? Icons.volunteer_activism_outlined
                                  : message.assistantType == AssistantType.room
                                      ? Icons.meeting_room_outlined
                                      : Icons.person,
                              color: message.assistantType == AssistantType.volunteer
                                  ? Colors.amber[700]
                                  : message.assistantType == AssistantType.room
                                      ? Colors.green[700]
                                      : RoomColors.primary,
                              size: 28,
                            ),
                          ),
                        // 未读消息数量Badge
                        if (message.unreadCount > 0)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              width: message.unreadCount > 9 ? 28 : 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFA5151),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  message.unreadCount > 99 ? '99+' : message.unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // 消息内容
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  message.assistantName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    //fontWeight: FontWeight.w600,
                                    color: RoomColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                message.timeDisplay,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: RoomColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: RoomColors.textSecondary,
                              fontWeight: message.isRead ? FontWeight.normal : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 分隔线
              Divider(
                height: 1,
                indent: 76,
                color: Colors.grey[200],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    // 注意：NotificationService 由 Dashboard 统一管理，这里不 dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            const Text(
              '消息',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            // 连接状态指示器
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          // 搜索按钮
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              // 搜索功能
            },
          ),
          // 更多按钮（打开抽屉）
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.black87),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: _buildEndDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadMessages,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _messages.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.message_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  '暂无消息',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageItem(_messages[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildEndDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: SafeArea(
        child: Column(
          children: [
            // 顶部标题栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      '消息设置',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // 设置项列表
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.done_all,
                    title: '全部已读',
                    onTap: () async {
                      setState(() {
                        _messages = _messages.map((msg) => Message(
                          id: msg.id,
                          senderId: msg.senderId,
                          senderName: msg.senderName,
                          senderAvatar: msg.senderAvatar,
                          content: msg.content,
                          timestamp: msg.timestamp,
                          isRead: true,
                          type: msg.type,
                          unreadCount: 0,
                          assistantType: msg.assistantType,
                          sourceId: msg.sourceId,
                          extraData: msg.extraData,
                        )).toList();
                      });
                      // 保存到本地存储并刷新badge
                      for (final msg in _messages) {
                        await LocalMessageService.updateMessageStatus(
                          msg.assistantId,
                          isRead: true,
                          unreadCount: 0,
                        );
                      }
                      refreshBadge();
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已全部标记为已读')),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.delete_sweep_outlined,
                    title: '清空消息',
                    color: RoomColors.occupied,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('确认清空'),
                          content: const Text('确定要清空所有消息吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _messages.clear();
                                });
                                Navigator.pop(context);
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('消息已清空')),
                                );
                              },
                              child: Text('确定', style: TextStyle(color: RoomColors.occupied)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildDrawerItem(
                    icon: Icons.notifications_outlined,
                    title: '消息通知',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('消息通知设置开发中')),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.block_outlined,
                    title: '屏蔽设置',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('屏蔽设置开发中')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildDrawerItem(
                    icon: Icons.refresh,
                    title: '重连 SSE',
                    onTap: () {
                      Navigator.of(context).pop();
                      _notificationService.disconnect();
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _notificationService.connect();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('SSE 重新连接中...')),
                        );
                      });
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.bug_report,
                    title: '测试消息',
                    onTap: () {
                      Navigator.of(context).pop();
                      // 手动添加测试消息
                      final testMessage = Message(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        senderId: 'system',
                        senderName: '测试通知',
                        senderAvatar: 'https://picsum.photos/seed/test/100/100',
                        content: '这是一条测试消息 - ${DateTime.now()}',
                        timestamp: DateTime.now(),
                        isRead: false,
                        type: MessageType.system,
                        unreadCount: 1,
                        assistantType: AssistantType.system,
                      );
                      setState(() {
                        _messages.insert(0, testMessage);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('测试消息已添加')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: color ?? Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }
}
