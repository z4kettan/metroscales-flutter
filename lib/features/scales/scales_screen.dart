import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/scale.dart';
import '../../providers/branch_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/async_view.dart';
import '../../widgets/branch_switcher.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_pill.dart';

class ScalesScreen extends ConsumerWidget {
  const ScalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scales = ref.watch(scalesProvider);
    return Scaffold(
      appBar: AppBar(toolbarHeight: 64, title: const BranchTitle('Scales')),
      body: AsyncView(
        value: scales,
        onRetry: () => ref.invalidate(scalesProvider),
        builder: (list) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(branchesProvider);
            return ref.refresh(scalesProvider.future);
          },
          child: list.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 60),
                  EmptyState(
                    icon: Icons.scale_outlined,
                    title: 'No scales in this branch',
                    message:
                        'Your dealer registers each scale by its MAC address. Ask them to add your scale to this branch.',
                  ),
                ])
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _Summary(list),
                    const SizedBox(height: 12),
                    for (final s in list) ...[_ScaleCard(s), const SizedBox(height: 10)],
                  ],
                ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.scales);
  final List<Scale> scales;

  @override
  Widget build(BuildContext context) {
    final online = scales.where((s) => s.online).length;
    final waiting = scales.fold<int>(0, (n, s) => n + s.pendingCommands);
    return Row(children: [
      _Stat(label: 'Online', value: '$online / ${scales.length}', color: online > 0 ? AppColors.success : AppColors.textSecondary),
      const SizedBox(width: 10),
      _Stat(label: 'Waiting to sync', value: '$waiting', color: waiting > 0 ? AppColors.warning : AppColors.textSecondary),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
            ]),
          ),
        ),
      );
}

class _ScaleCard extends StatelessWidget {
  const _ScaleCard(this.scale);
  final Scale scale;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/scale/${scale.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scale.online ? AppColors.successSoft : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scale.online ? Colors.transparent : AppColors.border),
                ),
                child: Icon(Icons.scale_rounded, color: scale.online ? AppColors.success : AppColors.textMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(scale.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(formatMac(scale.mac),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFeatures: [FontFeature.tabularFigures()])),
                ]),
              ),
              StatusPill.online(scale.online),
            ]),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text('Last seen ${since(scale.lastSeenAt)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const Spacer(),
              if (scale.pendingCommands > 0)
                StatusPill(
                  '${scale.pendingCommands} waiting',
                  color: AppColors.warning,
                  background: AppColors.warningSoft,
                )
              else
                const Text('Up to date', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ]),
          ]),
        ),
      ),
    );
  }
}
