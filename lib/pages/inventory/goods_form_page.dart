import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../models/inventory/goods.dart';
import '../../services/inventory/inventory_service.dart';
import '../../services/inventory/inventory_theme_manager.dart';

/// 产品表单页面（新增/编辑）
class GoodsFormPage extends StatefulWidget {
  final Goods? goods;

  const GoodsFormPage({super.key, this.goods});

  @override
  State<GoodsFormPage> createState() => _GoodsFormPageState();
}

class _GoodsFormPageState extends State<GoodsFormPage> {
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _specController = TextEditingController();
  final _unitController = TextEditingController(text: '个');
  final _colorController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _safetyStockController = TextEditingController(text: '10');
  final _remarkController = TextEditingController();

  bool _isLoading = false;
  final _themeManager = InventoryThemeManager();

  AppTheme get _currentTheme => _themeManager.currentTheme;

  @override
  void initState() {
    super.initState();
    _themeManager.init();
    if (widget.goods != null) {
      _nameController.text = widget.goods!.goodsName;
      _typeController.text = widget.goods!.goodsType;
      _specController.text = widget.goods!.specification ?? '';
      _unitController.text = widget.goods!.unit;
      _colorController.text = widget.goods!.color ?? '';
      _purchasePriceController.text = widget.goods!.purchasePrice?.toString() ?? '';
      _sellingPriceController.text = widget.goods!.sellingPrice?.toString() ?? '';
      _safetyStockController.text = widget.goods!.safetyStock?.toString() ?? '10';
      _remarkController.text = widget.goods!.remark ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _specController.dispose();
    _unitController.dispose();
    _colorController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _safetyStockController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      TDToast.showText('请输入产品名称', context: context);
      return;
    }
    if (_typeController.text.trim().isEmpty) {
      TDToast.showText('请输入产品类型', context: context);
      return;
    }
    if (_unitController.text.trim().isEmpty) {
      TDToast.showText('请输入单位', context: context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final goods = Goods(
        goodsId: widget.goods?.goodsId,
        goodsName: _nameController.text.trim(),
        goodsType: _typeController.text.trim(),
        specification: _specController.text.trim().isEmpty
            ? null
            : _specController.text.trim(),
        unit: _unitController.text.trim(),
        color: _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim(),
        purchasePrice: _purchasePriceController.text.isEmpty
            ? null
            : double.tryParse(_purchasePriceController.text),
        sellingPrice: _sellingPriceController.text.isEmpty
            ? null
            : double.tryParse(_sellingPriceController.text),
        safetyStock: int.tryParse(_safetyStockController.text) ?? 10,
        remark: _remarkController.text.trim().isEmpty
            ? null
            : _remarkController.text.trim(),
      );

      if (widget.goods == null) {
        await InventoryService.createGoods(goods);
        TDToast.showText('创建成功', context: context);
      } else {
        await InventoryService.updateGoods(widget.goods!.goodsId!, goods);
        TDToast.showText('更新成功', context: context);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      TDToast.showText('保存失败: $e', context: context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.goods != null;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Theme(
      data: Theme.of(context).copyWith(
        brightness: _currentTheme.brightness,
      ),
      child: Scaffold(
        backgroundColor: _currentTheme.background,
        appBar: AppBar(
          title: Text(
            isEdit ? '编辑产品' : '新增产品',
            style: TextStyle(
              color: _currentTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: _currentTheme.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: _currentTheme.textPrimary),
        ),
        body: Stack(
          children: [
            ListView(
              padding: EdgeInsets.all(16).copyWith(bottom: 16 + bottomPadding + 80),
              children: [
                _buildSection('基本信息', [
                  _buildInput(
                    controller: _nameController,
                    label: '产品名称',
                    hint: '请输入产品名称',
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    controller: _typeController,
                    label: '产品类型',
                    hint: '请输入产品类型',
                    required: true,
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    controller: _specController,
                    label: '规格',
                    hint: '请输入规格（可选）',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildInput(
                          controller: _unitController,
                          label: '单位',
                          hint: '如：个、件、箱',
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildInput(
                          controller: _colorController,
                          label: '颜色',
                          hint: '可选',
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSection('价格信息', [
                  _buildInput(
                    controller: _purchasePriceController,
                    label: '进价',
                    hint: '请输入进价（可选）',
                    inputType: TextInputType.number,
                    suffix: '元',
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    controller: _sellingPriceController,
                    label: '售价',
                    hint: '请输入售价（可选）',
                    inputType: TextInputType.number,
                    suffix: '元',
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    controller: _safetyStockController,
                    label: '安全库存',
                    hint: '低于此值将预警',
                    inputType: TextInputType.number,
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSection('其他信息', [
                  _buildInput(
                    controller: _remarkController,
                    label: '备注',
                    hint: '请输入备注（可选）',
                    maxLines: 3,
                  ),
                ]),
                const SizedBox(height: 32),
                _isLoading
                    ? Center(
                        child: TDCircleIndicator(
                          color: _currentTheme.primary,
                        ),
                      )
                    : _buildSubmitButton(isEdit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _currentTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _currentTheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: _currentTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _currentTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    TextInputType inputType = TextInputType.text,
    String? suffix,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _currentTheme.textPrimary,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _currentTheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _currentTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _currentTheme.divider,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: inputType,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 15,
              color: _currentTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 14,
                color: _currentTheme.textSecondary.withOpacity(0.6),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              suffixText: suffix,
              suffixStyle: TextStyle(
                fontSize: 14,
                color: _currentTheme.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isEdit) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _currentTheme.primary,
            _currentTheme.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _currentTheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _save,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isEdit ? Icons.save : Icons.add_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isEdit ? '保存修改' : '创建产品',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
