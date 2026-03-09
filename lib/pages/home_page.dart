import 'dart:async';
import 'package:flutter/material.dart';
import '../components/occupancy_summary_dialog.dart';
import '../components/today_activity_dialog.dart';
import '../models/room.dart';
import '../models/room_check_in.dart';
import '../room_colors.dart';
import '../services/room_service.dart';
import '../services/room_data_notifier.dart';
import 'room/current_check_ins_page.dart';
import 'room/room_grid_page.dart';
import 'room/room_list_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onDataChanged;
  
  const HomePage({super.key, this.onDataChanged});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<Room> _rooms = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _todayCheckInCount = 0;
  int _todayCheckOutCount = 0;
  StreamSubscription<void>? _dataChangeSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // 监听数据变更通知
    print('=== HomePage: 开始监听数据变更通知 ===');
    _dataChangeSubscription = RoomDataNotifier().onDataChanged.listen((_) {
      print('=== HomePage: 收到数据变更通知，开始刷新 ===');
      _loadData();
    });
    print('=== HomePage: 监听设置完成 ===');
  }
  
  @override
  void dispose() {
    _dataChangeSubscription?.cancel();
    super.dispose();
  }

  // 公共刷新方法，供外部调用
  Future<void> refreshData() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    await Future.wait([
      _loadRooms(),
      _loadTodayStats(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadRooms() async {
    final response = await RoomService.getRooms();

    if (response.isSuccess) {
      setState(() {
        _rooms = response.data;
      });
    } else {
      setState(() {
        _errorMessage = response.message;
      });
    }
  }

  Future<void> _loadTodayStats() async {
    // 并行获取今日入住和今日退房数据
    final results = await Future.wait([
      RoomService.getTodayCheckIns(),
      RoomService.getTodayCheckOuts(),
    ]);

    final todayCheckInsResponse = results[0];
    final todayCheckOutsResponse = results[1];

    setState(() {
      if (todayCheckInsResponse.isSuccess) {
        _todayCheckInCount = todayCheckInsResponse.data.length;
      }
      if (todayCheckOutsResponse.isSuccess) {
        _todayCheckOutCount = todayCheckOutsResponse.data.length;
      }
    });
  }

  // 获取各区域的房间统计
  Map<String, AreaStats> _getAreaStats() {
    Map<String, AreaStats> stats = {};
    
    for (var area in AreaConfig.allAreas) {
      final areaRooms = _rooms.where((r) => r.roomArea == area.code).toList();
      final totalRooms = areaRooms.length;
      final totalBeds = areaRooms.fold(0, (sum, r) => sum + r.totalCapacity);
      final occupiedBeds = areaRooms.fold(0, (sum, r) => sum + r.occupiedBeds);
      final availableBeds = totalBeds - occupiedBeds;
      
      stats[area.code] = AreaStats(
        totalRooms: totalRooms,
        totalBeds: totalBeds,
        occupiedBeds: occupiedBeds,
        availableBeds: availableBeds,
      );
    }
    
    return stats;
  }

  void _showOccupancyDetail() async {
    // 显示加载中
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // 获取所有在住人员记录
    final checkInsResponse = await RoomService.getCurrentCheckIns();

    // 关闭加载中
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (!mounted) return;

    if (checkInsResponse.isSuccess) {
      // 显示在住人员汇总弹窗
      OccupancySummaryDialog.show(
        context: context,
        checkIns: checkInsResponse.data,
        title: '在住人员汇总',
      );
    } else {
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('获取数据失败: ${checkInsResponse.message}'),
          backgroundColor: RoomColors.occupied,
        ),
      );
    }
  }

  // 显示今日动态弹窗
  void _showTodayActivity() async {
    // 显示加载中
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // 并行获取今日入住和今日退房数据
    final results = await Future.wait([
      RoomService.getTodayCheckIns(),
      RoomService.getTodayCheckOuts(),
    ]);

    // 关闭加载中
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (!mounted) return;

    final todayCheckInsResponse = results[0];
    final todayCheckOutsResponse = results[1];

    // 显示今日动态弹窗
    TodayActivityDialog.show(
      context: context,
      todayCheckIns: todayCheckInsResponse.isSuccess ? todayCheckInsResponse.data : [],
      todayCheckOuts: todayCheckOutsResponse.isSuccess ? todayCheckOutsResponse.data : [],
      title: '今日动态',
    );
  }

  @override
  Widget build(BuildContext context) {
    final areaStats = _getAreaStats();
    
    return Scaffold(
      backgroundColor: RoomColors.background,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: RoomColors.primary,
              ),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadRooms,
                  color: RoomColors.primary,
                  displacement: 100,
                  strokeWidth: 2.5,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 总体统计卡片
                        _buildOverallStatsCard(),
                        const SizedBox(height: 16),
                        // 区域标题
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            '区域分布',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: RoomColors.textPrimary,
                            ),
                          ),
                        ),
                        // 区域网格
                        _buildAreaGrid(areaStats),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOverallStatsCard() {
    final totalRooms = _rooms.length;
    final totalBeds = _rooms.fold(0, (sum, r) => sum + r.totalCapacity);
    final occupiedBeds = _rooms.fold(0, (sum, r) => sum + r.occupiedBeds);
    final availableBeds = totalBeds - occupiedBeds;
    final occupancyRate = totalBeds > 0 ? (occupiedBeds / totalBeds * 100).toInt() : 0;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: RoomColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PageView(
        children: [
          // 第一页：总体统计
          _buildStatsPage1(totalRooms, totalBeds, occupiedBeds, availableBeds, occupancyRate),
          // 第二页：今日动态
          _buildStatsPage2(),
        ],
      ),
    );
  }

  Widget _buildStatsPage1(int totalRooms, int totalBeds, int occupiedBeds, int availableBeds, int occupancyRate) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showOccupancyDetail(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '总体入住率',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: RoomColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: RoomColors.textGrey,
                    ),
                  ],
                ),
                Text(
                  '$occupancyRate%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: RoomColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('总房间', '$totalRooms', RoomColors.textPrimary),
              ),
              Container(
                width: 1,
                height: 30,
                color: RoomColors.divider,
              ),
              Expanded(
                child: _buildStatItem('总床位', '$totalBeds', RoomColors.textPrimary),
              ),
              Container(
                width: 1,
                height: 30,
                color: RoomColors.divider,
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CurrentCheckInsPage(
                          onDataChanged: () {
                            // 数据变更时刷新首页
                            _loadData();
                            // 通知父页面刷新Grid
                            widget.onDataChanged?.call();
                          },
                        ),
                      ),
                    );
                    // 返回时刷新首页数据
                    _loadData();
                    // 通知父页面刷新Grid
                    widget.onDataChanged?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: _buildStatItem('已入住', '$occupiedBeds', RoomColors.occupied),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: RoomColors.divider,
              ),
              Expanded(
                child: _buildStatItem('空床位', '$availableBeds', RoomColors.available),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 指示器
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 4,
                decoration: BoxDecoration(
                  color: RoomColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: RoomColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPage2() {
    return GestureDetector(
      onTap: () => _showTodayActivity(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '今日动态',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: RoomColors.textPrimary,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: RoomColors.textGrey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    icon: Icons.login,
                    label: '今日入住',
                    count: _todayCheckInCount,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStatCard(
                    icon: Icons.logout,
                    label: '今日离开',
                    count: _todayCheckOutCount,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // 指示器
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RoomColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 16,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RoomColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          // 右上角图标
          Positioned(
            top: 0,
            right: 0,
            child: Icon(icon, size: 18, color: color.withOpacity(0.6)),
          ),
          // 内容
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count人',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: RoomColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
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
    );
  }

  Widget _buildAreaGrid(Map<String, AreaStats> areaStats) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AreaConfig.allAreas.map((area) {
        final stats = areaStats[area.code] ?? AreaStats.empty();
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 36) / 2,
          child: _buildAreaCard(area, stats),
        );
      }).toList(),
    );
  }

  Widget _buildAreaCard(AreaConfig area, AreaStats stats) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomGridPage(initialArea: area.code),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RoomColors.cardBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  area.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: RoomColors.textPrimary,
                  ),
                ),
                if (stats.occupiedBeds > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: area.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${stats.occupiedBeds}人',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: area.color,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.totalRooms}间 · ${stats.occupiedBeds}/${stats.totalBeds}床',
              style: TextStyle(
                fontSize: 12,
                color: RoomColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: RoomColors.occupied.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: RoomColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadRooms,
            child: Text(
              '重试',
              style: TextStyle(color: RoomColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class AreaStats {
  final int totalRooms;
  final int totalBeds;
  final int occupiedBeds;
  final int availableBeds;

  AreaStats({
    required this.totalRooms,
    required this.totalBeds,
    required this.occupiedBeds,
    required this.availableBeds,
  });

  factory AreaStats.empty() {
    return AreaStats(
      totalRooms: 0,
      totalBeds: 0,
      occupiedBeds: 0,
      availableBeds: 0,
    );
  }
}
