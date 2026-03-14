import 'dart:async';
import 'package:flutter/material.dart';
import '../models/room_check_in.dart';
import '../room_colors.dart';
import '../services/room_service.dart';
import '../services/room_data_notifier.dart';
import 'change_room_sheet.dart';

class PendingCheckInDetailSheet extends StatefulWidget {
  final RoomCheckIn checkIn;
  final VoidCallback? onApproved;
  final VoidCallback? onRejected;

  const PendingCheckInDetailSheet({
    super.key,
    required this.checkIn,
    this.onApproved,
    this.onRejected,
  });

  static Future<void> show({
    required BuildContext context,
    required RoomCheckIn checkIn,
    VoidCallback? onApproved,
    VoidCallback? onRejected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PendingCheckInDetailSheet(
        checkIn: checkIn,
        onApproved: onApproved,
        onRejected: onRejected,
      ),
    );
  }

  @override
  State<PendingCheckInDetailSheet> createState() => _PendingCheckInDetailSheetState();
}

class _PendingCheckInDetailSheetState extends State<PendingCheckInDetailSheet> {
  bool _isLoading = false;
  late StreamSubscription<void> _dataChangeSubscription;
  late RoomCheckIn _checkIn;

  @override
  void initState() {
    super.initState();
    _checkIn = widget.checkIn;
    
    // 订阅数据变更通知
    _dataChangeSubscription = RoomDataNotifier().onDataChanged.listen((_) {
      _reloadCheckInData();
    });
  }

  @override
  void dispose() {
    _dataChangeSubscription.cancel();
    super.dispose();
  }

  Future<void> _reloadCheckInData() async {
    final response = await RoomService.getCheckInDetail(_checkIn.id);
    if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _checkIn = response.data![0];
        });
      }
    }
  }

  Future<void> _approve() async {
    // 检查身份是否已设置
    if (_checkIn.purpose == null || _checkIn.purpose!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先点击身份设置后再通过申请'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: '确认通过',
      message: '确定要通过 ${_checkIn.cname} 的入住申请吗？',
      confirmText: '通过',
      confirmColor: RoomColors.available,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final response = await RoomService.approveCheckIn(_checkIn.id);

    setState(() => _isLoading = false);

    if (response.isSuccess) {
      if (mounted) {
        RoomDataNotifier().notifyDataChanged();
        // 先调用回调，再关闭弹窗
        widget.onApproved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已通过 ${_checkIn.cname} 的入住申请'),
            backgroundColor: RoomColors.available,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: RoomColors.occupied,
          ),
        );
      }
    }
  }

  Future<void> _reject() async {
    final confirmed = await _showConfirmDialog(
      title: '确认拒绝',
      message: '确定要拒绝 ${_checkIn.cname} 的入住申请吗？',
      confirmText: '拒绝',
      confirmColor: RoomColors.occupied,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final response = await RoomService.rejectCheckIn(_checkIn.id);

    setState(() => _isLoading = false);

    if (response.isSuccess) {
      if (mounted) {
        RoomDataNotifier().notifyDataChanged();
        // 先调用回调，再关闭弹窗
        widget.onRejected?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已拒绝 ${_checkIn.cname} 的入住申请'),
            backgroundColor: RoomColors.textSecondary,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: RoomColors.occupied,
          ),
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: TextStyle(color: RoomColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = _checkIn;

    return Container(
      decoration: BoxDecoration(
        color: RoomColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部拖动条
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: RoomColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '入住审核',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: RoomColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '待审核',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: RoomColors.divider),
            // 基本信息
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 姓名
                  _buildInfoRow('姓名', checkIn.cname),
                  const SizedBox(height: 16),
                  // 性别和年龄
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow('性别', checkIn.genderDisplayName),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildInfoRow('年龄', checkIn.cage != null ? '${checkIn.cage}岁' : '-'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 手机号
                  _buildInfoRow('手机号', checkIn.cphone),
                  const SizedBox(height: 16),
                  // 房间（可点击更换）
                  _buildClickableInfoRow(
                    '房间',
                    '${checkIn.areaDisplayName}-${checkIn.roomNumber}号房',
                    onTap: () => _showChangeRoomSheet(_checkIn),
                  ),
                  const SizedBox(height: 16),
                  // 床位
                  _buildInfoRow('床位', '${checkIn.bedNumber}号床'),
                  const SizedBox(height: 16),
                  // 入住时间
                  _buildInfoRow('申请时间', _formatDateTime(checkIn.checkInTime)),
                  if (checkIn.remark != null && checkIn.remark!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('备注', checkIn.remark!),
                  ],
                  const SizedBox(height: 16),
                  _buildClickableInfoRow(
                    '身份',
                    checkIn.purpose != null && checkIn.purpose!.isNotEmpty
                        ? _getPurposeDisplayName(checkIn.purpose!)
                        : '未设置',
                    onTap: () => _showPurposeEditDialog(),
                  ),
                  if (checkIn.emergencyContactName != null && checkIn.emergencyContactName!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('紧急联系人', '${checkIn.emergencyContactName} (${checkIn.emergencyContactRelation ?? ''}) ${checkIn.emergencyContactPhone ?? ''}'),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: RoomColors.divider),
            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _reject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RoomColors.occupied,
                        side: BorderSide(color: RoomColors.occupied),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('拒绝', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isLoading || _checkIn.purpose == null || _checkIn.purpose!.isEmpty)
                          ? null
                          : _approve,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RoomColors.available,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              (_checkIn.purpose == null || _checkIn.purpose!.isEmpty)
                                  ? '请设置身份'
                                  : '通过',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: RoomColors.textSecondary,
            ),
          ),
        ),
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
    );
  }

  Widget _buildClickableInfoRow(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: RoomColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: RoomColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: RoomColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangeRoomSheet(RoomCheckIn checkIn) {
    ChangeRoomSheet.show(
      context: context,
      checkIn: checkIn,
      onRoomChanged: () {
        Navigator.pop(context);
        RoomDataNotifier().notifyDataChanged();
        widget.onApproved?.call();
      },
    );
  }

  void _showPurposeEditDialog() {
    final List<Map<String, String>> purposes = [
      {'value': 'volunteer', 'label': '义工'},
      {'value': 'study', 'label': '学修'},
      {'value': 'permanent', 'label': '常住'},
      {'value': 'master', 'label': '师父'},
      {'value': 'other', 'label': '其它'},
    ];

    String? selectedPurpose = _checkIn.purpose;

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
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消', style: TextStyle(color: RoomColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedPurpose != null && selectedPurpose != _checkIn.purpose) {
                  // 先更新，再关闭对话框
                  setState(() {
                    _isLoading = true;
                  });

                  final response = await RoomService.updateCheckInPurpose(
                    _checkIn.id,
                    selectedPurpose!,
                  );

                  setState(() {
                    _isLoading = false;
                  });

                  if (response.isSuccess) {
                    RoomDataNotifier().notifyDataChanged();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('身份更新成功'),
                        backgroundColor: RoomColors.available,
                      ),
                    );
                    Navigator.pop(context);
                    widget.onApproved?.call();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response.message),
                        backgroundColor: RoomColors.occupied,
                      ),
                    );
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RoomColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getPurposeDisplayName(String purpose) {
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
        return purpose;
    }
  }
}
