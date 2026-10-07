import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/format.dart';
import '../../models/item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/services.dart';
import '../../widgets/async_view.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/tab_page.dart';

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

    return TabPage(
      title: 'Items',
      onRefresh: () => ref.refresh(itemsProvider.future),
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) => v == 'categories' ? context.push('/categories') : _menu(v),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'categories', child: _MenuRow(Icons.category_rounded, 'Categories')),
            const PopupMenuItem(value: 'send', child: _MenuRow(Icons.sync_rounded, 'Send items to scales')),
            if (canManage) ...[
              const PopupMenuItem(value: 'clear-stock', child: _MenuRow(Icons.layers_clear_rounded, 'Clear stock')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'delete-all', child: _MenuRow(Icons.delete_sweep_rounded, 'Delete all items', danger: true)),
            ],
          ],
        ),
      ],
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/item'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New item'),
            )
          : null,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
        ),
        if (categories.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
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
          ),
        SliverAsyncView(
          value: items,
          onRetry: () => ref.invalidate(itemsProvider),
          builder: (all) {
            if (all.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.inventory_2_rounded,
                  title: 'No items yet',
                  message: 'Add the items you sell. Each gets a PLU number the scale uses.',
                  action: canManage
                      ? FilledButton.icon(
                          onPressed: () => context.push('/item'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add first item'),
                        )
                      : null,
                ),
              );
            }
            final list = _filter(all);
            if (list.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(icon: Icons.search_off_rounded, title: 'No matching items'),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.builder(
                itemCount: list.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                      child: Text(
                        '${list.length} ${list.length == 1 ? 'item' : 'items'}',
                        style: context.tt.labelLarge?.copyWith(color: context.cs.onSurfaceVariant),
                      ),
                    );
                  }
                  return _ItemCard(item: list[i - 1], canEdit: canManage);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label, {this.danger = false});
  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.cs.error : null;
    return Row(children: [
      Icon(icon, size: 20, color: color ?? context.cs.onSurfaceVariant),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(color: color)),
    ]);
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.canEdit});
  final Item item;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final noStock = item.stock <= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          onTap: canEdit ? () => context.push('/item', extra: item) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              PluBadge(item.plu),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.name, style: context.tt.titleMedium),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    StatusPill(item.categoryName ?? 'No category'),
                    if (item.gstPercent > 0) StatusPill('GST ${qty(item.gstPercent)}%', tone: Tone.primary),
                  ]),
                ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: money(item.price), style: context.tt.titleMedium),
                  TextSpan(text: ' /${unitLabel(item.unit)}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                ])),
                const SizedBox(height: 6),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.inventory_rounded, size: 14, color: noStock ? cs.error : cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    qtyWithUnit(item.stock, item.unit),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: noStock ? cs.error : cs.onSurfaceVariant),
                  ),
                ]),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
