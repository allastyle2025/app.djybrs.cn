import 'package:flutter/material.dart';
import '../models/message.dart';
import '../room_colors.dart';
import '../utils/page_route.dart';
import 'chat_page.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => MessagePageState();
}

class MessagePageState extends State<MessagePage> {
  List<Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    setState(() {
      _messages = MockMessages.getMessages();
      _isLoading = false;
    });
  }

  void _markAsRead(Message message) {
    setState(() {
      _messages = _messages.map((msg) {
        if (msg.id == message.id) {
          return Message(
            id: msg.id,
            senderId: msg.senderId,
            senderName: msg.senderName,
            senderAvatar: msg.senderAvatar,
            content: msg.content,
            timestamp: msg.timestamp,
            isRead: true,
            type: msg.type,
          );
        }
        return msg;
      }).toList();
    });
  }

  void _deleteMessage(Message message) {
    setState(() {
      _messages.removeWhere((msg) => msg.id == message.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('消息已删除'),
        backgroundColor: RoomColors.available,
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      onDismissed: (direction) => _deleteMessage(message),
      child: GestureDetector(
        onTap: () {
          _markAsRead(message);
          // 跳转到聊天详情页面 - 使用iOS风格路由（自带手势返回）
          Navigator.push(
            context,
            IOSPageRoute(
              builder: (context) => ChatPage(
                senderId: message.senderId,
                senderName: message.senderName,
                senderAvatar: message.senderAvatar,
              ),
            ),
          );
        },
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
                        // 头像 - 微信样式圆角，使用网络图片
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6), // 微信风格的圆角
                          child: Image.network(
                            message.senderAvatar,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 48,
                                height: 48,
                                color: RoomColors.background,
                                child: const Icon(Icons.person, color: Colors.grey),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 48,
                                height: 48,
                                color: RoomColors.background,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            },
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
                                color: const Color(0xFFFA5151), // 微信红色
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
                                  message.senderName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
              Container(
                margin: const EdgeInsets.only(left: 76),
                height: 1,
                color: RoomColors.divider.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_outlined, size: 64, color: RoomColors.divider),
          const SizedBox(height: 16),
          Text(
            '暂无消息',
            style: TextStyle(color: RoomColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '新的消息将在这里显示',
            style: TextStyle(color: RoomColors.textGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // 右侧抽屉
  Widget _buildEndDrawer() {
    return Drawer(
      width: 280,
      child: SafeArea(
        child: Column(
          children: [
            // 抽屉头部
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: RoomColors.divider.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined, color: Colors.black87),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '消息设置',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            // 设置选项
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.mark_chat_read_outlined,
                    title: '全部已读',
                    onTap: () {
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
                        )).toList();
                      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          '消息',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('搜索功能开发中')),
              );
            },
          ),
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
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: RoomColors.primary))
            : RefreshIndicator(
                onRefresh: () async {
                  _loadMessages();
                },
                color: RoomColors.primary,
                child: _messages.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: _buildEmptyView(),
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
      ),
    );
  }
}