import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/format.dart';
import '../../models/item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/services.dart';
import '../../widgets/async_view.dart';
import '../../widgets/branch_switcher.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';
import '../../widgets/status_pill.dart';

class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({super.key});

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen> {
  String _search = '';
  String? _categoryId;
  bool _byName = false;

  List<Item> _filter(List<Item> all) {
    final q = _search.toLowerCase();
    final list = all.where((i) {
      if (_categoryId != null && i.categoryId != _categoryId) return false;
      if (q.isEmpty) return true;
      return i.name.toLowerCase().contains(q) || '${i.plu}'.startsWith(q) || (i.barcode?.contains(q) ?? false);
    }).toList();
    list.sort((a, b) => _byName ? a.name.toLowerCase().compareTo(b.name.toLowerCase()) : a.plu.compareTo(b.plu));
    return list;
  }

  Future<void> _menu(String action) async {
    final branchId = ref.read(branchIdProvider);
    try {
      switch (action) {
        case 'send':
          final scales = await ref.read(scalesProvider.future);
          if (scales.isEmpty) {
            if (mounted) AppToast.info(context, 'There are no scales in this branch');
            return;
          }
          for (final s in scales) {
            await ref.read(scaleServiceProvider).runCommand(s.id, 'PUSH_ITEMS');
          }
          if (mounted) {
            AppToast.success(context, 'Items queued for ${scales.length} ${scales.length == 1 ? 'scale' : 'scales'}');
          }
        case 'clear-stock':
          if (!await confirm(context,
              title: 'Clear stock?',
              message: 'This sets the stock of every item in this branch to zero.',
              confirmLabel: 'Clear stock',
              danger: true)) {
            return;
          }
          await ref.read(stockServiceProvider).clearStock(branchId);
          ref.invalidate(itemsProvider);
          if (mounted) AppToast.success(context, 'Stock cleared');
        case 'delete-all':
          if (!await confirm(context,
              title: 'Delete all items?',
              message: 'Every item will be removed from all branches. Sales history is kept. This cannot be undone.',
              confirmLabel: 'Delete all',
              danger: true)) {
            return;
          }
          await ref.read(catalogServiceProvider).deleteAllItems();
          ref.invalidate(itemsProvider);
          if (mounted) AppToast.success(context, 'All items deleted');
      }
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsProvider);
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final canManage = ref.watch(currentUserProvider)?.canManage ?? false;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: const BranchTitle('Items'),
        actions: [
          IconButton(
            tooltip: 'Categories',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => context.push('/categories'),
          ),
          PopupMenuButton<String>(
            onSelected: _menu,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'send', child: _MenuRow(Icons.sync_rounded, 'Send items to scales')),
              if (canManage) ...[
                const PopupMenuItem(value: 'clear-stock', child: _MenuRow(Icons.layers_clear_outlined, 'Clear stock')),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete-all',
                  child: _MenuRow(Icons.delete_sweep_outlined, 'Delete all items', color: AppColors.danger),
                ),
              ],
            ],
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/item'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add item'),
            )
          : null,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SearchField(
            hint: 'Search name, PLU or barcode',
            onChanged: (v) => setState(() => _search = v.trim()),
            trailing: IconButton(
              tooltip: _byName ? 'Sorted by name' : 'Sorted by PLU',
              icon: Icon(_byName ? Icons.sort_by_alpha_rounded : Icons.format_list_numbered_rounded),
              onPressed: () => setState(() => _byName = !_byName),
            ),
          ),
        ),
        if (categories.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(label: 'All', selected: _categoryId == null, onTap: () => setState(() => _categoryId = null)),
                for (final c in categories)
                  _CategoryChip(
                    label: c.name,
                    selected: _categoryId == c.id,
                    onTap: () => setState(() => _categoryId = _categoryId == c.id ? null : c.id),
                  ),
              ],
            ),
          ),
        Expanded(
          child: AsyncView(
            value: items,
            onRetry: () => ref.invalidate(itemsProvider),
            builder: (all) {
              if (all.isEmpty) {
                return EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No items yet',
                  message: 'Add the items you sell. Each gets a PLU number the scale uses.',
                  action: canManage
                      ? FilledButton.icon(
                          onPressed: () => context.push('/item'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add first item'),
                        )
                      : null,
                );
              }
              final list = _filter(all);
              return RefreshIndicator(
                onRefresh: () => ref.refresh(itemsProvider.future),
                child: list.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 80),
                        EmptyState(icon: Icons.search_off_rounded, title: 'No matching items'),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: list.length + 1,
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                              child: Text(
                                '${list.length} ${list.length == 1 ? 'item' : 'items'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }
                          return _ItemCard(item: list[i - 1], canEdit: canManage);
                        },
                      ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label, {this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ]);
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? AppColors.primaryDark : AppColors.textSecondary,
          ),
          side: BorderSide(color: selected ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
        ),
      );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.canEdit});
  final Item item;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final lowStock = item.stock <= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: canEdit ? () => context.push('/item', extra: item) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              PluBadge(item.plu),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(
                    [
                      item.categoryName ?? 'No category',
                      if (item.gstPercent > 0) 'GST ${qty(item.gstPercent)}%',
                    ].join(' · '),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: money(item.price), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  TextSpan(
                    text: ' /${unitLabel(item.unit)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ])),
                const SizedBox(height: 4),
                Text(
                  'Stock ${qtyWithUnit(item.stock, item.unit)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: lowStock ? AppColors.danger : AppColors.textSecondary,
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
