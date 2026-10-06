import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/format.dart';
import '../../models/item.dart';
import '../../providers/branch_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/services.dart';
import '../../widgets/buttons.dart';
import '../../widgets/item_picker.dart';
import '../../widgets/section_card.dart';

class _Line {
  _Line(this.item);
  final Item item;
  final qty = TextEditingController();
  final cost = TextEditingController();

  double get quantity => double.tryParse(qty.text) ?? 0;
  double get unitCost => double.tryParse(cost.text) ?? 0;
  double get amount => quantity * unitCost;

  void dispose() {
    qty.dispose();
    cost.dispose();
  }
}

/// Record stock bought from a supplier. Quantities are added to the branch's stock.
class PurchaseFormScreen extends ConsumerStatefulWidget {
  const PurchaseFormScreen({super.key});

  @override
  ConsumerState<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends ConsumerState<PurchaseFormScreen> {
  final _supplier = TextEditingController();
  final _invoice = TextEditingController();
  final List<_Line> _lines = [];
  DateTime _date = dateOnly(DateTime.now());
  bool _busy = false;

  double get _total => _lines.fold(0, (s, l) => s + l.amount);

  @override
  void dispose() {
    _supplier.dispose();
    _invoice.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _addLine() async {
    final item = await pickItem(context, title: 'Add item to purchase');
    if (item == null) return;
    if (_lines.any((l) => l.item.id == item.id)) {
      if (mounted) AppToast.info(context, '${item.name} is already in this purchase');
      return;
    }
    setState(() => _lines.add(_Line(item)));
  }

  Future<void> _save() async {
    final lines = _lines.where((l) => l.quantity > 0).toList();
    if (lines.isEmpty) {
      AppToast.info(context, 'Add at least one item with a quantity');
      return;
    }
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      await ref.read(stockServiceProvider).createPurchase(
            ref.read(branchIdProvider),
            purchasedAt: DateTime(_date.year, _date.month, _date.day, now.hour, now.minute),
            supplier: _supplier.text.trim().isEmpty ? null : _supplier.text.trim(),
            invoiceNo: _invoice.text.trim().isEmpty ? null : _invoice.text.trim(),
            lines: [for (final l in lines) (itemId: l.item.id, quantity: l.quantity, unitCost: l.unitCost)],
          );
      ref.invalidate(purchasesProvider);
      ref.invalidate(itemsProvider);
      if (!mounted) return;
      AppToast.success(context, 'Purchase saved. Stock updated.');
      context.pop();
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final decimal3 = [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}'))];
    final decimal2 = [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))];

    return Scaffold(
      appBar: AppBar(title: const Text('New purchase')),
      bottomNavigationBar: BottomActionBar(
        child: Row(children: [
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(money(_total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ]),
          ),
          SizedBox(width: 170, child: PrimaryButton(label: 'Save purchase', busy: _busy, onPressed: _save)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SectionCard(
            title: 'Details',
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(children: [
              TextField(
                controller: _supplier,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Supplier', helperText: 'Optional'),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: TextField(controller: _invoice, decoration: const InputDecoration(labelText: 'Invoice no.')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => _date = dateOnly(d));
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                      ),
                      child: Text(day(_date)),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
          const SectionLabel('Items'),
          for (final (i, l) in _lines.indexed) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 6, 14),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: Text(l.item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                      onPressed: () => setState(() => _lines.removeAt(i).dispose()),
                    ),
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          controller: l.qty,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: decimal3,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(labelText: 'Quantity', suffixText: unitLabel(l.item.unit), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: l.cost,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: decimal2,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Cost',
                            prefixText: '₹ ',
                            suffixText: '/${unitLabel(l.item.unit)}',
                            isDense: true,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  if (l.amount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(money(l.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: _addLine,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add item'),
          ),
        ],
      ),
    );
  }
}
