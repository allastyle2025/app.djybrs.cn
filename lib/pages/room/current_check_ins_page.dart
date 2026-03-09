import 'package:flutter/material.dart';
import '../../components/change_room_sheet.dart';
import '../../components/check_in_detail_sheet.dart';
import '../../models/room_check_in.dart';
import '../../room_colors.dart';
import '../../services/room_service.dart';
import '../../services/room_data_notifier.dart';

class CurrentCheckInsPage extends StatefulWidget {
  final VoidCallback? onDataChanged;
  
  const CurrentCheckInsPage({super.key, this.onDataChanged});

  @override
  State<CurrentCheckInsPage> createState() => _CurrentCheckInsPageState();
}

class _CurrentCheckInsPageState extends State<CurrentCheckInsPage> {
  List<RoomCheckIn> _checkIns = [];
  bool _isLoading = true;
  String _errorMessage = '';

  //头像显示变量
  bool _showAvatar = false; // false = 隐藏, true = 显示

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await RoomService.getCurrentCheckIns();

    setState(() {
      _isLoading = false;
      if (response.isSuccess) {
        _checkIns = response.data;
      } else {
        _errorMessage = response.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoomColors.background,
      appBar: AppBar(
        backgroundColor: RoomColors.cardBg,
        elevation: 0,
        iconTheme: IconThemeData(color: RoomColors.textPrimary),
        title: Text(
          '在寺人员',
          style: TextStyle(
            color: RoomColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: RoomColors.primary))
          : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : _checkIns.isEmpty
          ? _buildEmptyView()
          : _buildListView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: RoomColors.occupied),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(color: RoomColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: RoomColors.divider),
          const SizedBox(height: 16),
          Text(
            '暂无在寺人员',
            style: TextStyle(color: RoomColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: RoomColors.primary,
      displacement: 60,
      strokeWidth: 2.5,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _checkIns.length,
        itemBuilder: (context, index) {
          final checkIn = _checkIns[index];
          // 倒序序号（列表最后一个是1，第一个是总数）
          final reverseIndex = _checkIns.length - index;
          return _buildCheckInItem(checkIn, reverseIndex);
        },
      ),
    );
  }

  Widget _buildCheckInItem(RoomCheckIn checkIn, int index) {
    // 计算已入住天数
    final days = DateTime.now().difference(checkIn.checkInTime).inDays;

    return GestureDetector(
      onTap: () => _showCheckInDetail(checkIn),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        decoration: BoxDecoration(
          color: RoomColors.cardBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 使用条件判断控制头像显示
                      if (_showAvatar) ...[
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
                              checkIn.cgender == 'male'
                                  ? Icons.person
                                  : Icons.person,
                              size: 28,
                              color: checkIn.genderColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 姓名、性别标签
                            Row(
                              children: [
                                // 姓名
                                Text(
                                  checkIn.cname,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: RoomColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 性别标签
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
                      // 占位，给右上角标签留空间
                      const SizedBox(width: 50),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 底部信息栏
                  Row(
                    children: [
                      // 区域-房间号
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: RoomColors.background,
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
                      // 床位号（颜色和区域一致）
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: RoomColors.background,
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
            ),
            // 已入住天数标签 - 右上角
            Positioned(
              top: 12,
              right: 12,
              child: Container(
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
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  void _showCheckInDetail(RoomCheckIn checkIn) async {
    // 获取历史入住记录
    final historyResponse = await RoomService.getUserCheckInHistory(checkIn.userId);
    
    if (!mounted) return;
    
    CheckInDetailSheet.show(
      context: context,
      checkIn: checkIn,
      historyCheckIns: historyResponse.data,
      showCheckOutButton: true,
      showChangeRoomButton: true,
      onCheckOut: () => _showCheckOutConfirmDialog(context, checkIn),
      onChangeRoom: () => _showChangeRoomSheet(checkIn),
    );
  }

  void _showChangeRoomSheet(RoomCheckIn checkIn) {
    ChangeRoomSheet.show(
      context: context,
      checkIn: checkIn,
      onRoomChanged: () {
        _loadData(); // 刷新列表
        // 发送全局数据变更通知
        RoomDataNotifier().notifyDataChanged();
      },
    );
  }

  // 显示退房确认对话框
  void _showCheckOutConfirmDialog(BuildContext context, RoomCheckIn checkIn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退房'),
        content: Text('确定要为 ${checkIn.cname} 办理退房吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _checkOut(checkIn);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RoomColors.occupied,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认退房'),
          ),
        ],
      ),
    );
  }

  // 执行退房
  Future<void> _checkOut(RoomCheckIn checkIn) async {
    final response = await RoomService.checkOut(checkIn.id);

    if (response.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${checkIn.cname} 退房成功'),
            backgroundColor: RoomColors.available,
          ),
        );
        _loadData(); // 刷新列表
        // 发送全局数据变更通知
        RoomDataNotifier().notifyDataChanged();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('退房失败: ${response.message}'),
            backgroundColor: RoomColors.occupied,
          ),
        );
      }
    }
  }

  // 计算入住天数
  String _calculateStayDays(DateTime checkInTime) {
    final now = DateTime.now();
    final difference = now.difference(checkInTime);
    final days = difference.inDays;
    if (days == 0) {
      return '今天';
    } else if (days == 1) {
      return '1天';
    } else {
      return '$days天';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label：',
            style: TextStyle(
              fontSize: 14,
              color: RoomColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: RoomColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRemarks(RoomCheckIn checkIn) {
    return FutureBuilder<CheckInHistoryResponse>(
      future: RoomService.getUserCheckInHistory(checkIn.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: RoomColors.occupied,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '加载失败',
                    style: TextStyle(
                      fontSize: 14,
                      color: RoomColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 过滤掉还在入住中的记录（checkOutTime为null）
        final historyList = snapshot.data?.data
                .where((h) => h.checkOutTime != null)
                .toList() ??
            [];

        if (historyList.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.history_outlined,
                    size: 48,
                    color: RoomColors.divider,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '暂无历史入住记录',
                    style: TextStyle(
                      fontSize: 14,
                      color: RoomColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: historyList.map((history) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RoomColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: RoomColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        history.checkInTime.toString().substring(0, 10),
                        style: TextStyle(
                          fontSize: 12,
                          color: RoomColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: history.status == 'CHECKED_OUT'
                              ? RoomColors.textSecondary.withOpacity(0.1)
                              : RoomColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          history.statusDisplayName,
                          style: TextStyle(
                            fontSize: 11,
                            color: history.status == 'CHECKED_OUT'
                                ? RoomColors.textSecondary
                                : RoomColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${history.areaDisplayName}${history.roomNumber}号房${history.bedNumber}床',
                          style: TextStyle(
                            fontSize: 13,
                            color: RoomColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: RoomColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '入住${history.stayDays}天',
                          style: TextStyle(
                            fontSize: 11,
                            color: RoomColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (history.checkOutTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '退房: ${history.checkOutTime.toString().substring(0, 10)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: RoomColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // 备注 Tab 内容
  Widget _buildRemarksTab(RoomCheckIn checkIn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 当前备注
        if (checkIn.remark != null && checkIn.remark!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RoomColors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RoomColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 16,
                      color: RoomColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '当前备注',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: RoomColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  checkIn.remark!,
                  style: TextStyle(
                    fontSize: 14,
                    color: RoomColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.note_add_outlined,
                    size: 48,
                    color: RoomColors.divider,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '暂无备注',
                    style: TextStyle(
                      fontSize: 14,
                      color: RoomColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
