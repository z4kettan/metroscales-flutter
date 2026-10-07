import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/format.dart';
import '../models/item.dart';
import '../providers/data_providers.dart';
import 'async_view.dart';
import 'empty_state.dart';
import 'search_field.dart';
import 'status_pill.dart';

/// A searchable list of the shop's items in a bottom sheet. Returns the
/// chosen item, or null.
Future<Item?> pickItem(BuildContext context, {String title = 'Choose item', bool allowClear = false}) {
  return showModalBottomSheet<Item>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.9,
      child: _ItemPicker(title: title, allowClear: allowClear),
    ),
  );
}

/// Returned by [pickItem] when the user taps "Clear key".
const clearedItem = Item(id: '', plu: 0, name: '');

class _ItemPicker extends ConsumerStatefulWidget {
  const _ItemPicker({required this.title, required this.allowClear});
  final String title;
  final bool allowClear;

  @override
  ConsumerState<_ItemPicker> createState() => _ItemPickerState();
}

class _ItemPickerState extends ConsumerState<_ItemPicker> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsProvider);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 16, 12),
        child: Row(children: [
          Expanded(child: Text(widget.title, style: context.tt.headlineSmall)),
          if (widget.allowClear)
            TextButton.icon(
              onPressed: () => Navigator.pop(context, clearedItem),
              style: TextButton.styleFrom(foregroundColor: context.cs.error),
              icon: const Icon(Icons.backspace_outlined, size: 18),
              label: const Text('Clear key'),
            ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SearchField(hint: 'Search name or PLU', onChanged: (v) => setState(() => _search = v.trim().toLowerCase())),
      ),
      Expanded(
        child: AsyncView(
          value: items,
          onRetry: () => ref.invalidate(itemsProvider),
          builder: (all) {
            final list = all
                .where((i) => _search.isEmpty || i.name.toLowerCase().contains(_search) || '${i.plu}'.startsWith(_search))
                .toList();
            if (list.isEmpty) return const EmptyState(icon: Icons.search_off_rounded, title: 'No matching items');
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final item = list[i];
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  leading: PluBadge(item.plu, size: 44),
                  title: Text(item.name),
                  subtitle: Text('${money(item.price)} / ${unitLabel(item.unit)}'),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}
