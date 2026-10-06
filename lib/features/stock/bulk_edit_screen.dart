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
import '../../widgets/async_view.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';

enum BulkEditMode { price, stock }

/// Edit the price or the stock of many items at once, for the current branch.
class BulkEditScreen extends ConsumerWidget {
  const BulkEditScreen({super.key, required this.mode});
  final BulkEditMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);
    final title = mode == BulkEditMode.price ? 'Update prices' : 'Update stock';
    return AsyncView(
      value: items,
      onRetry: () => ref.invalidate(itemsProvider),
      builder: (list) => list.isEmpty
          ? Scaffold(
              appBar: AppBar(title: Text(title)),
              body: const EmptyState(icon: Icons.inventory_2_outlined, title: 'No items yet', message: 'Add items first.'),
            )
          : _Editor(mode: mode, items: list, title: title),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.mode, required this.items, required this.title});
  final BulkEditMode mode;
  final List<Item> items;
  final String title;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, double> _changes = {};
  String _search = '';
  bool _busy = false;

  bool get _isPrice => widget.mode == BulkEditMode.price;

  double _current(Item i) => _isPrice ? i.price : i.stock;

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  TextEditingController _controller(Item i) =>
      _controllers.putIfAbsent(i.id, () => TextEditingController(text: _fmt(_current(i))));

  void _onChanged(Item i, String text) {
    final v = double.tryParse(text);
    setState(() {
      if (v == null || v == _current(i)) {
        _changes.remove(i.id);
      } else {
        _changes[i.id] = v;
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final branchId = ref.read(branchIdProvider);
    try {
      if (_isPrice) {
        final scales = await ref.read(stockServiceProvider).setPrices(branchId, _changes);
        if (mounted) {
          AppToast.success(
            context,
            scales == 0
                ? '${_changes.length} prices saved'
                : '${_changes.length} prices saved and sent to $scales ${scales == 1 ? 'scale' : 'scales'}',
          );
        }
      } else {
        await ref.read(stockServiceProvider).setStock(branchId, _changes, note: 'Stock count');
        if (mounted) AppToast.success(context, 'Stock updated for ${_changes.length} items');
      }
      ref.invalidate(itemsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branch = ref.watch(currentBranchProvider);
    final q = _search.toLowerCase();
    final list = widget.items
        .where((i) => q.isEmpty || i.name.toLowerCase().contains(q) || '${i.plu}'.startsWith(q))
        .toList();

    return PopScope(
      canPop: _changes.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await confirm(context,
            title: 'Discard changes?',
            message: '${_changes.length} unsaved ${_changes.length == 1 ? 'change' : 'changes'} will be lost.',
            confirmLabel: 'Discard',
            danger: true);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title),
            if (branch != null)
              Text(branch.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          ]),
        ),
        bottomNavigationBar: BottomActionBar(
          child: PrimaryButton(
            label: _changes.isEmpty
                ? 'No changes'
                : 'Save ${_changes.length} ${_changes.length == 1 ? 'change' : 'changes'}',
            busy: _busy,
            onPressed: _changes.isEmpty ? null : _save,
          ),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchField(hint: 'Search name or PLU', onChanged: (v) => setState(() => _search = v.trim())),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, idx) {
                final item = list[idx];
                final changed = _changes.containsKey(item.id);
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: changed ? AppColors.primary : AppColors.border, width: changed ? 1.4 : 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            changed
                                ? 'Was ${_isPrice ? money(_current(item)) : qtyWithUnit(_current(item), item.unit)}'
                                : 'PLU ${item.plu}',
                            style: TextStyle(fontSize: 12.5, color: changed ? AppColors.primary : AppColors.textSecondary),
                          ),
                        ]),
                      ),
                      SizedBox(
                        width: 132,
                        child: TextField(
                          controller: _controller(item),
                          textAlign: TextAlign.right,
                          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: !_isPrice),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              _isPrice ? RegExp(r'^\d*\.?\d{0,2}') : RegExp(r'^-?\d*\.?\d{0,3}'),
                            ),
                          ],
                          onChanged: (t) => _onChanged(item, t),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            isDense: true,
                            prefixText: _isPrice ? '₹ ' : null,
                            suffixText: _isPrice ? null : unitLabel(item.unit),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
