import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../models/branch.dart';
import '../providers/branch_provider.dart';

/// A tonal chip with the current branch; tapping it lets the user switch.
/// Every screen shows data for the chosen branch.
class BranchChip extends ConsumerWidget {
  const BranchChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(currentBranchProvider);
    final many = (ref.watch(branchesProvider).value?.length ?? 0) > 1;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: FilledButton.tonal(
        onPressed: many ? () => showBranchPicker(context, ref) : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.only(left: 12, right: 8),
          disabledBackgroundColor: context.cs.secondaryContainer,
          disabledForegroundColor: context.cs.onSecondaryContainer,
          textStyle: context.tt.labelLarge,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.storefront_rounded, size: 18),
          const SizedBox(width: 6),
          Flexible(child: Text(branch?.name ?? 'No branch', overflow: TextOverflow.ellipsis)),
          if (many) const Icon(Icons.arrow_drop_down_rounded, size: 22) else const SizedBox(width: 4),
        ]),
      ),
    );
  }
}

Future<void> showBranchPicker(BuildContext context, WidgetRef ref) async {
  final branches = ref.read(branchesProvider).value ?? const <Branch>[];
  final current = ref.read(currentBranchProvider);
  final picked = await showModalBottomSheet<Branch>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text('Choose branch', style: ctx.tt.headlineSmall),
          ),
          for (final b in branches)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: ListTile(
                selected: b.id == current?.id,
                selectedTileColor: ctx.cs.secondaryContainer,
                selectedColor: ctx.cs.onSecondaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                leading: const Icon(Icons.storefront_rounded),
                title: Text(b.name),
                subtitle: Text(
                  b.scaleCount == 0
                      ? 'No scales'
                      : '${b.onlineScaleCount} of ${b.scaleCount} ${b.scaleCount == 1 ? 'scale' : 'scales'} online',
                ),
                trailing: b.id == current?.id ? const Icon(Icons.check_circle_rounded) : null,
                onTap: () => Navigator.pop(ctx, b),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
  if (picked != null) ref.read(selectedBranchIdProvider.notifier).select(picked.id);
}
