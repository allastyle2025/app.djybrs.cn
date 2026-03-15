import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../models/inventory/goods.dart';
import '../../models/inventory/stock_overview.dart';
import '../../services/inventory/inventory_service.dart';
import '../../services/inventory/inventory_theme_manager.dart';
import 'goods_form_page.dart';
import 'inbound_page.dart';
import 'outbound_page.dart';
import 'stock_stats_page.dart';

/// 产品列表页面（库存管理主页）
class GoodsListPage extends StatefulWidget {
  const GoodsListPage({super.key});

  @override
  State<GoodsListPage> createState() => _GoodsListPageState();
}

class _GoodsListPageState extends State<GoodsListPage> {
  List<Goods> _goodsList = [];
  StockOverview? _overview;
  bool _isLoading = true;
  bool _isFabMenuOpen = false;

  final _themeManager = InventoryThemeManager();

  AppTheme get _currentTheme => _themeManager.currentTheme;

  /// 根据颜色名称获取对应的颜色值
  Color _getColorFromName(String? colorName) {
    if (colorName == null || colorName.isEmpty) {
      return _currentTheme.secondary;
    }
    
    final colorMap = {
      'yellow': const Color(0xFFFFD93D),
      'red': const Color(0xFFFF6B6B),
      'green': const Color(0xFF6BCB77),
      'blue': const Color(0xFF4D96FF),
      'purple': const Color(0xFF9B59B6),
      'orange': const Color(0xFFFF9F45),
      'pink': const Color(0xFFFF85A1),
      'cyan': const Color(0xFF00D9FF),
      'brown': const Color(0xFF8B4513),
      'black': const Color(0xFF2C3E50),
      'white': const Color(0xFFE8E8E8),
      'gray': const Color(0xFF95A5A6),
      'gold': const Color(0xFFFFD700),
      'silver': const Color(0xFFC0C0C0),
    };
    
    return colorMap[colorName.toLowerCase()] ?? _currentTheme.secondary;
  }

  /// 切换主题
  void _switchTheme() async {
    await _themeManager.nextTheme();
    setState(() {});
    TDToast.showText('已切换至 ${_currentTheme.name} 主题', context: context);
  }

