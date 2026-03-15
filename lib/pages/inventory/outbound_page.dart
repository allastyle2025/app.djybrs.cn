import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../models/inventory/goods.dart';
import '../../models/inventory/outbound_record.dart';
import '../../services/inventory/inventory_service.dart';
import '../../services/inventory/inventory_theme_manager.dart';

/// 出库页面 - 批量出库
class OutboundPage extends StatefulWidget {
  const OutboundPage({super.key});

  @override
  State<OutboundPage> createState() => _OutboundPageState();
}

class _OutboundPageState extends State<OutboundPage> {
  List<Goods> _goodsList = [];
  List<String> _halls = [];
  String? _selectedHall;
  DateTime _outboundDate = DateTime.now();
  bool _isLoading = false;
  bool _isSubmitting = false;

  /// 产品数量映射 <goodsId, quantity>
  final Map<int, int> _quantities = {};

  /// 选中的产品ID集合
  final Set<int> _selectedGoodsIds = {};

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
      final goods = await InventoryService.getAllGoods();
      final halls = await InventoryService.getHalls();
      setState(() {
        _goodsList = goods;
        _halls = halls;
        // 初始化数量为0，默认不选中
        for (var g in goods) {
          if (g.goodsId != null) {
            _quantities[g.goodsId!] = 0;
          }
        }
      });
    } catch (e) {
      TDToast.showText('加载数据失败: $e', context: context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _outboundDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _outboundDate = date);
    }
  }

  /// 获取已选择的产品列表（有数量的）
  List<MapEntry<int, int>> get _selectedItems {
    return _quantities.entries
        .where((e) => e.value > 0 && _selectedGoodsIds.contains(e.key))
        .toList();
  }

  /// 获取总出库数量
  int get _totalQuantity {
    return _quantities.entries
        .where((e) => _selectedGoodsIds.contains(e.key))
        .fold(0, (sum, q) => sum + q.value);
  }

  /// 获取当前显示的产品列表
  List<Goods> get _displayedGoods {
    return _goodsList.where((g) => _selectedGoodsIds.contains(g.goodsId)).toList();
  }

  Future<void> _submit() async {
    if (_selectedHall == null) {
      TDToast.showText('请选择出库位置', context: context);
      return;
    }

    final selectedItems = _selectedItems;
    if (selectedItems.isEmpty) {
      TDToast.showText('请至少选择一个产品', context: context);
      return;
    }

    // 检查库存
    for (var entry in selectedItems) {
      final goods = _goodsList.firstWhere((g) => g.goodsId == entry.key);
      if ((goods.currentStock ?? 0) < entry.value) {
        TDToast.showText(
          '${goods.goodsName} 库存不足，当前库存: ${goods.currentStock ?? 0}',
          context: context,
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // 批量提交出库记录
      for (var entry in selectedItems) {
        final record = OutboundRecord(
          goodsId: entry.key,
          quantity: entry.value,
          destination: _selectedHall!,
          outboundDate: _outboundDate,
        );
        await InventoryService.createOutbound(record);
      }

      TDToast.showText('批量出库成功，共 ${_selectedItems.length} 个产品', context: context);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      TDToast.showText('出库失败: $e', context: context);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showHallSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: _currentTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _currentTheme.divider)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '选择出库位置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _currentTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _currentTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _halls.isEmpty
                  ? Center(child: TDEmpty(emptyText: '暂无位置'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.0,
                      ),
                      itemCount: _halls.length,
                      itemBuilder: (context, index) {
                        final hall = _halls[index];
                        final isSelected = _selectedHall == hall;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedHall = hall);
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _currentTheme.primary.withOpacity(0.1)
                                  : _currentTheme.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? _currentTheme.primary
                                    : _currentTheme.divider,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                hall,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? _currentTheme.primary
                                      : _currentTheme.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示出库汇总单弹窗
  void _showOutboundSummary() {
    if (_selectedHall == null) {
      TDToast.showText('请选择出库位置', context: context);
      return;
    }
    
    if (_selectedItems.isEmpty) {
      TDToast.showText('请选择至少一个产品', context: context);
      return;
    }
    
    final dateStr = '${_outboundDate.year}-${_outboundDate.month.toString().padLeft(2, '0')}-${_outboundDate.day.toString().padLeft(2, '0')}';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _currentTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 40,
            maxWidth: MediaQuery.of(context).size.width - 40,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_selectedHall出库单',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _currentTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '出库日期: $dateStr',
                  style: TextStyle(
                    fontSize: 14,
                    color: _currentTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: _currentTheme.background,
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: _currentTheme.divider),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       ..._selectedItems.map((item) {
                         final goods = _goodsList.firstWhere((g) => g.goodsId == item.key);
                         return Padding(
                           padding: const EdgeInsets.symmetric(vertical: 6),
                           child: Row(
                             children: [
                               Container(
                                 width: 8,
                                 height: 8,
                                 decoration: BoxDecoration(
                                   color: _currentTheme.primary,
                                   shape: BoxShape.circle,
                                 ),
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Text(
                                   '${goods.goodsName} × ${item.value} ${goods.unit}',
                                   style: TextStyle(
                                     fontSize: 14,
                                     color: _currentTheme.textSecondary,
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         );
                       }).toList(),
                     ],
                   ),
                 ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _currentTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _currentTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.summarize, size: 20, color: _currentTheme.primary),
                      const SizedBox(width: 10),
                      Text(
                         '总计:',
                         style: TextStyle(
                           fontSize: 14,
                           color: _currentTheme.primary,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                       const SizedBox(width: 10),
                       Text(
                         '$_totalQuantity 件',
                         style: TextStyle(
                           fontSize: 14,
                           color: _currentTheme.primary,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 16,
                          color: _currentTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TDButton(
                      text: '确认出库',
                      theme: TDButtonTheme.danger,
                      size: TDButtonSize.large,
                      onTap: () {
                        Navigator.pop(context);
                        _submit();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateQuantity(int goodsId, int delta) {
    setState(() {
      final current = _quantities[goodsId] ?? 0;
      final newValue = current + delta;
      if (newValue >= 0) {
        _quantities[goodsId] = newValue;
      }
    });
  }

  void _setQuantity(int goodsId, String value) {
    final quantity = int.tryParse(value) ?? 0;
    setState(() {
      _quantities[goodsId] = quantity < 0 ? 0 : quantity;
    });
  }

  /// 显示产品选择弹窗
  void _showGoodsSelector() {
    final Set<int> _selectedGoodsIdsTemp = Set<int>.from(_selectedGoodsIds);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final availableGoods = _goodsList.where((g) => (g.currentStock ?? 0) > 0).length;
          final isAllSelected = _selectedGoodsIdsTemp.length == availableGoods;
          return SafeArea(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: _currentTheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: _currentTheme.divider)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '选择出库产品',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _currentTheme.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                if (isAllSelected) {
                                  _selectedGoodsIdsTemp.clear();
                                } else {
                                  _selectedGoodsIdsTemp.clear();
                                  for (var g in _goodsList) {
                                    if (g.goodsId != null && (g.currentStock ?? 0) > 0) {
                                      _selectedGoodsIdsTemp.add(g.goodsId!);
                                    }
                                  }
                                }
                              });
                            },
                            child: Text(
                              isAllSelected ? '全不选' : '全选',
                              style: TextStyle(color: _currentTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _goodsList.isEmpty
                      ? Center(child: TDEmpty(emptyText: '暂无产品'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.8,
                          ),
                          itemCount: _goodsList.length,
                          itemBuilder: (context, index) {
                            final goods = _goodsList[index];
                            final stock = goods.currentStock ?? 0;
                            final isSelected = goods.goodsId != null && _selectedGoodsIdsTemp.contains(goods.goodsId!);
                            final isOutOfStock = stock <= 0;
                            return InkWell(
                              onTap: isOutOfStock
                                  ? null
                                  : () {
                                      setModalState(() {
                                        if (goods.goodsId != null) {
                                          if (isSelected) {
                                            _selectedGoodsIdsTemp.remove(goods.goodsId!);
                                          } else {
                                            _selectedGoodsIdsTemp.add(goods.goodsId!);
                                          }
                                        }
                                      });
                                    },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isOutOfStock
                                      ? _currentTheme.textSecondary.withOpacity(0.03)
                                      : isSelected
                                          ? _currentTheme.background
                                          : _currentTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isOutOfStock
                                        ? _currentTheme.divider.withOpacity(0.5)
                                        : isSelected
                                            ? _currentTheme.primary
                                            : _currentTheme.divider,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            goods.goodsName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: isOutOfStock
                                                  ? _currentTheme.textSecondary.withOpacity(0.4)
                                                  : _currentTheme.textPrimary,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (!isOutOfStock)
                                          Icon(
                                            isSelected
                                                ? Icons.check_circle
                                                : Icons.circle_outlined,
                                            color: isSelected
                                                ? _currentTheme.primary
                                                : _currentTheme.textSecondary,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '库存: $stock ${goods.unit}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _currentTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _currentTheme.surface,
                    border: Border(top: BorderSide(color: _currentTheme.divider)),
                  ),
                  child: Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedGoodsIds.clear();
                          _selectedGoodsIds.addAll(_selectedGoodsIdsTemp);
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '确定 (${_selectedGoodsIdsTemp.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final selectedCount = _selectedItems.length;

    return Scaffold(
      backgroundColor: _currentTheme.background,
      appBar: TDNavBar(
        title: '产品出库',
        backgroundColor: _currentTheme.surface,
        useDefaultBack: true,
      ),
      body: _isLoading
          ? Center(child: TDCircleIndicator(color: _currentTheme.primary))
          : ListView(
              padding: EdgeInsets.all(16).copyWith(bottom: 16 + bottomPadding),
              children: [
                _buildSection('出库位置', [
                  InkWell(
                    onTap: _showHallSelector,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: _currentTheme.divider),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(TDIcons.houses, color: _currentTheme.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedHall ?? '点击选择出库位置',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedHall == null
                                    ? _currentTheme.textSecondary
                                    : _currentTheme.textPrimary,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: _currentTheme.divider),
                        ],
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSectionWithAction(
                  '出库产品',
                  action: TextButton.icon(
                    onPressed: _showGoodsSelector,
                    icon: Icon(Icons.add_circle_outline, size: 18, color: _currentTheme.primary),
                    label: Text(
                      '添加',
                      style: TextStyle(color: _currentTheme.primary),
                    ),
                  ),
                  children: [
                    if (_displayedGoods.isEmpty)
                      Center(
                        child: ElevatedButton(
                          onPressed: _showGoodsSelector,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            '添加出库产品',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._displayedGoods.map((goods) => _buildGoodsItem(goods)),
                  ],
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isSubmitting
                      ? Center(child: TDCircleIndicator(color: _currentTheme.primary))
                      : TDButton(
                          text: selectedCount > 0 ? '出库 ($selectedCount)' : '出库',
                          theme: TDButtonTheme.danger,
                          size: TDButtonSize.large,
                          isBlock: true,
                          onTap: _showOutboundSummary,
                        ),
                ),
                SizedBox(height: bottomPadding),
              ],
            ),
    );
  }

  Widget _buildGoodsItem(Goods goods) {
    final quantity = _quantities[goods.goodsId] ?? 0;
    final stock = goods.currentStock ?? 0;
    final isLow = goods.isLowStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: quantity == 0 ? _currentTheme.primary.withOpacity(0.05) : _currentTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: quantity == 0 ? _currentTheme.primary.withOpacity(0.3) : _currentTheme.divider,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goods.goodsName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _currentTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (isLow)
                      TDTag(
                        '库存不足',
                        theme: TDTagTheme.danger,
                        size: TDTagSize.small,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '库存: $stock ${goods.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isLow ? _currentTheme.danger : _currentTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildQuantityControl(goods.goodsId!, quantity, stock),
        ],
      ),
    );
  }

  Widget _buildQuantityControl(int goodsId, int quantity, int maxStock) {
    return Container(
      decoration: BoxDecoration(
        color: _currentTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _currentTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: quantity > 0 ? () => _updateQuantity(goodsId, -1) : null,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            highlightColor: _currentTheme.primary.withOpacity(0.2),
            splashColor: _currentTheme.primary.withOpacity(0.1),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: quantity == 0 ? _currentTheme.primary.withOpacity(0.1) : null,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              ),
              child: Icon(
                Icons.remove,
                size: 18,
                color: quantity == 0 ? _currentTheme.primary : _currentTheme.textSecondary.withOpacity(0.3),
              ),
            ),
          ),
          Container(
            width: 50,
            height: 36,
            alignment: Alignment.center,
            child: TextField(
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _currentTheme.textPrimary,
              ),
              controller: TextEditingController(text: quantity.toString()),
              onChanged: (value) => _setQuantity(goodsId, value),
            ),
          ),
          InkWell(
            onTap: quantity < maxStock ? () => _updateQuantity(goodsId, 1) : null,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
            highlightColor: _currentTheme.primary.withOpacity(0.2),
            splashColor: _currentTheme.primary.withOpacity(0.1),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: quantity < maxStock ? _currentTheme.primary.withOpacity(0.1) : null,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
              ),
              child: Icon(
                Icons.add,
                size: 18,
                color: quantity < maxStock ? _currentTheme.primary : _currentTheme.textSecondary.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _currentTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _currentTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionWithAction(
    String title, {
    required Widget action,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _currentTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _currentTheme.textPrimary,
                ),
              ),
              action,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
