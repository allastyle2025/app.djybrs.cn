import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../../models/inventory/goods.dart';
import '../../services/inventory/inventory_service.dart';

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

  @override
  void initState() {
    super.initState();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: TDNavBar(
        title: isEdit ? '编辑产品' : '新增产品',
        backgroundColor: Colors.white,
        useDefaultBack: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16).copyWith(bottom: 16 + bottomPadding),
        children: [
          _buildSection('基本信息', [
            TDInput(
              controller: _nameController,
              leftLabel: '产品名称',
              hintText: '请输入产品名称',
              leftLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              required: true,
            ),
            const SizedBox(height: 16),
            TDInput(
              controller: _typeController,
              leftLabel: '产品类型',
              hintText: '请输入产品类型',
              leftLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              required: true,
            ),
            const SizedBox(height: 16),
            TDInput(
              controller: _specController,
              leftLabel: '规格',
              hintText: '请输入规格（可选）',
              leftLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TDInput(
                    controller: _unitController,
                    leftLabel: '单位',
                    hintText: '如：个、件、箱',
                    leftLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
                    required: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TDInput(
                    controller: _colorController,
                    leftLabel: '颜色',
                    hintText: '可选',
                    leftLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('价格信息', [
            TDInput(
              controller: _purchasePriceController,
              leftLabel: '进价',
              hintText: '请输入进价（可选）',
              leftLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              inputType: TextInputType.number,
              rightWidget: const Text('元'),
            ),
            const SizedBox(height: 16),
            TDInput(
              controller: _sellingPriceController,
              leftLabel: '售价',
              hintText: '请输入售价（可选）',
              leftLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              inputType: TextInputType.number,
              rightWidget: const Text('元'),
            ),
            const SizedBox(height: 16),
            TDInput(
              controller: _safetyStockController,
              leftLabel: '安全库存',
              hintText: '低于此值将预警',
              leftLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              inputType: TextInputType.number,
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('其他信息', [
            TDInput(
              controller: _remarkController,
              leftLabel: '备注',
              hintText: '请输入备注（可选）',
              leftLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 3,
            ),
          ]),
          const SizedBox(height: 32),
          _isLoading
              ? const Center(child: TDCircleIndicator())
              : TDButton(
                  text: isEdit ? '保存修改' : '创建产品',
                  theme: TDButtonTheme.primary,
                  size: TDButtonSize.large,
                  isBlock: true,
                  onTap: _save,
                ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
