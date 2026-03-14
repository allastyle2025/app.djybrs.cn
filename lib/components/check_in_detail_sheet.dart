import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/room_check_in.dart';
import '../room_colors.dart';
import '../services/room_service.dart';
import '../services/room_data_notifier.dart';

/// 入住详情底部抽屉弹窗组件
class CheckInDetailSheet extends StatefulWidget {
  final RoomCheckIn checkIn;
  final List<CheckInHistory> historyCheckIns;
  final VoidCallback? onCheckOut;
  final VoidCallback? onChangeRoom;
  final VoidCallback? onPurposeUpdated;
  final VoidCallback? onRoomChanged; // 房间更换后回调
  final bool showCheckOutButton;
  final bool showChangeRoomButton;

  const CheckInDetailSheet({
    super.key,
    required this.checkIn,
    this.historyCheckIns = const [],
    this.onCheckOut,
    this.onChangeRoom,
    this.onPurposeUpdated,
    this.onRoomChanged,
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
    VoidCallback? onPurposeUpdated,
    VoidCallback? onRoomChanged,
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
        onPurposeUpdated: onPurposeUpdated,
        onRoomChanged: onRoomChanged,
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
  late Future<void> _loadDataFuture;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _isExpanded = false;
  late StreamSubscription<void> _dataChangeSubscription;

  @override
  void initState() {
    super.initState();
    checkIn = widget.checkIn;
    historyCheckIns = widget.historyCheckIns;
    _loadDataFuture = _loadData();
    
    // 订阅数据变更通知
    _dataChangeSubscription = RoomDataNotifier().onDataChanged.listen((_) {
      print('=== CheckInDetailSheet: 收到数据变更通知，重新加载入住信息 ===');
      _reloadCheckInData();
    });
  }

  @override
  void dispose() {
    _dataChangeSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    // 模拟加载延迟，让加载效果更明显
    await Future.delayed(const Duration(milliseconds: 300));
  }

  VoidCallback? get onCheckOut => widget.onCheckOut;
  VoidCallback? get onChangeRoom => widget.onChangeRoom;
  VoidCallback? get onPurposeUpdated => widget.onPurposeUpdated;
  VoidCallback? get onRoomChanged => widget.onRoomChanged;
  bool get showCheckOutButton => widget.showCheckOutButton;
  bool get showChangeRoomButton => widget.showChangeRoomButton;

  // 重新加载入住信息
  Future<void> _reloadCheckInData() async {
    print('=== CheckInDetailSheet: 开始重新加载入住信息，checkIn.id = ${checkIn.id} ===');
    final response = await RoomService.getCheckInDetail(checkIn.id);
    print('=== CheckInDetailSheet: API 响应 isSuccess = ${response.isSuccess}, data.length = ${response.data.length} ===');
    if (response.isSuccess && response.data.isNotEmpty) {
      print('=== CheckInDetailSheet: 成功获取新数据，准备更新状态 ===');
      setState(() {
        checkIn = response.data[0];
        print('=== CheckInDetailSheet: 状态更新完成，新房间号 = ${checkIn.roomNumber} ===');
      });
    } else {
      print('=== CheckInDetailSheet: 加载失败，message = ${response.message} ===');
    }
  }

  @override
  void didUpdateWidget(CheckInDetailSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当widget更新时，重新加载数据
    if (widget.checkIn.id != oldWidget.checkIn.id) {
      checkIn = widget.checkIn;
      _loadDataFuture = _loadData();
    }
  }

@override
Widget build(BuildContext context) {
  // 计算已入住天数
  final days = DateTime.now().difference(checkIn.checkInTime).inDays;

  return SafeArea(
    child: ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: FutureBuilder<void>(
        future: _loadDataFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RoomColors.cardBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                Column(
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
                    // 卡片头部（固定显示，不受加载影响）
                    _buildHeaderCard(days),
                    const SizedBox(height: 16),
                    // Tab 切换区域
                    Expanded(
                      child: isLoading
                          ? _buildLoadingView()
                          : DefaultTabController(
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
                                        insets: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
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
                                        Tab(text: '备注'),
                                        Tab(text: '历史入住'),
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
                                                _buildDetailGridItem(
                                                  '姓名',
                                                  checkIn.cname,
                                                ),
                                                _buildDetailGridItem(
                                                  '身份',
                                                  _mapPurposeToDisplay(checkIn.purpose),
                                                  onTap: () => _showPurposeEditDialog(),
                                                ),
                                                _buildDetailGridItem(
                                                  '电话',
                                                  _formatPhoneNumber(checkIn.cphone),
                                                  onTap: () => _showCallConfirmDialog(checkIn.cphone),
                                                ),
                                              ]),
                                              const SizedBox(height: 16),
                                              // 入住信息卡片
                                              _buildDetailCard('入住信息', [
                                                _buildDetailGridItem(
                                                  '位置',
                                                  '${checkIn.areaDisplayName}-${checkIn.roomNumber}',
                                                ),
                                                _buildDetailGridItem(
                                                  '床位号',
                                                  '${checkIn.bedNumber}号',
                                                ),
                                                _buildDetailGridItem(
                                                  '已入住',
                                                  _calculateStayDays(
                                                    checkIn.checkInTime,
                                                  ),
                                                ),
                                                _buildDetailGridItem(
                                                  '入住时间',
                                                  '${_formatDate(checkIn.checkInTime)} ${_formatTime(checkIn.checkInTime)}',
                                                  onTap: () => _showCheckInTimeEditDialog(),
                                                ),
                                                if (checkIn.checkOutTime != null) ...[
                                                  _buildDetailGridItem(
                                                    '退床时间',
                                                    '${_formatDate(checkIn.checkOutTime!)} ${_formatTime(checkIn.checkOutTime!)}',
                                                  ),
                                                ],
                                              ]),
                                              const SizedBox(height: 16),
                                              // 系统信息卡片
                                              _buildDetailCard('系统信息', [
                                                _buildDetailGridItem(
                                                  '用户ID',
                                                  '${checkIn.userId}',
                                                ),
                                                _buildDetailGridItem(
                                                  '入住ID',
                                                  '${checkIn.id}',
                                                ),
                                              ]),
                                              const SizedBox(height: 80),
                                            ],
                                          ),
                                        ),
                                        // 备注 Tab
                                        SingleChildScrollView(
                                          child: _buildRemarksTab(),
                                        ),
                                        // 历史入住 Tab
                                        _buildHistoryTab(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
                // 右下角悬浮更多按钮
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 展开的按钮
                      if (_isExpanded) ...[
                        // 退床按钮
                        if (showCheckOutButton) ...[
                          FloatingActionButton.extended(
                            onPressed: () {
                              setState(() {
                                _isExpanded = false;
                              });
                              onCheckOut?.call();
                            },
                            heroTag: 'check_out',
                            backgroundColor: RoomColors.occupied,
                            foregroundColor: Colors.white,
                            label: const Text('退床'),
                            icon: const Icon(Icons.exit_to_app),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // 换房按钮
                        if (showChangeRoomButton) ...[
                          FloatingActionButton.extended(
                            onPressed: () {
                              setState(() {
                                _isExpanded = false;
                              });
                              // 传递房间更换完成的回调
                              onChangeRoom?.call();
                              // 房间更换完成后，重新加载当前入住信息
                              Future.delayed(const Duration(seconds: 1), () {
                                _reloadCheckInData();
                              });
                            },
                            heroTag: 'change_room',
                            backgroundColor: RoomColors.primary,
                            foregroundColor: Colors.white,
                            label: const Text('换房'),
                            icon: const Icon(Icons.swap_horiz),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                      // 主按钮
                      FloatingActionButton(
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        heroTag: 'more',
                        backgroundColor: RoomColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        child: Icon(_isExpanded ? Icons.close : Icons.more_vert),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }, // 这里需要闭合 builder 回调
      ), // 这里需要闭合 FutureBuilder
    ), // 这里需要闭合 ScaffoldMessenger
  ); // 这里需要闭合 SafeArea
}

  /// 构建加载视图
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: RoomColors.primary, strokeWidth: 3),
          const SizedBox(height: 16),
          Text(
            '加载中...',
            style: TextStyle(fontSize: 14, color: RoomColors.textSecondary),
          ),
        ],
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: checkIn.genderColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                checkIn.cgender == 'male'
                                    ? Icons.male
                                    : Icons.female,
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
                              if (checkIn.cage != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${checkIn.cage}岁',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: RoomColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
                          _formatPhoneNumber(checkIn.cphone),
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
                  style: TextStyle(fontSize: 11, color: RoomColors.primary),
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
                style: TextStyle(fontSize: 12, color: RoomColors.textGrey),
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
  Widget _buildDetailGridItem(
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
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
            style: TextStyle(fontSize: 10, color: RoomColors.textSecondary),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: onTap != null
                  ? RoomColors.primary
                  : RoomColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
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
              style: TextStyle(fontSize: 14, color: RoomColors.textGrey),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isCheckedOut
                              ? RoomColors.textSecondary.withOpacity(0.1)
                              : RoomColors.available.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isCheckedOut ? '已退床位' : '在住',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isCheckedOut
                                ? RoomColors.textSecondary
                                : RoomColors.available,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '#${history.id}',
                    style: TextStyle(fontSize: 12, color: RoomColors.textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // 入住/退床时间
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
                        '退床',
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
  Widget _buildHistoryTimeItem(
    String label,
    String date,
    String time,
    Color color,
  ) {
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
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: RoomColors.textSecondary),
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
              style: TextStyle(fontSize: 11, color: RoomColors.textGrey),
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
                      icon: Icon(
                        Icons.edit,
                        size: 16,
                        color: RoomColors.primary,
                      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 14,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          checkIn.remark!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
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
                    style: TextStyle(fontSize: 14, color: RoomColors.textGrey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showEditRemarkDialog(),
                    icon: Icon(Icons.add, color: Colors.white),
                    label: Text('添加备注'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RoomColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
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
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: RoomColors.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: RoomColors.divider, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      color: RoomColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      checkIn.remark != null && checkIn.remark!.isNotEmpty
                          ? '编辑备注'
                          : '添加备注',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: RoomColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // 内容区域
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: controller,
                  maxLines: 6,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '请输入备注内容...',
                    hintStyle: TextStyle(
                      color: RoomColors.textGrey,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: RoomColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: RoomColors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: RoomColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
              // 按钮区域
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: RoomColors.divider, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RoomColors.textSecondary,
                          side: BorderSide(color: RoomColors.divider),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('取消', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final newRemark = controller.text.trim();
                          Navigator.pop(context);
                          await _updateRemark(newRemark);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RoomColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '保存',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示身份编辑对话框
  void _showPurposeEditDialog() {
    final List<Map<String, String>> purposes = [
      {'value': 'volunteer', 'label': '义工'},
      {'value': 'study', 'label': '学修'},
      {'value': 'permanent', 'label': '常住'},
      {'value': 'master', 'label': '师父'},
      {'value': 'other', 'label': '其它'},
    ];

    String? selectedPurpose = checkIn.purpose;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('修改身份'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: purposes.map((item) {
              final isSelected = selectedPurpose == item['value'];
              return ListTile(
                title: Text(item['label']!),
                leading: Radio<String>(
                  value: item['value']!,
                  groupValue: selectedPurpose,
                  onChanged: (value) {
                    setState(() {
                      selectedPurpose = value;
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    selectedPurpose = item['value'];
                  });
                },
                selected: isSelected,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: selectedPurpose == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      _updatePurpose(selectedPurpose!);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: RoomColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('确认修改'),
            ),
          ],
        ),
      ),
    );
  }

  /// 更新身份
  Future<void> _updatePurpose(String purpose) async {
    try {
      final response = await RoomService.updateCheckInPurpose(
        checkIn.id,
        purpose,
      );
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
            remark: checkIn.remark,
            cname: checkIn.cname,
            cgender: checkIn.cgender,
            cphone: checkIn.cphone,
            cage: checkIn.cage,
            purpose: purpose,
            emergencyContactName: checkIn.emergencyContactName,
            emergencyContactRelation: checkIn.emergencyContactRelation,
            emergencyContactPhone: checkIn.emergencyContactPhone,
          );
        });
        _scaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('身份更新成功')));
        // 通知父级刷新
        onPurposeUpdated?.call();
      } else {
        _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('身份更新失败: ${response.message}')));
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('更新失败: $e')));
    }
  }

  /// 显示入住时间编辑对话框
  void _showCheckInTimeEditDialog() {
    DateTime selectedDate = checkIn.checkInTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(checkIn.checkInTime);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('修改入住时间'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 日期选择
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('日期'),
                subtitle: Text(
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
              // 时间选择
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('时间'),
                subtitle: Text(
                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedTime = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final newDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                Navigator.pop(context);
                _updateCheckInTime(newDateTime);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RoomColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('确认修改'),
            ),
          ],
        ),
      ),
    );
  }

