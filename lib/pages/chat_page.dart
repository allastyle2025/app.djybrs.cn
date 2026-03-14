import 'package:flutter/material.dart';
import '../models/message.dart';
import '../room_colors.dart';
import '../services/local_message_service.dart';
import '../services/message_sender_service.dart';

class ChatPage extends StatefulWidget {
  final AssistantType assistantType;
  final String assistantId;
  final String assistantName;
  final String assistantAvatar;
  final String? sourceId;

  const ChatPage({
    super.key,
    required this.assistantType,
    required this.assistantId,
    required this.assistantName,
    required this.assistantAvatar,
    this.sourceId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isLoading = true;
  bool _isTextEmpty = true; // 输入框是否为空
  bool _isVoiceMode = false; // 是否为语音输入模式

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // 监听输入框文字变化
    _messageController.addListener(_onTextChanged);
  }

  /// 输入框文字变化回调
  void _onTextChanged() {
    final isEmpty = _messageController.text.trim().isEmpty;
    if (isEmpty != _isTextEmpty) {
      setState(() {
        _isTextEmpty = isEmpty;
      });
    }
  }

  /// 从本地存储加载聊天记录
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 从聊天记录加载当前助手的所有消息
      final chatHistory = await LocalMessageService.loadChatHistory(widget.assistantId);
      
      print('🐛 聊天页面 - 助手ID: ${widget.assistantId}');
      print('🐛 聊天页面 - 加载到 ${chatHistory.length} 条消息');
      for (int i = 0; i < chatHistory.length; i++) {
        final msg = chatHistory[i];
        print('🐛 消息[$i]: ID=${msg.id}, content=${msg.content}, assistantId=${msg.assistantId}, time=${msg.timestamp}');
      }
      
      setState(() {
        _messages.clear();
        _messages.addAll(chatHistory);
        _isLoading = false;
      });
      
      print('💬 从本地加载聊天记录成功: ${_messages.length} 条 (助手: ${widget.assistantName})');
      _scrollToBottom();
    } catch (e) {
      print('❌ 加载聊天记录异常: $e');
      setState(() {
        _messages.clear();
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 显示更多菜单
  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部拖动条
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // 菜单项
              _buildMenuItem(
                icon: Icons.person_outline,
                title: '查看详情',
                onTap: () {
                  Navigator.pop(context);
                  _showAssistantDetail();
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildMenuItem(
                icon: Icons.delete_outline,
                title: '清空聊天记录',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showClearChatConfirmDialog();
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildMenuItem(
                icon: Icons.notifications_off_outlined,
                title: '消息免打扰',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('消息免打扰设置开发中')),
                  );
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildMenuItem(
                icon: Icons.report_outlined,
                title: '投诉',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('投诉功能开发中')),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建菜单项
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: color ?? Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  /// 显示助手详情
  void _showAssistantDetail() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 顶部拖动条
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // 头像
            CircleAvatar(
              radius: 40,
              backgroundColor: _getAssistantColor().withOpacity(0.1),
              child: Icon(
                _getAssistantIcon(),
                size: 40,
                color: _getAssistantColor(),
              ),
            ),
            const SizedBox(height: 16),
            // 名称
            Text(
              widget.assistantName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // 类型标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getAssistantColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getAssistantTypeText(),
                style: TextStyle(
                  fontSize: 12,
                  color: _getAssistantColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 信息列表
            _buildInfoItem('助手ID', widget.assistantId),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildInfoItem('消息数量', '${_messages.length} 条'),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildInfoItem('创建时间', _formatDate(DateTime.now())),
            const Spacer(),
            // 关闭按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF07C160),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('关闭', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建信息项
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取助手颜色
  Color _getAssistantColor() {
    switch (widget.assistantType) {
      case AssistantType.volunteer:
        return const Color(0xFFFFA500); // 黄色
      case AssistantType.room:
        return const Color(0xFF4CAF50); // 绿色
      case AssistantType.allasGroup:
        return const Color(0xFF2196F3); // 蓝色
      case AssistantType.system:
      default:
        return const Color(0xFF07C160); // 微信绿
    }
  }

  /// 获取助手图标
  IconData _getAssistantIcon() {
    switch (widget.assistantType) {
      case AssistantType.volunteer:
        return Icons.volunteer_activism;
      case AssistantType.room:
        return Icons.meeting_room;
      case AssistantType.allasGroup:
        return Icons.group;
      case AssistantType.system:
      default:
        return Icons.notifications;
    }
  }

  /// 获取助手类型文本
  String _getAssistantTypeText() {
    switch (widget.assistantType) {
      case AssistantType.volunteer:
        return '义工申请助手';
      case AssistantType.room:
        return '房间小助手';
      case AssistantType.allasGroup:
        return 'Allas群助手';
      case AssistantType.system:
      default:
        return '系统通知';
    }
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 显示清空聊天记录确认对话框
  void _showClearChatConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空聊天记录'),
        content: Text('确定要清空与 ${widget.assistantName} 的所有聊天记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearChatHistory();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  /// 清空聊天记录
  Future<void> _clearChatHistory() async {
    try {
      await LocalMessageService.clearChatHistory(widget.assistantId);
      setState(() {
        _messages.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('聊天记录已清空')),
        );
      }
    } catch (e) {
      print('❌ 清空聊天记录失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('清空聊天记录失败')),
        );
      }
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // 先显示在本地
    final tempMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'user',
      senderName: '我',
      senderAvatar: '',
      content: text,
      timestamp: DateTime.now(),
      isRead: true,
      type: MessageType.text,
      unreadCount: 0,
      assistantType: widget.assistantType,
      sourceId: widget.sourceId,
    );

    setState(() {
      _messages.add(tempMessage);
      _messageController.clear();
    });
    _scrollToBottom();

    // 保存消息到本地存储
    await LocalMessageService.saveChatMessage(widget.assistantId, tempMessage);

    // 如果是 allasGroup 类型，发送到后端
    if (widget.assistantType == AssistantType.allasGroup) {
      await MessageSenderService.sendAllasGroupMessage(
        title: widget.assistantName,
        message: text,
      );
    }

    print('💬 发送消息到助手 ${widget.assistantName}: $text');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // 微信聊天背景色
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.assistantName,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black87),
            onPressed: _showMoreMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无消息',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final showTime = _shouldShowTimeDivider(index);
                          
                          return Column(
                            children: [
                              // 时间分隔线
                              if (showTime)
                                _buildTimeDivider(message.timestamp),
                              // 消息项
                              _buildMessageItem(message),
                            ],
                          );
                        },
                      ),
          ),
          // 底部输入栏 - 1:1复刻微信样式
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 语音/键盘切换按钮
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isVoiceMode = !_isVoiceMode;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[400]!, width: 0.5),
                      ),
                      child: Icon(
                        _isVoiceMode ? Icons.keyboard : Icons.mic,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 输入框或语音按钮
                  Expanded(
                    child: _isVoiceMode
                        ? GestureDetector(
                            onTapDown: (_) {},
                            onTapUp: (_) {},
                            onTapCancel: () {},
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey[300]!, width: 0.5),
                              ),
                              child: const Center(
                                child: Text(
                                  '按住 说话',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            constraints: const BoxConstraints(
                              minHeight: 40,
                              maxHeight: 120,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey[300]!, width: 0.5),
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: '请输入消息',
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  // 表情按钮
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(bottom: 4),
                      child: const Icon(
                        Icons.sentiment_satisfied_outlined,
                        color: Colors.black87,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 发送按钮或加号按钮
                  if (_isTextEmpty)
                    // 加号按钮（无文字时显示）
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(bottom: 4),
                        child: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.black87,
                          size: 28,
                        ),
                      ),
                    )
                  else
                    // 发送按钮（有文字时显示）
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 48,
                        height: 32,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF07C160), // 微信绿色
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text(
                            '发送',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 判断是否需要显示时间分隔线
  /// 规则：第一条消息显示时间，或者与上一条消息间隔超过5分钟
  bool _shouldShowTimeDivider(int index) {
    if (index == 0) return true; // 第一条消息总是显示时间
    
    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];
    
    final diff = currentMessage.timestamp.difference(previousMessage.timestamp);
    return diff.inMinutes >= 5; // 间隔5分钟以上显示时间
  }

  /// 构建时间分隔线（微信风格）
  Widget _buildTimeDivider(DateTime time) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _formatMessageTime(time),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  /// 格式化消息时间显示
  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);
    
    String dateStr;
    if (messageDate == today) {
      dateStr = '';
    } else if (messageDate == yesterday) {
      dateStr = '昨天 ';
    } else if (now.year == time.year) {
      dateStr = '${time.month}月${time.day}日 ';
    } else {
      dateStr = '${time.year}年${time.month}月${time.day}日 ';
    }
    
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return '$dateStr$timeStr';
  }

