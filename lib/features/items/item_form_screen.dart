import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../models/item.dart';
import '../../providers/branch_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/services.dart';
import '../../widgets/barcode_scanner.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/section_card.dart';

/// Add a new item, or edit [item].
class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key, this.item});
  final Item? item;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _plu = TextEditingController(text: widget.item == null ? '' : '${widget.item!.plu}');
  late final _barcode = TextEditingController(text: widget.item?.barcode);
  late final _price = TextEditingController(text: widget.item == null ? '' : _num(widget.item!.price));
  late final _tare = TextEditingController(text: widget.item == null ? '0' : '${widget.item!.tareGrams}');
  late final _gst = TextEditingController(text: widget.item == null ? '0' : _num(widget.item!.gstPercent));
  late String _unit = widget.item?.unit ?? 'KG';
  late String _gstMode = widget.item?.gstMode ?? 'INCLUDED';
  late String? _categoryId = widget.item?.categoryId;
  bool _busy = false;

  bool get _editing => widget.item != null;

  static String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void initState() {
    super.initState();
    if (!_editing) {
      ref.read(catalogServiceProvider).nextPlu().then((p) {
        if (mounted && _plu.text.isEmpty) _plu.text = '$p';
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _plu, _barcode, _price, _tare, _gst]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final branchId = ref.read(branchIdProvider);
    final price = double.parse(_price.text);
    final fields = {
      'name': _name.text.trim(),
      'plu': int.parse(_plu.text),
      'barcode': _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      'unit': _unit,
      'tareGrams': _unit == 'KG' ? int.tryParse(_tare.text) ?? 0 : 0,
      'gstPercent': double.tryParse(_gst.text) ?? 0,
      'gstMode': _gstMode,
      'categoryId': _categoryId,
    };
    try {
      final catalog = ref.read(catalogServiceProvider);
      if (_editing) {
        await catalog.updateItem(widget.item!.id, fields);
        if (price != widget.item!.price) {
          await ref.read(stockServiceProvider).setPrices(branchId, {widget.item!.id: price});
        }
      } else {
        await catalog.createItem({...fields, 'defaultPrice': price, 'price': price, 'branchId': branchId});
      }
      ref.invalidate(itemsProvider);
      ref.invalidate(categoriesProvider);
      if (!mounted) return;
      AppToast.success(context, _editing ? 'Item saved' : 'Item added');
      context.pop();
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirm(
      context,
      title: 'Delete ${widget.item!.name}?',
      message: 'The item is removed from every branch and from the scales on their next sync.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok) return;
    try {
      await ref.read(catalogServiceProvider).deleteItem(widget.item!.id);
      ref.invalidate(itemsProvider);
      if (!mounted) return;
      AppToast.success(context, 'Item deleted');
      context.pop();
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    }
  }

  Future<void> _newCategory() async {
    final name = await promptText(context, title: 'New category', label: 'Category name', confirmLabel: 'Add');
    if (name == null) return;
    try {
      await ref.read(catalogServiceProvider).createCategory(name);
      ref.invalidate(categoriesProvider);
      final list = await ref.read(categoriesProvider.future);
      setState(() => _categoryId = list.where((c) => c.name == name).lastOrNull?.id ?? _categoryId);
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final branch = ref.watch(currentBranchProvider);
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))];

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit item' : 'New item'),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Delete item',
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              onPressed: _delete,
            ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(label: _editing ? 'Save changes' : 'Add item', busy: _busy, onPressed: _save),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SectionCard(
              title: 'Item',
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 40,
                  decoration: const InputDecoration(labelText: 'Item name', counterText: ''),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _plu,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'PLU', helperText: 'Number on the scale'),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return (n == null || n < 1 || n > AppConstants.maxPlu) ? '1 to ${AppConstants.maxPlu}' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _barcode,
                      decoration: InputDecoration(
                        labelText: 'Barcode',
                        helperText: 'Optional',
                        suffixIcon: IconButton(
                          tooltip: 'Scan barcode',
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          onPressed: () async {
                            final code = await scanBarcode(context);
                            if (code != null) setState(() => _barcode.text = code);
                          },
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                DropdownButtonFormField<String?>(
                  initialValue: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No category')),
                    for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _newCategory,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New category'),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Price',
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'KG', label: Text('Per kg'), icon: Icon(Icons.scale_outlined)),
                    ButtonSegment(value: 'PACK', label: Text('Per pack'), icon: Icon(Icons.inventory_2_outlined)),
                  ],
                  selected: {_unit},
                  onSelectionChanged: (s) => setState(() => _unit = s.first),
                ),
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: decimal,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        prefixText: '₹ ',
                        suffixText: _unit == 'KG' ? '/ kg' : '/ pack',
                        helperText: branch == null ? null : 'For ${branch.name}',
                      ),
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Enter a price' : null,
                    ),
                  ),
                  if (_unit == 'KG') ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _tare,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Tare', suffixText: 'g', helperText: 'Container weight'),
                      ),
                    ),
                  ],
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'GST',
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(children: [
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    controller: _gst,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: decimal,
                    decoration: const InputDecoration(labelText: 'Rate', suffixText: '%'),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n < 0 || n > 100) ? '0 to 100' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'INCLUDED', label: Text('Included')),
                      ButtonSegment(value: 'EXCLUDED', label: Text('Extra')),
                    ],
                    selected: {_gstMode},
                    onSelectionChanged: (s) => setState(() => _gstMode = s.first),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Saved items are sent to the scales in this branch automatically.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
