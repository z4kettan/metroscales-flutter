import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/scale.dart';
import '../../providers/branch_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/async_view.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/tab_page.dart';

class ScalesScreen extends ConsumerWidget {
  const ScalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scales = ref.watch(scalesProvider);
    return TabPage(
      title: 'Scales',
      onRefresh: () {
        ref.invalidate(branchesProvider);
        return ref.refresh(scalesProvider.future);
      },
      slivers: [
        SliverAsyncView(
          value: scales,
          onRetry: () => ref.invalidate(scalesProvider),
          builder: (list) => list.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.scale_rounded,
                    title: 'No scales in this branch',
                    message:
                        'Your dealer registers each scale by its MAC address. Ask them to add your scale to this branch.',
                  ),
                )
              : SliverPagePadding(
                  sliver: SliverList.list(children: [
                    _Summary(list),
                    const SizedBox(height: 16),
                    for (final s in list) ...[_ScaleCard(s), const SizedBox(height: 12)],
                  ]),
                ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.scales);
  final List<Scale> scales;

  @override
  Widget build(BuildContext context) {
    final s = context.status;
    final cs = context.cs;
    final online = scales.where((x) => x.online).length;
    final waiting = scales.fold<int>(0, (n, x) => n + x.pendingCommands);
    return Row(children: [
      _Stat(
        icon: Icons.wifi_rounded,
        label: 'Online',
        value: '$online of ${scales.length}',
        bg: online > 0 ? s.successContainer : cs.surfaceContainerHigh,
        fg: online > 0 ? s.onSuccessContainer : cs.onSurfaceVariant,
      ),
      const SizedBox(width: 10),
      _Stat(
        icon: Icons.sync_rounded,
        label: 'Waiting to sync',
        value: '$waiting',
        bg: waiting > 0 ? s.warningContainer : cs.surfaceContainerHigh,
        fg: waiting > 0 ? s.onWarningContainer : cs.onSurfaceVariant,
      ),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value, required this.bg, required this.fg});
  final IconData icon;
  final String label;
  final String value;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: context.tt.titleLarge?.copyWith(color: fg)),
                Text(label, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
      );
}

class _ScaleCard extends StatelessWidget {
  const _ScaleCard(this.scale);
  final Scale scale;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final st = context.status;
    return Card(
      child: InkWell(
        onTap: () => context.push('/scale/${scale.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scale.online ? st.successContainer : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.scale_rounded, size: 30, color: scale.online ? st.onSuccessContainer : cs.onSurfaceVariant),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(scale.title, style: context.tt.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    formatMac(scale.mac),
                    style: TextStyle(color: cs.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ]),
              ),
              StatusPill.online(scale.online),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(Icons.schedule_rounded, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text('Last seen ${since(scale.lastSeenAt)}', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                if (scale.pendingCommands > 0)
                  StatusPill('${scale.pendingCommands} waiting', tone: Tone.warning)
                else
                  Text(
                    scale.lastSeenAt == null ? 'Not connected yet' : 'Up to date',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
