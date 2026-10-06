import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../models/branch.dart';
import '../providers/branch_provider.dart';

/// The current branch name with a chevron; tapping it lets the user switch
/// branch. Every screen shows data for the chosen branch.
class BranchSwitcher extends ConsumerWidget {
  const BranchSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(currentBranchProvider);
    final branches = ref.watch(branchesProvider).value ?? const <Branch>[];
    final canSwitch = branches.length > 1;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: canSwitch ? () => showBranchPicker(context, ref) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              branch?.name ?? 'No branch',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
          if (canSwitch) const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.primary),
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Choose branch', style: Theme.of(ctx).textTheme.titleLarge),
          ),
          for (final b in branches)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: b.id == current?.id ? AppColors.primary : AppColors.primarySoft,
                foregroundColor: b.id == current?.id ? Colors.white : AppColors.primary,
                child: const Icon(Icons.storefront_rounded, size: 20),
              ),
              title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                b.scaleCount == 0
                    ? 'No scales'
                    : '${b.onlineScaleCount} of ${b.scaleCount} ${b.scaleCount == 1 ? 'scale' : 'scales'} online',
              ),
              trailing: b.id == current?.id ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
              onTap: () => Navigator.pop(ctx, b),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (picked != null) ref.read(selectedBranchIdProvider.notifier).select(picked.id);
}

/// The two-line app bar title used on the main tabs: screen name above the
/// branch switcher.
class BranchTitle extends StatelessWidget {
  const BranchTitle(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [Text(title), const BranchSwitcher()],
      );
}
