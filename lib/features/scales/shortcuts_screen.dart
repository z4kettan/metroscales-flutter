import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_toast.dart';
import '../../models/scale.dart';
import '../../providers/data_providers.dart';
import '../../providers/services.dart';
import '../../widgets/async_view.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/item_picker.dart';

final _shortcutsProvider = FutureProvider.autoDispose.family<List<Shortcut>, String>(
  (ref, id) => ref.watch(scaleServiceProvider).shortcuts(id),
);

/// Assign items to the scale's quick keys. Each key has a normal and a
/// shifted item.
class ShortcutsScreen extends ConsumerWidget {
  const ShortcutsScreen({super.key, required this.scaleId});
  final String scaleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortcuts = ref.watch(_shortcutsProvider(scaleId));
    return AsyncView(
      value: shortcuts,
      onRetry: () => ref.invalidate(_shortcutsProvider(scaleId)),
      builder: (list) => _Editor(scaleId: scaleId, initial: list),
    );
  }
}

typedef _Key = (int keyNo, int layer);
typedef _Assigned = ({String itemId, String name, int plu});

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.scaleId, required this.initial});
  final String scaleId;
  final List<Shortcut> initial;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final Map<_Key, _Assigned> _keys = {
    for (final s in widget.initial) (s.keyNo, s.layer): (itemId: s.itemId, name: s.itemName, plu: s.plu),
  };
  final Map<_Key, String?> _changes = {};
  int _layer = 1;
  bool _busy = false;

  Future<void> _edit(int keyNo) async {
    final key = (keyNo, _layer);
    final picked = await pickItem(
      context,
      title: 'Key $keyNo${_layer == 2 ? ' (shift)' : ''}',
      allowClear: _keys.containsKey(key),
    );
    if (picked == null) return;
    setState(() {
      if (picked.id.isEmpty) {
        _keys.remove(key);
        _changes[key] = null;
      } else {
        _keys[key] = (itemId: picked.id, name: picked.name, plu: picked.plu);
        _changes[key] = picked.id;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(scaleServiceProvider).saveShortcuts(widget.scaleId, _changes);
      ref.invalidate(scaleProvider(widget.scaleId));
      if (!mounted) return;
      AppToast.success(context, 'Shortcut keys saved and queued for the scale');
      context.pop();
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmLeave() async =>
      _changes.isEmpty ||
      await confirm(context,
          title: 'Discard changes?', message: 'Your key changes have not been saved.', confirmLabel: 'Discard', danger: true);

  @override
  Widget build(BuildContext context) {
    final assigned = _keys.keys.where((k) => k.$2 == _layer).length;
    return PopScope(
      canPop: _changes.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmLeave() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Shortcut keys')),
        bottomNavigationBar: BottomActionBar(
          child: PrimaryButton(
            label: _changes.isEmpty ? 'No changes' : 'Save ${_changes.length} ${_changes.length == 1 ? 'change' : 'changes'}',
            busy: _busy,
            onPressed: _changes.isEmpty ? null : _save,
          ),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 1, label: Text('Keys')),
                  ButtonSegment(value: 2, label: Text('Shift + key')),
                ],
                selected: {_layer},
                onSelectionChanged: (s) => setState(() => _layer = s.first),
              ),
              const SizedBox(height: 10),
              Text(
                '$assigned of ${AppConstants.shortcutKeys} keys assigned. Tap a key to choose its item.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 110,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.05,
              ),
              itemCount: AppConstants.shortcutKeys,
              itemBuilder: (_, i) {
                final keyNo = i + 1;
                final a = _keys[(keyNo, _layer)];
                final changed = _changes.containsKey((keyNo, _layer));
                return _KeyTile(keyNo: keyNo, assigned: a, changed: changed, onTap: () => _edit(keyNo));
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _KeyTile extends StatelessWidget {
  const _KeyTile({required this.keyNo, required this.assigned, required this.changed, required this.onTap});
  final int keyNo;
  final _Assigned? assigned;
  final bool changed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final filled = assigned != null;
    return Material(
      color: filled ? context.cs.primaryContainer : context.cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: changed ? context.status.warning : (filled ? context.cs.primary.withValues(alpha: 0.25) : context.cs.outlineVariant),
          width: changed ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '$keyNo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: filled ? context.cs.onPrimaryContainer : context.cs.outline,
              ),
            ),
            const Spacer(),
            Text(
              filled ? assigned!.name : 'Empty',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.2,
                fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
                color: filled ? context.cs.onSurface : context.cs.outline,
              ),
            ),
            if (filled)
              Text('PLU ${assigned!.plu}', style: TextStyle(fontSize: 11, color: context.cs.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