  Widget _buildMessageItem(Message message) {
    final isMe = message.senderId == 'user';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            // 对方头像（助手头像）- 与消息列表保持一致
            if (widget.assistantType == AssistantType.system || widget.assistantType == AssistantType.allasGroup)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  widget.assistantAvatar,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        width: 44,
                        height: 44,
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, size: 24),
                      ),
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.assistantType == AssistantType.volunteer
                      ? Colors.amber.withOpacity(0.15)
                      : widget.assistantType == AssistantType.room
                          ? Colors.green.withOpacity(0.15)
                          : RoomColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  widget.assistantType == AssistantType.volunteer
                      ? Icons.volunteer_activism_outlined
                      : widget.assistantType == AssistantType.room
                          ? Icons.meeting_room_outlined
                          : Icons.person,
                  color: widget.assistantType == AssistantType.volunteer
                      ? Colors.amber[700]
                      : widget.assistantType == AssistantType.room
                          ? Colors.green[700]
                          : RoomColors.primary,
                  size: 24,
                ),
              ),
            const SizedBox(width: 10),
          ],
          // 消息气泡
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF95EC69) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isMe 
                ? _buildMyMessageContent(message)
                : _buildAssistantMessageCard(message),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 10),
            // 我的头像
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 44,
                height: 44,
                color: RoomColors.primary,
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建我的消息内容（简单文本）
  Widget _buildMyMessageContent(Message message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        message.content,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }

  /// 构建助手消息卡片（现代化卡片设计）
  Widget _buildAssistantMessageCard(Message message) {
    // allasGroup 类型使用微信样式（简单文本）
    if (message.assistantType == AssistantType.allasGroup) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          message.content,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      );
    }

    // 从extraData中提取申请信息
    final extraData = message.extraData ?? {};
    final data = extraData['data'] ?? extraData;
    final applicantName = data['applicantName'] ?? data['name'] ?? '未知申请人';
    final applicantPhone = data['applicantPhone'] ?? data['phone'] ?? '';
    final applicationId = data['applicationId'] ?? data['checkInId'] ?? data['id'] ?? '';
    final applicantGender = data['gender']?.toString() ?? '';
    final applicantAge = data['age']?.toString() ?? '';

    // 从extraData的type字段或message.assistantType判断类型
    final eventType = extraData['type']?.toString() ?? '';
    final isVolunteer = eventType == 'volunteer_application' ||
                        message.assistantType == AssistantType.volunteer;

    // 根据类型选择主题色
    final themeColor = isVolunteer
        ? Colors.amber[700]!
        : message.assistantType == AssistantType.room
            ? Colors.green[700]!
            : RoomColors.primary;
    final themeColorLight = isVolunteer
        ? Colors.amber.withOpacity(0.1)
        : message.assistantType == AssistantType.room
            ? Colors.green.withOpacity(0.1)
            : RoomColors.primary.withOpacity(0.1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部标题栏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: themeColorLight,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isVolunteer
                    ? Icons.volunteer_activism_outlined
                    : Icons.meeting_room_outlined,
                  size: 18,
                  color: themeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isVolunteer ? '义工申请' : '入住登记',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: themeColor,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // 内容区域
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 申请人姓名
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '申请人：',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        applicantName.toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 性别和年龄
                if (applicantGender.isNotEmpty || applicantAge.isNotEmpty)
                  Row(
                    children: [
                      if (applicantGender.isNotEmpty) ...[
                        Icon(
                          applicantGender == 'male' ? Icons.male_outlined : Icons.female_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          applicantGender == 'male' ? '男' : '女',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                      if (applicantGender.isNotEmpty && applicantAge.isNotEmpty)
                        const SizedBox(width: 16),
                      if (applicantAge.isNotEmpty) ...[
                        Icon(
                          Icons.cake_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$applicantAge岁',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ],
                  ),
                if (applicantGender.isNotEmpty || applicantAge.isNotEmpty)
                  const SizedBox(height: 8),
                // 申请人电话（如果有）
                if (applicantPhone.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '电话：',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        applicantPhone.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                if (applicantPhone.isNotEmpty)
                  const SizedBox(height: 10),
                // 底部申请编号
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tag_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '申请编号：',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        applicationId.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时间显示
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      // 今天，只显示时间
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // 昨天
      return '昨天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      // 其他日期
      return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
