import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/room_check_in.dart';
import '../room_colors.dart';
import '../services/room_service.dart';

/// 入住详情底部抽屉弹窗组件
class CheckInDetailSheet extends StatefulWidget {
  final RoomCheckIn checkIn;
  final List<CheckInHistory> historyCheckIns;
  final VoidCallback? onCheckOut;
  final VoidCallback? onChangeRoom;
  final bool showCheckOutButton;
  final bool showChangeRoomButton;

  const CheckInDetailSheet({
    super.key,
    required this.checkIn,
    this.historyCheckIns = const [],
    this.onCheckOut,
    this.onChangeRoom,
    this.showCheckOutButton = true,
    this.showChangeRoomButton = true,
  });

  /// 显示底部抽屉弹窗
  static Future<void> show({
    required BuildContext context,
    required RoomCheckIn checkIn,
    List<CheckInHistory> historyCheckIns = const [],
    VoidCallback? onCheckOut,
    VoidCallback? onChangeRoom,
    bool showCheckOutButton = true,
    bool showChangeRoomButton = true,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CheckInDetailSheet(
        checkIn: checkIn,
        historyCheckIns: historyCheckIns,
        onCheckOut: onCheckOut,
        onChangeRoom: onChangeRoom,
        showCheckOutButton: showCheckOutButton,
        showChangeRoomButton: showChangeRoomButton,
      ),
    );
  }

  @override
  State<CheckInDetailSheet> createState() => _CheckInDetailSheetState();
}

class _CheckInDetailSheetState extends State<CheckInDetailSheet> {
  late RoomCheckIn checkIn;
  late List<CheckInHistory> historyCheckIns;

  @override
  void initState() {
    super.initState();
    checkIn = widget.checkIn;
    historyCheckIns = widget.historyCheckIns;
  }

  VoidCallback? get onCheckOut => widget.onCheckOut;
  VoidCallback? get onChangeRoom => widget.onChangeRoom;
  bool get showCheckOutButton => widget.showCheckOutButton;
  bool get showChangeRoomButton => widget.showChangeRoomButton;

