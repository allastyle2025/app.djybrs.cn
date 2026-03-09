import 'package:flutter/material.dart';
import '../../components/room_app_bar.dart';
import '../../models/room_check_in.dart';
import '../../room_colors.dart';
import '../../services/room_service.dart';

/// 入住记录页面
/// 显示所有入住记录（包括已退房和未退房的）
class CheckInRecordsPage extends StatefulWidget {
  const CheckInRecordsPage({super.key});

  @override
  State<CheckInRecordsPage> createState() => _CheckInRecordsPageState();
}

class _CheckInRecordsPageState extends State<CheckInRecordsPage> {
  List<RoomCheckIn> _checkIns = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // 分页相关
  int _currentPage = 1;
  int _pageSize = 20;
  int get _totalItems => _filteredTotalItems;
  int get _totalPages => (_totalItems / _pageSize).ceil();

  // 筛选相关
  String? _statusFilter; // null: 全部, 'checked_in': 在住, 'checked_out': 已退房

  // 滚动控制器（用于同步表头和表体）
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // 同步表头和表体的滚动
    _headerScrollController.addListener(() {
      if (_bodyScrollController.hasClients &&
          _bodyScrollController.offset != _headerScrollController.offset) {
        _bodyScrollController.jumpTo(_headerScrollController.offset);
      }
    });
    _bodyScrollController.addListener(() {
      if (_headerScrollController.hasClients &&
          _headerScrollController.offset != _bodyScrollController.offset) {
        _headerScrollController.jumpTo(_bodyScrollController.offset);
      }
    });
  }
  
  @override
  void dispose() {
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await RoomService.getAllCheckIns();

    if (response.isSuccess) {
      setState(() {
        _checkIns = response.data;
        _currentPage = 1; // 重置到第一页
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response.message;
        _isLoading = false;
      });
    }
  }

  // 获取筛选后的数据
  List<RoomCheckIn> get _filteredCheckIns {
    if (_statusFilter == null) return _checkIns;
    if (_statusFilter == 'checked_in') {
      return _checkIns.where((c) => c.checkOutTime == null).toList();
    }
    if (_statusFilter == 'checked_out') {
      return _checkIns.where((c) => c.checkOutTime != null).toList();
    }
    return _checkIns;
  }

  // 获取当前页的数据
  List<RoomCheckIn> get _currentPageData {
    final filtered = _filteredCheckIns;
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    if (startIndex >= filtered.length) return [];
    return filtered.sublist(startIndex, endIndex > filtered.length ? filtered.length : endIndex);
  }

  // 获取筛选后的总数
  int get _filteredTotalItems => _filteredCheckIns.length;

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoomColors.background,
      appBar: const RoomAppBar(
        title: '入住记录',
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: RoomColors.primary,
                ),
              )
            : _errorMessage.isNotEmpty
                ? _buildErrorView()
                : _checkIns.isEmpty
                    ? _buildEmptyView()
                    : _buildContent(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: RoomColors.occupied,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: RoomColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: RoomColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: RoomColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无入住记录',
            style: TextStyle(
              fontSize: 14,
              color: RoomColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // 统计信息
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: RoomColors.cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildStatItem('总记录', '$_totalItems'),
              Container(
                width: 1,
                height: 30,
                color: RoomColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              _buildStatItem('在住', '${_checkIns.where((c) => c.checkOutTime == null).length}'),
              Container(
                width: 1,
                height: 30,
                color: RoomColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              _buildStatItem('已退房', '${_checkIns.where((c) => c.checkOutTime != null).length}'),
            ],
          ),
        ),
        // 表格区域
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: RoomColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final containerWidth = constraints.maxWidth < 430 ? 430.0 : constraints.maxWidth;
                  return RefreshIndicator(
                    onRefresh: _loadData,
                    color: RoomColors.primary,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        width: containerWidth,
                        height: constraints.maxHeight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 表头
                            _buildTableHeader(),
                            Divider(height: 1, color: RoomColors.divider),
                            // 表格内容
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _currentPageData.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final checkIn = entry.value;
                                    // 倒序序号：总记录数 - 当前页起始位置 - 当前行索引
                                    final globalIndex = _totalItems - ((_currentPage - 1) * _pageSize + index);
                                    return _buildTableRow(checkIn, globalIndex);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // 分页控件
        if (_totalPages > 1)
          _buildPagination(),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: RoomColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: RoomColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: RoomColors.primary.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('序号', 32),
          _buildHeaderCell('姓名', 50),
          _buildHeaderCell('性别', 32),
          _buildHeaderCell('年龄', 32),
          _buildHeaderCell('房间', 80),
          _buildStatusFilterCell(),
          _buildHeaderCell('入住日期', 70),
          _buildHeaderCell('退房日期', 70),
        ],
      ),
    );
  }

  Widget _buildStatusFilterCell() {
    final filterText = _statusFilter == null
        ? '状态 ▼'
        : (_statusFilter == 'checked_in' ? '在住 ▼' : '已退 ▼');
    final filterColor = _statusFilter == null
        ? RoomColors.textSecondary
        : (_statusFilter == 'checked_in' ? RoomColors.available : RoomColors.textSecondary);

    return SizedBox(
      width: 40,
      child: GestureDetector(
        onTap: _showStatusFilterMenu,
        child: Text(
          filterText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: filterColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showStatusFilterMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width / 2 - 60,
        280,
        MediaQuery.of(context).size.width / 2 + 60,
        0,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                _statusFilter == null ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: RoomColors.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text('全部'),
            ],
          ),
          onTap: () {
            setState(() {
              _statusFilter = null;
              _currentPage = 1;
            });
          },
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                _statusFilter == 'checked_in' ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: RoomColors.available,
              ),
              const SizedBox(width: 8),
              Text('在住', style: TextStyle(color: RoomColors.available)),
            ],
          ),
          onTap: () {
            setState(() {
              _statusFilter = 'checked_in';
              _currentPage = 1;
            });
          },
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                _statusFilter == 'checked_out' ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: RoomColors.textSecondary,
              ),
              const SizedBox(width: 8),
              const Text('已退房'),
            ],
          ),
          onTap: () {
            setState(() {
              _statusFilter = 'checked_out';
              _currentPage = 1;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: RoomColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(RoomCheckIn checkIn, int index) {
    final isCheckedOut = checkIn.checkOutTime != null;
    final statusColor = isCheckedOut ? RoomColors.textSecondary : RoomColors.available;
    final statusText = isCheckedOut ? '已退' : '在住';
    final statusBgColor = isCheckedOut ? RoomColors.textSecondary.withOpacity(0.1) : RoomColors.available.withOpacity(0.1);

    // 性别显示
    final genderText = checkIn.cgender == 'male' ? '男' : (checkIn.cgender == 'female' ? '女' : '-');
    final genderColor = checkIn.cgender == 'male' ? Colors.blue : (checkIn.cgender == 'female' ? Colors.pink : RoomColors.textSecondary);

    // 格式化日期（如果不是今年则显示年份）
    final now = DateTime.now();
    final checkInDate = checkIn.checkInTime.year == now.year
        ? '${checkIn.checkInTime.month.toString().padLeft(2, '0')}-${checkIn.checkInTime.day.toString().padLeft(2, '0')}'
        : '${checkIn.checkInTime.year}-${checkIn.checkInTime.month.toString().padLeft(2, '0')}-${checkIn.checkInTime.day.toString().padLeft(2, '0')}';
    final checkOutDate = checkIn.checkOutTime != null
        ? (checkIn.checkOutTime!.year == now.year
            ? '${checkIn.checkOutTime!.month.toString().padLeft(2, '0')}-${checkIn.checkOutTime!.day.toString().padLeft(2, '0')}'
            : '${checkIn.checkOutTime!.year}-${checkIn.checkOutTime!.month.toString().padLeft(2, '0')}-${checkIn.checkOutTime!.day.toString().padLeft(2, '0')}')
        : '-';

    return InkWell(
      onTap: () => _showDetailDialog(checkIn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: RoomColors.divider.withOpacity(0.5)),
          ),
        ),
        child: Row(
          children: [
            _buildDataCell('$index', 32),
            _buildDataCell(checkIn.cname ?? '-', 50, isBold: true),
            SizedBox(
              width: 32,
              child: Text(
                genderText,
                style: TextStyle(
                  fontSize: 12,
                  color: genderColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            _buildDataCell(checkIn.cage?.toString() ?? '-', 32),
            _buildDataCell('${checkIn.areaDisplayName}-${checkIn.roomNumber}', 80, color: RoomColors.textSecondary),
            SizedBox(
              width: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            _buildDataCell(checkInDate, 70, color: RoomColors.textSecondary),
            _buildDataCell(checkOutDate, 70, color: RoomColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(RoomCheckIn checkIn) {
    final isCheckedOut = checkIn.checkOutTime != null;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: RoomColors.cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        RoomColors.primary.withOpacity(0.1),
                        RoomColors.primary.withOpacity(0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: RoomColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '入住详情',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: RoomColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: RoomColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 内容区域
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 基本信息
                        _buildDetailSection('基本信息', [
                          _buildDetailItem('姓名', checkIn.cname ?? '-'),
                          _buildDetailItem('性别', checkIn.cgender == 'male' ? '男' : (checkIn.cgender == 'female' ? '女' : '-')),
                          _buildDetailItem('年龄', checkIn.cage?.toString() ?? '-'),
                          _buildDetailItem('电话', checkIn.cphone ?? '-'),
                        ]),
                        const SizedBox(height: 16),
                        // 入住信息
                        _buildDetailSection('入住信息', [
                          _buildDetailItem('区域', checkIn.areaDisplayName),
                          _buildDetailItem('房间号', checkIn.roomNumber),
                          _buildDetailItem('床位号', '${checkIn.bedNumber}号床'),
                          _buildDetailItem('入住时间', _formatDateTime(checkIn.checkInTime)),
                          if (checkIn.checkOutTime != null)
                            _buildDetailItem('退房时间', _formatDateTime(checkIn.checkOutTime!)),
                          _buildDetailItem('状态', isCheckedOut ? '已退房' : '在住',
                            valueColor: isCheckedOut ? RoomColors.textSecondary : RoomColors.available),
                          if (checkIn.purpose != null && checkIn.purpose!.isNotEmpty)
                            _buildDetailItem('目的', _getPurposeText(checkIn.purpose)),
                        ]),
                        if (checkIn.emergencyContactName != null && checkIn.emergencyContactName!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          // 紧急联系人
                          _buildDetailSection('紧急联系人', [
                            _buildDetailItem('姓名', checkIn.emergencyContactName!),
                            if (checkIn.emergencyContactRelation != null)
                              _buildDetailItem('关系', checkIn.emergencyContactRelation!),
                            if (checkIn.emergencyContactPhone != null)
                              _buildDetailItem('电话', checkIn.emergencyContactPhone!),
                          ]),
                        ],
                        if (checkIn.remark != null && checkIn.remark!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          // 备注
                          _buildDetailSection('备注', [
                            _buildDetailItem('', checkIn.remark!),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: RoomColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: RoomColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
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
                fontWeight: FontWeight.w500,
                color: valueColor ?? RoomColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getPurposeText(String? purpose) {
    switch (purpose) {
      case 'volunteer':
        return '义工';
      case 'practice':
        return '修行';
      case 'visit':
        return '参访';
      case 'other':
        return '其他';
      default:
        return purpose ?? '-';
    }
  }

  Widget _buildDataCell(String text, double width, {bool isBold = false, Color? color}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w500 : FontWeight.normal,
          color: color ?? RoomColors.textPrimary,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: RoomColors.cardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上一页
          IconButton(
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            icon: Icon(
              Icons.chevron_left,
              color: _currentPage > 1 ? RoomColors.textPrimary : RoomColors.divider,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 8),
          // 页码信息
          Text(
            '$_currentPage / $_totalPages',
            style: TextStyle(
              fontSize: 14,
              color: RoomColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          // 下一页
          IconButton(
            onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            icon: Icon(
              Icons.chevron_right,
              color: _currentPage < _totalPages ? RoomColors.textPrimary : RoomColors.divider,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
