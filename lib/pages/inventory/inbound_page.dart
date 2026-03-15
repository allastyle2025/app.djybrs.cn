import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../models/inventory/goods.dart';
import '../../models/inventory/inbound_record.dart';
import '../../services/inventory/inventory_service.dart';
import '../../services/inventory/inventory_theme_manager.dart';

/// 入库页面
class InboundPage extends StatefulWidget {
  const InboundPage({super.key});

  @override
  State<InboundPage> createState() => _InboundPageState();
}

class _InboundPageState extends State<InboundPage> {
  List<Goods> _goodsList = [];
  Set<int> _selectedGoodsIds = {};
  Set<int> _selectedGoodsIdsTemp = {};
  List<Goods> _displayedGoods = [];
  Map<int, int> _selectedItems = {};
  DateTime _inboundDate = DateTime.now();
  bool _isLoading = false;
  bool _isSubmitting = false;

  final _themeManager = InventoryThemeManager();

  AppTheme get _currentTheme => _themeManager.currentTheme;

  int get _totalQuantity {
    return _selectedItems.values.fold(0, (sum, quantity) => sum + quantity);
  }

  @override
  void initState() {
    super.initState();
    _themeManager.init();
    _loadGoods();
  }

  Future<void> _loadGoods() async {
    setState(() => _isLoading = true);
    try {
      final goods = await InventoryService.getAllGoods();
      setState(() => _goodsList = goods);
    } catch (e) {
      TDToast.showText('加载产品失败: $e', context: context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    TDPicker.showDatePicker(
      context,
      title: '选择入库时间',
      onConfirm: (selected) {
        final year = selected['year'] as int;
        final month = selected['month'] as int;
        final day = selected['day'] as int;
        final selectedDate = DateTime(year, month, day);
        setState(() => _inboundDate = selectedDate);
        Navigator.of(context).pop();
      },
      dateStart: [2020, 1, 1],
      dateEnd: [
        DateTime.now().year, 
        DateTime.now().month, 
        DateTime.now().day
      ],
      initialDate: [
        _inboundDate.year, 
        _inboundDate.month, 
        _inboundDate.day
      ],
      //backgroundColor: _currentTheme.surface,
      //titleDividerColor: _currentTheme.divider,
      //leftTextStyle: TextStyle(color: _currentTheme.textPrimary),
      //centerTextStyle: TextStyle(color: _currentTheme.textPrimary),
      //rightTextStyle: TextStyle(color: _currentTheme.primary),
    );
  }

  Future<void> _submit() async {
    if (_selectedItems.isEmpty) {
      TDToast.showText('请选择至少一个产品', context: context);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      for (var entry in _selectedItems.entries) {
        final goods = _goodsList.firstWhere((g) => g.goodsId == entry.key);
        final quantity = entry.value;
        
        if (quantity <= 0) {
          TDToast.showText('${goods.goodsName}的入库数量必须大于0', context: context);
          continue;
        }

        final record = InboundRecord(
          goodsId: goods.goodsId!,
          quantity: quantity,
          inboundDate: _inboundDate,
        );

        await InventoryService.createInbound(record);
      }
      
      TDToast.showText('批量入库成功', context: context);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      TDToast.showText('入库失败: $e', context: context);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _updateDisplayedGoods() {
    setState(() {
      _displayedGoods = _goodsList
          .where((goods) => _selectedGoodsIds.contains(goods.goodsId))
          .toList();
    });
  }

  void _updateSelectedItems() {
    setState(() {
      _selectedItems.clear();
      for (var goodsId in _selectedGoodsIds) {
        _selectedItems[goodsId] = _selectedItems[goodsId] ?? 1;
      }
      _updateDisplayedGoods();
    });
  }

  void _showGoodsSelector() {
    _selectedGoodsIdsTemp = Set.from(_selectedGoodsIds);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final availableGoods = _goodsList.where((g) => g.goodsId != null).length;
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
                          '选择入库产品',
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
                                      if (g.goodsId != null) {
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
                              final isSelected = _selectedGoodsIdsTemp.contains(goods.goodsId);
                              final isOutOfStock = stock <= 0;
                              
                              return GestureDetector(
                                onTap: isOutOfStock
                                    ? null
                                    : () {
                                        setModalState(() {
                                          if (isSelected) {
                                            _selectedGoodsIdsTemp.remove(goods.goodsId!);
                                          } else {
                                            _selectedGoodsIdsTemp.add(goods.goodsId!);
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
                                                    : isSelected
                                                        ? _currentTheme.primary
                                                        : _currentTheme.textPrimary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (!isOutOfStock)
                                            Icon(
                                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                                              color: isSelected
                                                  ? _currentTheme.primary
                                                  : _currentTheme.textSecondary,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${goods.goodsType} · ${goods.currentStock ?? 0} ${goods.unit}',
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
                    child: TDButton(
                      text: '确定 (${_selectedGoodsIdsTemp.length})',
                      theme: TDButtonTheme.primary,
                      size: TDButtonSize.large,
                      isBlock: true,
                      onTap: () {
                        setState(() {
                          _selectedGoodsIds.clear();
                          _selectedGoodsIds.addAll(_selectedGoodsIdsTemp);
                          _updateSelectedItems();
                        });
                        Navigator.pop(context);
                      },
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

  Widget _buildGoodsItem(Goods goods) {
    if (goods.goodsId == null) return const SizedBox.shrink();
    
    final quantity = _selectedItems[goods.goodsId!] ?? 1;
    final stock = goods.currentStock ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: quantity == 1 ? _currentTheme.primary.withOpacity(0.05) : _currentTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: quantity == 1 ? _currentTheme.primary.withOpacity(0.3) : _currentTheme.divider,
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
                  ],
                ),
                const SizedBox(height: 4),
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
          const SizedBox(width: 12),
          _buildQuantityControl(goods.goodsId!, quantity),
        ],
      ),
    );
  }

  Widget _buildQuantityControl(int goodsId, int quantity) {
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
            onTap: quantity == 1 
                ? () => _removeProduct(goodsId)
                : quantity > 1 ? () => _updateQuantity(goodsId, -1) : null,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            highlightColor: _currentTheme.primary.withOpacity(0.2),
            splashColor: _currentTheme.primary.withOpacity(0.1),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: quantity == 1 ? _currentTheme.danger.withOpacity(0.1) : _currentTheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              ),
              child: Icon(
                quantity == 1 ? Icons.delete_outline : Icons.remove,
                size: 18,
                color: quantity == 1 ? _currentTheme.danger : _currentTheme.primary,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 36,
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _currentTheme.textPrimary,
              ),
            ),
          ),
          InkWell(
            onTap: () => _updateQuantity(goodsId, 1),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
            highlightColor: _currentTheme.primary.withOpacity(0.2),
            splashColor: _currentTheme.primary.withOpacity(0.1),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
              ),
              child: Icon(
                Icons.add,
                size: 18,
                color: _currentTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeProduct(int goodsId) {
    setState(() {
      _selectedItems.remove(goodsId);
      _selectedGoodsIds.remove(goodsId);
      _updateDisplayedGoods();
    });
  }

  void _updateQuantity(int goodsId, int delta) {
    setState(() {
      final current = _selectedItems[goodsId] ?? 1;
      final newValue = current + delta;
      if (newValue >= 1) {
        _selectedItems[goodsId] = newValue;
      }
    });
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

  Widget _buildSectionWithAction(String title, {required Widget action, required List<Widget> children}) {
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

  /// 显示入库汇总单弹窗
  void _showInboundSummary() {
    if (_selectedItems.isEmpty) {
      TDToast.showText('请选择至少一个产品', context: context);
      return;
    }
    
    final dateStr = '${_inboundDate.year}-${_inboundDate.month.toString().padLeft(2, '0')}-${_inboundDate.day.toString().padLeft(2, '0')}';
    
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
                  '入库单',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _currentTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '入库日期: $dateStr',
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
                       ..._selectedItems.entries.map((item) {
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
                      text: '确认入库',
                      theme: TDButtonTheme.primary,
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final selectedCount = _selectedItems.length;

    return Scaffold(
      backgroundColor: _currentTheme.background,
      appBar: TDNavBar(
        title: '产品入库',
        backgroundColor: _currentTheme.surface,
        useDefaultBack: true,
      ),
      body: _isLoading
          ? Center(child: TDCircleIndicator(color: _currentTheme.primary))
          : ListView(
              padding: EdgeInsets.all(16).copyWith(bottom: 16 + bottomPadding),
              children: [
                _buildSection('入库时间', [
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: _currentTheme.divider),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: _currentTheme.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${_inboundDate.year}-${_inboundDate.month.toString().padLeft(2, '0')}-${_inboundDate.day.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 16,
                                color: _currentTheme.textPrimary,
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
                  '入库产品',
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
                            '添加入库产品',
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
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isSubmitting
                      ? Center(child: TDCircleIndicator(color: _currentTheme.primary))
                      : TDButton(
                          text: selectedCount > 0 ? '入库 ($selectedCount)' : '入库',
                          theme: TDButtonTheme.primary,
                          size: TDButtonSize.large,
                          isBlock: true,
                          onTap: _showInboundSummary,
                        ),
                ),
              ],
            ),
    );
  }
}