  @override
  Widget build(BuildContext context) {
    // 计算已入住天数
    final days = DateTime.now().difference(checkIn.checkInTime).inDays;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RoomColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖动条
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: RoomColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 卡片头部
            _buildHeaderCard(days),
            const SizedBox(height: 16),
            // Tab 切换区域
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    // Tab 标签栏
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: RoomColors.tabBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TabBar(
                        indicator: UnderlineTabIndicator(
                          borderSide: BorderSide(
                            color: RoomColors.primary,
                            width: 3,
                          ),
                          insets: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        indicatorSize: TabBarIndicatorSize.label,
                        dividerColor: Colors.transparent,
                        labelColor: RoomColors.primary,
                        unselectedLabelColor: RoomColors.tabNormal,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        tabAlignment: TabAlignment.fill,
                        tabs: const [
                          Tab(text: '详细信息'),
                          Tab(text: '历史入住'),
                          Tab(text: '备注'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tab 内容区域
                    Expanded(
                      child: TabBarView(
                        children: [
                          // 详细信息 Tab - 两列网格布局
                          SingleChildScrollView(
                            child: Column(
                              children: [
                                // 基本信息卡片
                                _buildDetailCard('基本信息', [
                                  _buildDetailGridItem('用户ID', '${checkIn.userId}'),
                                  _buildDetailGridItem('姓名', checkIn.cname),
                                  _buildDetailGridItem('性别', checkIn.genderDisplayName),
                                  _buildDetailGridItem(
                                    '电话',
                                    checkIn.cphone,
                                    onTap: () async {
                                      final phoneNumber = checkIn.cphone;
                                      if (phoneNumber != null && phoneNumber.isNotEmpty) {
                                        final telUrl = 'tel:$phoneNumber';
                                        if (await canLaunchUrl(Uri.parse(telUrl))) {
                                          await launchUrl(Uri.parse(telUrl));
                                        }
                                      }
                                    },
                                  ),
                                  _buildDetailGridItem('年龄', checkIn.cage?.toString() ?? '-'),
                                ]),
                                const SizedBox(height: 16),
                                // 入住信息卡片
                                _buildDetailCard('入住信息', [
                                  _buildDetailGridItem('入住ID', '${checkIn.id}'),
                                  _buildDetailGridItem('区域', checkIn.areaDisplayName),
                                  _buildDetailGridItem('房间号', checkIn.roomNumber),
                                  _buildDetailGridItem('床位号', '${checkIn.bedNumber}号'),
                                  _buildDetailGridItem('已入住', _calculateStayDays(checkIn.checkInTime)),
                                ]),
                                const SizedBox(height: 16),
                                // 时间信息卡片
                                _buildDetailCard('时间信息', [
                                  _buildDetailGridItem('入住日期', _formatDate(checkIn.checkInTime)),
                                  _buildDetailGridItem('入住时间', _formatTime(checkIn.checkInTime)),
                                  if (checkIn.checkOutTime != null) ...[
                                    _buildDetailGridItem('退房日期', _formatDate(checkIn.checkOutTime!)),
                                    _buildDetailGridItem('退房时间', _formatTime(checkIn.checkOutTime!)),
                                  ],
                                ]),
                              ],
                            ),
                          ),
                          // 历史入住 Tab
                          _buildHistoryTab(),
                          // 备注 Tab
                          SingleChildScrollView(
                            child: _buildRemarksTab(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 按钮区域
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// 构建头部卡片
  Widget _buildHeaderCard(int days) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 头像（性别图标）
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: checkIn.genderColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Icon(
                    checkIn.cgender == 'male' ? Icons.person : Icons.person,
                    size: 28,
                    color: checkIn.genderColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 姓名、性别标签
                    Row(
                      children: [
                        Text(
                          checkIn.cname,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: RoomColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: checkIn.genderColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                checkIn.cgender == 'male' ? Icons.male : Icons.female,
                                size: 12,
                                color: checkIn.genderColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                checkIn.genderDisplayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: checkIn.genderColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 手机号
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: RoomColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          checkIn.cphone,
                          style: TextStyle(
                            fontSize: 13,
                            color: RoomColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 已入住天数标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RoomColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  days == 0 ? '今天' : '${days}天',
                  style: TextStyle(
                    fontSize: 11,
                    color: RoomColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 底部信息栏
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: RoomColors.cardBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.meeting_room_outlined,
                      size: 12,
                      color: RoomColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${checkIn.areaDisplayName}-${checkIn.roomNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        color: RoomColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: RoomColors.cardBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bed_outlined,
                      size: 12,
                      color: RoomColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${checkIn.bedNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        color: RoomColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '入住: ${_formatDate(checkIn.checkInTime)}',
                style: TextStyle(
                  fontSize: 12,
                  color: RoomColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建详情卡片
  Widget _buildDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: RoomColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: RoomColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 两列网格
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: children,
          ),
        ],
      ),
    );
  }

  /// 构建详情网格项
  Widget _buildDetailGridItem(String label, String value, {VoidCallback? onTap}) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: RoomColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: RoomColors.textSecondary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: onTap != null ? RoomColors.primary : RoomColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }

  /// 格式化时间
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 构建历史入住 Tab
  Widget _buildHistoryTab() {
    if (historyCheckIns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: RoomColors.textGrey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无历史入住记录',
              style: TextStyle(
                fontSize: 14,
                color: RoomColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: historyCheckIns.length,
      itemBuilder: (context, index) {
        final history = historyCheckIns[index];
        final isCheckedOut = history.checkOutTime != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：房间信息和状态
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bed_outlined,
                        size: 18,
                        color: RoomColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${history.areaDisplayName} - ${history.roomNumber}号',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: RoomColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCheckedOut
                              ? RoomColors.textSecondary.withOpacity(0.1)
                              : RoomColors.available.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isCheckedOut ? '已退房' : '在住',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isCheckedOut ? RoomColors.textSecondary : RoomColors.available,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '#${history.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: RoomColors.textGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // 入住/退房时间
              Row(
                children: [
                  Expanded(
                    child: _buildHistoryTimeItem(
                      '入住',
                      _formatDate(history.checkInTime),
                      _formatTime(history.checkInTime),
                      RoomColors.primary,
                    ),
                  ),
                  if (history.checkOutTime != null)
                    Expanded(
                      child: _buildHistoryTimeItem(
                        '退房',
                        _formatDate(history.checkOutTime!),
                        _formatTime(history.checkOutTime!),
                        RoomColors.occupied,
                      ),
                    ),
                ],
              ),
              // 备注字段暂时隐藏（CheckInHistory 模型中不存在）
              // if (history.remark != null && history.remark!.isNotEmpty) ...[
              //   const SizedBox(height: 8),
              //   Container(
              //     padding: const EdgeInsets.all(8),
              //     decoration: BoxDecoration(
              //       color: RoomColors.background,
              //       borderRadius: BorderRadius.circular(6),
              //     ),
              //     child: Row(
              //       children: [
              //         Icon(
              //           Icons.notes,
              //           size: 14,
              //           color: RoomColors.textSecondary,
              //         ),
              //         const SizedBox(width: 6),
              //         Expanded(
              //           child: Text(
              //             history.remark!,
              //             style: TextStyle(
              //               fontSize: 12,
              //               color: RoomColors.textSecondary,
              //             ),
              //             maxLines: 2,
              //             overflow: TextOverflow.ellipsis,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ],
            ],
          ),
        );
      },
    );
  }

  /// 构建历史记录时间项
  Widget _buildHistoryTimeItem(String label, String date, String time, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: RoomColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: RoomColors.textPrimary,
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: RoomColors.textGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建备注 Tab
  Widget _buildRemarksTab() {
    final hasRemark = checkIn.remark != null && checkIn.remark!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: hasRemark
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '当前备注',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: RoomColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEditRemarkDialog(),
                      icon: Icon(Icons.edit, size: 16, color: RoomColors.primary),
                      label: Text(
                        '编辑',
                        style: TextStyle(color: RoomColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: RoomColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    checkIn.remark!,
                    style: TextStyle(
                      fontSize: 14,
                      color: RoomColors.textPrimary,
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 48,
                    color: RoomColors.textGrey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无备注信息',
                    style: TextStyle(
                      fontSize: 14,
                      color: RoomColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showEditRemarkDialog(),
                    icon: Icon(Icons.add, color: Colors.white),
                    label: Text('添加备注'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RoomColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// 显示编辑备注对话框
  void _showEditRemarkDialog() {
    final TextEditingController controller = TextEditingController(
      text: checkIn.remark ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(checkIn.remark != null && checkIn.remark!.isNotEmpty ? '编辑备注' : '添加备注'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: '请输入备注内容',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newRemark = controller.text.trim();
              Navigator.pop(context);
              await _updateRemark(newRemark);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RoomColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 更新备注
  Future<void> _updateRemark(String remark) async {
    try {
      final response = await RoomService.updateCheckInRemark(checkIn.id, remark);
      if (response.isSuccess) {
        // 更新本地数据
        setState(() {
          checkIn = RoomCheckIn(
            id: checkIn.id,
            roomId: checkIn.roomId,
            roomArea: checkIn.roomArea,
            roomNumber: checkIn.roomNumber,
            userId: checkIn.userId,
            bedNumber: checkIn.bedNumber,
            checkInTime: checkIn.checkInTime,
            checkOutTime: checkIn.checkOutTime,
            status: checkIn.status,
            remark: remark,
            cname: checkIn.cname,
            cgender: checkIn.cgender,
            cphone: checkIn.cphone,
            cage: checkIn.cage,
            purpose: checkIn.purpose,
            emergencyContactName: checkIn.emergencyContactName,
            emergencyContactRelation: checkIn.emergencyContactRelation,
            emergencyContactPhone: checkIn.emergencyContactPhone,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备注更新成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备注更新失败: ${response.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失败: $e')),
      );
    }
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context) {
    final buttons = <Widget>[];

    // 更换房间按钮
    if (showChangeRoomButton) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              print('=== CheckInDetailSheet: 换房按钮被点击 ===');
              print('=== CheckInDetailSheet: onChangeRoom = $onChangeRoom ===');
              Navigator.pop(context);
              print('=== CheckInDetailSheet: 抽屉已关闭，准备调用 onChangeRoom ===');
              onChangeRoom?.call();
              print('=== CheckInDetailSheet: onChangeRoom 调用完成 ===');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RoomColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text('换房'),
          ),
        ),
      );
    }

    // 退房按钮
    if (showCheckOutButton) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onCheckOut?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RoomColors.occupied,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.exit_to_app, size: 18),
            label: const Text('退房'),
          ),
        ),
      );
    }

    // 关闭按钮
    if (buttons.isNotEmpty) buttons.add(const SizedBox(width: 8));
    buttons.add(
      Expanded(
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: RoomColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: RoomColors.divider),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('关闭'),
        ),
      ),
    );

    return Row(
      children: buttons,
    );
  }

  /// 计算入住天数
  String _calculateStayDays(DateTime checkInTime) {
    final now = DateTime.now();
    final difference = now.difference(checkInTime);
    final days = difference.inDays;

    if (days == 0) {
      final hours = difference.inHours;
      if (hours == 0) {
        final minutes = difference.inMinutes;
        return '$minutes分钟';
      }
      return '$hours小时';
    } else if (days < 30) {
      return '$days天';
    } else if (days < 365) {
      final months = (days / 30).floor();
      return '$months个月';
    } else {
      final years = (days / 365).floor();
      return '$years年';
    }
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
