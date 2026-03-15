import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../models/inventory/goods.dart';
import '../../models/inventory/inbound_record.dart';
import '../../models/inventory/outbound_record.dart';
import '../../models/inventory/stock_overview.dart';
import '../../services/inventory/inventory_service.dart';
import '../../services/inventory/inventory_theme_manager.dart';

/// 库存统计页面
class StockStatsPage extends StatefulWidget {
  const StockStatsPage({super.key});

  @override
  State<StockStatsPage> createState() => _StockStatsPageState();
}

class _StockStatsPageState extends State<StockStatsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StockOverview? _overview;
  List<Goods> _warningGoods = [];
  List<InboundRecord> _inboundRecords = [];
  List<OutboundRecord> _outboundRecords = [];
  bool _isLoading = true;

  final _themeManager = InventoryThemeManager();

  AppTheme get _currentTheme => _themeManager.currentTheme;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _themeManager.init();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final overview = await InventoryService.getStockOverview();
      final warning = await InventoryService.getStock(warning: true);
      final inbound = await InventoryService.getInboundRecords();
      final outbound = await InventoryService.getOutboundRecords();

      setState(() {
        _overview = overview;
        _warningGoods = warning;
        _inboundRecords = inbound;
        _outboundRecords = outbound;
      });
    } catch (e) {
      TDToast.showText('加载数据失败: $e', context: context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _currentTheme.background,
      appBar: AppBar(
        title: Text('库存统计', style: TextStyle(color: _currentTheme.textPrimary)),
        backgroundColor: _currentTheme.surface,
        foregroundColor: _currentTheme.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _currentTheme.primary,
          unselectedLabelColor: _currentTheme.textSecondary,
          indicatorColor: _currentTheme.primary,
          tabs: const [
            Tab(text: '总览'),
            Tab(text: '预警'),
            Tab(text: '入库'),
            Tab(text: '出库'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: TDCircleIndicator(color: _currentTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(bottomPadding),
                _buildWarningTab(bottomPadding),
                _buildInboundTab(bottomPadding),
                _buildOutboundTab(bottomPadding),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(double bottomPadding) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _currentTheme.primary,
      child: ListView(
        padding: EdgeInsets.all(16).copyWith(bottom: 16 + bottomPadding),
        children: [
          _buildOverviewCard(),
          const SizedBox(height: 16),
          _buildTodayStatsCard(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_currentTheme.primary, _currentTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '库存总览',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '${_overview?.totalGoods ?? 0}',
                  '总产品数',
                  Colors.white,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '${_overview?.warningCount ?? 0}',
                  '预警产品',
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _currentTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日动态',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _currentTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '${_overview?.todayInbound ?? 0}',
                  '今日入库',
                  _currentTheme.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '${_overview?.todayOutbound ?? 0}',
                  '今日出库',
                  _currentTheme.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningTab(double bottomPadding) {
    if (_warningGoods.isEmpty) {
      return const Center(
        child: TDEmpty(
          icon: TDIcons.check_circle,
          emptyText: '暂无库存预警',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _currentTheme.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(16).copyWith(bottom: 16 + bottomPadding),
        itemCount: _warningGoods.length,
        itemBuilder: (context, index) {
          final goods = _warningGoods[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _currentTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _currentTheme.danger.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _currentTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warning,
                    color: _currentTheme.danger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goods.goodsName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _currentTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${goods.goodsType}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _currentTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${goods.currentStock ?? 0}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _currentTheme.danger,
                      ),
                    ),
                    Text(
                      '安全: ${goods.safetyStock ?? 10}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _currentTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInboundTab(double bottomPadding) {
    if (_inboundRecords.isEmpty) {
      return const Center(
        child: TDEmpty(emptyText: '暂无入库记录'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _currentTheme.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(16).copyWith(bottom: 16 + bottomPadding),
        itemCount: _inboundRecords.length,
        itemBuilder: (context, index) {
          final record = _inboundRecords[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _currentTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _currentTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.login,
                    color: _currentTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.goods?.goodsName ?? '未知产品',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _currentTheme.textPrimary,
                        ),
                      ),
                      if (record.supplier != null)
                        Text(
                          '供应商: ${record.supplier}',
                          style: TextStyle(
                            fontSize: 13,
                            color: _currentTheme.textSecondary,
                          ),
                        ),
                      Text(
                        '${record.inboundDate?.toString().split('T')[0] ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _currentTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${record.quantity}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _currentTheme.success,
                      ),
                    ),
                    if (record.purchasePrice != null)
                      Text(
                        '¥${record.purchasePrice}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _currentTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOutboundTab(double bottomPadding) {
    if (_outboundRecords.isEmpty) {
      return const Center(
        child: TDEmpty(emptyText: '暂无出库记录'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _currentTheme.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(16).copyWith(bottom: 16 + bottomPadding),
        itemCount: _outboundRecords.length,
        itemBuilder: (context, index) {
          final record = _outboundRecords[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _currentTheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _currentTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: _currentTheme.danger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.goods?.goodsName ?? '未知产品',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _currentTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '去向: ${record.destination}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _currentTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '${record.outboundDate?.toString().split('T')[0] ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _currentTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '-${record.quantity}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _currentTheme.danger,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