  /// 更新入住时间
  Future<void> _updateCheckInTime(DateTime checkInTime) async {
    try {
      final response = await RoomService.updateCheckInTime(
        checkIn.id,
        checkInTime,
      );
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
            checkInTime: checkInTime,
            checkOutTime: checkIn.checkOutTime,
            status: checkIn.status,
            remark: checkIn.remark,
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
        _scaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('入住时间更新成功')));
        // 通知父级刷新
        onPurposeUpdated?.call();
      } else {
        _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('入住时间更新失败: ${response.message}')));
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('更新失败: $e')));
    }
  }

  /// 更新备注
  Future<void> _updateRemark(String remark) async {
    try {
      final response = await RoomService.updateCheckInRemark(
        checkIn.id,
        remark,
      );
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
        _scaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('备注更新成功')));
        // 通知父级刷新
        onPurposeUpdated?.call();
      } else {
        _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('备注更新失败: ${response.message}')));
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('更新失败: $e')));
    }
  }

  /// 格式化电话号码为 123 4567 8901
  String _formatPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) return '-';
    // 移除所有非数字字符
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      // 11位手机号：3-4-4 分段
      return '${digits.substring(0, 3)} ${digits.substring(3, 7)} ${digits.substring(7)}';
    } else if (digits.length == 10) {
      // 10位号码：3-3-4 分段
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    } else if (digits.length == 8) {
      // 8位固话：4-4 分段
      return '${digits.substring(0, 4)} ${digits.substring(4)}';
    }
    // 其他长度直接返回原值
    return phoneNumber;
  }

  /// 显示拨号确认对话框
  void _showCallConfirmDialog(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认拨号'),
        content: Text('是否拨打：${_formatPhoneNumber(phoneNumber)}？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final telUrl = 'tel:$phoneNumber';
              if (await canLaunchUrl(Uri.parse(telUrl))) {
                await launchUrl(Uri.parse(telUrl));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RoomColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('拨号'),
          ),
        ],
      ),
    );
  }

  /// 将 purpose 映射为显示文本
  String _mapPurposeToDisplay(String? purpose) {
    switch (purpose) {
      case 'volunteer':
        return '义工';
      case 'study':
        return '学修';
      case 'permanent':
        return '常住';
      case 'master':
        return '师父';
      case 'other':
        return '其它';
      default:
        return purpose ?? '-';
    }
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
    final now = DateTime.now();
    // 如果不是今年，显示年份
    if (date.year != now.year) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    return '${date.month}/${date.day}';
  }
}
