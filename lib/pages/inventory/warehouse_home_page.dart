import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../models/inventory/stock_overview.dart';
import '../../services/inventory/inventory_service.dart';
import '../../services/inventory/inventory_theme_manager.dart';
import 'goods_list_page.dart';
import 'goods_form_page.dart';
import 'inbound_page.dart';
import 'outbound_page.dart';
import 'stock_stats_page.dart';

/// 库房管理主页
class WarehouseHomePage extends StatefulWidget {
  const WarehouseHomePage({super.key});

  @override
  State<WarehouseHomePage> createState() => _WarehouseHomePageState();
}

class _WarehouseHomePageState extends State<WarehouseHomePage> {
  StockOverview? _overview;
  bool _isLoading = true;

  final _themeManager = InventoryThemeManager();

  AppTheme get _currentTheme => _themeManager.currentTheme;

  @override
  void initState() {
    super.initState();
    _themeManager.init();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final overview = await InventoryService.getStockOverview();
      setState(() {
        _overview = overview;
      });
    } catch (e) {
      TDToast.showText('加载失败: $e', context: context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 切换主题
  void _switchTheme() async {
    await _themeManager.nextTheme();
    setState(() {});
    TDToast.showText('已切换至 ${_currentTheme.name} 主题', context: context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _currentTheme.background,
      appBar: TDNavBar(
        title: '库房管理',
        backgroundColor: _currentTheme.surface,
        useDefaultBack: true,
      ),
      body: _isLoading
          ? Center(child: TDCircleIndicator(color: _currentTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _currentTheme.primary,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 16 + bottomPadding),
                child: Column(
                  children: [
                    _buildStatsCard(),
                    const SizedBox(height: 16),
                    _buildActionGrid(),
                  ],
                ),
              ),
            ),
      floatingActionButton: _buildThemeFab(),
    );
  }

  /// 统计卡片
  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_currentTheme.primary, _currentTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _currentTheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '库存概览',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '今日',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '${_overview?.totalGoods ?? 0}',
                  '总产品',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '${_overview?.todayInbound ?? 0}',
                  '今日入库',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '${_overview?.todayOutbound ?? 0}',
                  '今日出库',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if ((_overview?.warningCount ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _currentTheme.danger.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_overview?.warningCount ?? 0} 个产品库存不足',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  /// 功能按钮网格
  Widget _buildActionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快捷操作',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _currentTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _buildActionCard(
                '入库',
                '入库登记',
                Icons.login,
                _currentTheme.success,
                () => _navigateTo(const InboundPage()),
                _currentTheme.primary,
              ),
              _buildActionCard(
                '出库',
                '出库登记',
                Icons.logout,
                _currentTheme.danger,
                () => _navigateTo(const OutboundPage()),
                _currentTheme.primary,
              ),
              _buildActionCard(
                '产品',
                '列表管理',
                Icons.inventory_2,
                _currentTheme.primary,
                () => _navigateTo(const GoodsListPage()),
                _currentTheme.primary,
              ),
              _buildActionCard(
                '统计',
                '统计分析',
                Icons.bar_chart,
                _currentTheme.primary,
                () => _navigateTo(const StockStatsPage()),
                _currentTheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    Color borderColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _currentTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _currentTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _currentTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 主题切换按钮
  Widget _buildThemeFab() {
    return FloatingActionButton(
      onPressed: _switchTheme,
      backgroundColor: _currentTheme.primary,
      child: Icon(Icons.palette, color: Colors.white),
    );
  }

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }
}