  @override
  void initState() {
    super.initState();
    _themeManager.init();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final goods = await InventoryService.getAllGoods();
      final overview = await InventoryService.getStockOverview();
      setState(() {
        _goodsList = goods;
        _overview = overview;
      });
    } catch (e) {
      TDToast.showText('加载失败: $e', context: context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteGoods(Goods goods) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => TDConfirmDialog(
        title: '确认删除',
        content: '确定要删除"${goods.goodsName}"吗？此操作不可恢复。',
      ),
    );

    if (confirmed == true) {
      try {
        await InventoryService.deleteGoods(goods.goodsId!);
        TDToast.showText('删除成功', context: context);
        _loadData();
      } catch (e) {
        TDToast.showText('删除失败: $e', context: context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _currentTheme.background,
      appBar: AppBar(
        title: Text(
          '库房管理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _currentTheme.textPrimary,
          ),
        ),
        backgroundColor: _currentTheme.surface,
        foregroundColor: _currentTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart_rounded, size: 22, color: _currentTheme.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StockStatsPage()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(_currentTheme.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _currentTheme.primary,
              backgroundColor: _currentTheme.surface,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildCompactStats()),
                  _buildGoodsGrid(),
                  SliverToBoxAdapter(child: SizedBox(height: bottomPadding + 100)),
                ],
              ),
            ),
      floatingActionButton: _buildFabMenu(),
    );
  }

  Widget _buildCompactStats() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: _currentTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _currentTheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            '产品',
            '${_overview?.totalGoods ?? 0}',
            _currentTheme.primary,
            Icons.inventory_2_outlined,
          ),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: _currentTheme.divider,
          ),
          _buildStatItem(
            '预警',
            '${_overview?.warningCount ?? 0}',
            _currentTheme.danger,
            Icons.notifications_outlined,
          ),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: _currentTheme.divider,
          ),
          _buildStatItem(
            '今日入库',
            '${_overview?.todayInbound ?? 0}',
            _currentTheme.success,
            Icons.download_done_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: _currentTheme.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoodsGrid() {
    if (_goodsList.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: _currentTheme.divider,
              ),
              const SizedBox(height: 16),
              Text(
                '暂无产品数据',
                style: TextStyle(
                  fontSize: 15,
                  color: _currentTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildGoodsCard(_goodsList[index]),
          childCount: _goodsList.length,
        ),
      ),
    );
  }

  Widget _buildGoodsCard(Goods goods) {
    final isLow = goods.isLowStock;
    final stock = goods.currentStock ?? 0;

    return Material(
      color: _currentTheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () => _showGoodsDetail(goods),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isLow
                ? Border.all(color: _currentTheme.danger.withOpacity(0.3), width: 1.5)
                : null,
            gradient: isLow
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _currentTheme.danger.withOpacity(0.05),
                      _currentTheme.surface,
                    ],
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 第一行：名称 + 库存不足标签
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goods.goodsName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _currentTheme.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLow)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _currentTheme.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '库存不足',
                        style: TextStyle(
                          fontSize: 9,
                          color: _currentTheme.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (goods.specification != null && goods.specification!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    goods.specification!,
                    style: TextStyle(
                      fontSize: 11,
                      color: _currentTheme.textSecondary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 8),
              // 第二行：type（左）+ 数量（右）
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 左侧：类型标签
                  Builder(
                    builder: (context) {
                      final isLow = goods.isLowStock;
                      final tagColor = goods.color != null && goods.color!.isNotEmpty
                          ? _getColorFromName(goods.color)
                          : (isLow ? _currentTheme.danger : _currentTheme.primary);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 颜色圆点（如果有颜色值）
                            if (goods.color != null && goods.color!.isNotEmpty) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: tagColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              goods.goodsType,
                              style: TextStyle(
                                fontSize: 10,
                                color: tagColor.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  // 右侧：数量
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$stock',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isLow ? _currentTheme.danger : _currentTheme.primary,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        goods.unit,
                        style: TextStyle(
                          fontSize: 11,
                          color: _currentTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFabMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 展开的菜单项
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _isFabMenuOpen
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 主题切换按钮
                    _buildFabButton(
                      Icons.palette,
                      _currentTheme.primary,
                      Colors.white,
                      '${_currentTheme.icon} ${_currentTheme.name}主题',
                      _switchTheme,
                    ),
                    const SizedBox(height: 10),
                    _buildFabButton(
                      Icons.add,
                      _currentTheme.surface,
                      _currentTheme.primary,
                      '新增产品',
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GoodsFormPage()),
                        );
                        if (result == true) _loadData();
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildFabButton(
                      Icons.login,
                      _currentTheme.success,
                      Colors.white,
                      '产品入库',
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const InboundPage()),
                        );
                        if (result == true) _loadData();
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildFabButton(
                      Icons.logout,
                      _currentTheme.danger,
                      Colors.white,
                      '产品出库',
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OutboundPage()),
                        );
                        if (result == true) _loadData();
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        // 主按钮（展开/关闭）
        _buildMainFabButton(),
      ],
    );
  }

  Widget _buildMainFabButton() {
    return Material(
      color: _currentTheme.primary,
      elevation: 6,
      shadowColor: _currentTheme.primary.withOpacity(0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          setState(() {
            _isFabMenuOpen = !_isFabMenuOpen;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: _isFabMenuOpen ? 0.125 : 0,
            child: Icon(
              _isFabMenuOpen ? Icons.close : Icons.add,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFabButton(
    IconData icon,
    Color bgColor,
    Color iconColor,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgColor,
        elevation: 4,
        shadowColor: bgColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
        ),
      ),
    );
  }

  void _showGoodsDetail(Goods goods) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _currentTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _currentTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goods.goodsName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _currentTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (goods.isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _currentTheme.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '库存不足',
                            style: TextStyle(
                              fontSize: 12,
                              color: _currentTheme.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem('产品类型', goods.goodsType),
                  if (goods.specification != null)
                    _buildDetailItem('规格', goods.specification!),
                  _buildDetailItem('单位', goods.unit),
                  if (goods.color != null)
                    _buildDetailItem('颜色', goods.color!),
                  _buildDetailItem('当前库存', '${goods.currentStock ?? 0} ${goods.unit}'),
                  _buildDetailItem('安全库存', '${goods.safetyStock ?? 10} ${goods.unit}'),
                  if (goods.purchasePrice != null)
                    _buildDetailItem('进价', '¥${goods.purchasePrice}'),
                  if (goods.sellingPrice != null)
                    _buildDetailItem('售价', '¥${goods.sellingPrice}'),
                  if (goods.remark != null && goods.remark!.isNotEmpty)
                    _buildDetailItem('备注', goods.remark!),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TDButton(
                          text: '编辑',
                          theme: TDButtonTheme.primary,
                          type: TDButtonType.outline,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GoodsFormPage(goods: goods),
                              ),
                            ).then((result) {
                              if (result == true) _loadData();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TDButton(
                          text: '删除',
                          theme: TDButtonTheme.danger,
                          type: TDButtonType.outline,
                          onTap: () {
                            Navigator.pop(context);
                            _deleteGoods(goods);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: _currentTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _currentTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
