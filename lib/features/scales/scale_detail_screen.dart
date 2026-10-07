import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/format.dart';
import '../../models/scale.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/services.dart';
import '../../widgets/async_view.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_pill.dart';

class ScaleDetailScreen extends ConsumerWidget {
  const ScaleDetailScreen({super.key, required this.scaleId});
  final String scaleId;

  Future<void> _run(BuildContext context, WidgetRef ref, Scale scale, String type) async {
    if (type == 'CLEAR_PLU') {
      final ok = await confirm(
        context,
        title: 'Clear all items on the scale?',
        message: 'Every PLU stored on ${scale.title} will be erased. Your items in the app are not affected; '
            'send items again afterwards to reload them.',
        confirmLabel: 'Clear scale',
        danger: true,
      );
      if (!ok) return;
    }
    try {
      final online = await ref.read(scaleServiceProvider).runCommand(scale.id, type);
      ref.invalidate(scaleProvider(scaleId));
      ref.invalidate(scalesProvider);
      if (!context.mounted) return;
      AppToast.success(
        context,
        online ? 'Sent to ${scale.title}' : '${scale.title} is offline. It will sync when it reconnects.',
      );
    } catch (e) {
      if (context.mounted) AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(scaleProvider(scaleId));
    final canManage = ref.watch(currentUserProvider)?.canManage ?? false;

    return Scaffold(
      body: AsyncView(
        value: scale,
        onRetry: () => ref.invalidate(scaleProvider(scaleId)),
        builder: (s) => RefreshIndicator(
          onRefresh: () => ref.refresh(scaleProvider(scaleId).future),
          edgeOffset: 120,
          child: CustomScrollView(slivers: [
            SliverAppBar.medium(title: Text(s.title)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList.list(children: [
                _Header(s),
                if (!s.online) ...[
                  const SizedBox(height: 12),
                  const _Notice(
                    'This scale is offline. Changes you make are saved and sent automatically when it reconnects.',
                  ),
                ],
                const SectionLabel('Sync'),
                Row(children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.upload_rounded,
                      title: 'Send items',
                      subtitle: 'Items and prices to the scale',
                      onTap: () => _run(context, ref, s, 'PUSH_ITEMS'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.download_rounded,
                      title: 'Read items',
                      subtitle: 'Import items from the scale',
                      tonal: true,
                      onTap: () => _run(context, ref, s, 'PULL_ITEMS'),
                    ),
                  ),
                ]),
                if (canManage) ...[
                  const SectionLabel('Settings'),
                  Card(
                    child: Column(children: [
                      _NavTile(
                        icon: Icons.tune_rounded,
                        title: 'Scale details and WiFi',
                        subtitle: s.wifiSsid == null ? 'Name, store name, WiFi' : 'WiFi: ${s.wifiSsid}',
                        onTap: () => context.push('/scale/${s.id}/settings'),
                      ),
                      _NavTile(
                        icon: Icons.receipt_rounded,
                        title: 'Print format',
                        subtitle: 'Label formats and footer lines',
                        onTap: () => context.push('/scale/${s.id}/print-format'),
                      ),
                      _NavTile(
                        icon: Icons.keyboard_rounded,
                        title: 'Shortcut keys',
                        subtitle: 'Items on the scale keyboard',
                        onTap: () => context.push('/scale/${s.id}/shortcuts'),
                      ),
                    ]),
                  ),
                ],
                const SectionLabel('Recent activity'),
                _Activity(s.recentCommands),
                if (canManage) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _run(context, ref, s, 'CLEAR_PLU'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.cs.error,
                      side: BorderSide(color: context.cs.error.withValues(alpha: 0.5)),
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded),
                    label: const Text('Clear all items on scale'),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.s);
  final Scale s;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final st = context.status;
    return Card(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: Row(children: [
            IconBox(
              Icons.scale_rounded,
              size: 60,
              background: s.online ? st.successContainer : cs.surfaceContainerHighest,
              foreground: s.online ? st.onSuccessContainer : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.model ?? 'Weighing scale', style: context.tt.titleMedium),
                const SizedBox(height: 6),
                StatusPill.online(s.online),
              ]),
            ),
          ]),
        ),
        InfoRow('MAC address', formatMac(s.mac), icon: Icons.fingerprint_rounded),
        InfoRow('Last seen', since(s.lastSeenAt), icon: Icons.schedule_rounded),
        if (s.storeName != null) InfoRow('Store name', s.storeName!, icon: Icons.storefront_rounded),
        if (s.lastIp != null) InfoRow('IP address', s.lastIp!, icon: Icons.lan_rounded),
        if (s.firmware != null) InfoRow('Firmware', s.firmware!, icon: Icons.memory_rounded),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.cloud_sync_rounded, color: cs.onSecondaryContainer),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(height: 1.45, color: cs.onSecondaryContainer, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.tonal = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final bg = tonal ? cs.secondaryContainer : cs.primary;
    final fg = tonal ? cs.onSecondaryContainer : cs.onPrimary;
    return Card(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: fg, size: 28),
            const SizedBox(height: 18),
            Text(title, style: context.tt.titleMedium?.copyWith(color: fg)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: IconBox(icon, size: 42),
        title: Text(title),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
      );
}

class _Activity extends StatelessWidget {
  const _Activity(this.commands);
  final List<ScaleCommand> commands;

  @override
  Widget build(BuildContext context) {
    if (commands.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Nothing sent to this scale yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.cs.onSurfaceVariant),
          ),
        ),
      );
    }
    return Card(
      child: Column(children: [
        for (final (i, c) in commands.take(8).indexed) ...[
          if (i > 0) const Divider(indent: 16, endIndent: 16),
          ListTile(
            title: Text(c.label),
            subtitle: Text(c.error ?? since(c.createdAt)),
            trailing: switch (c.status) {
              'DONE' => StatusPill(c.statusLabel, tone: Tone.success),
              'FAILED' => StatusPill(c.statusLabel, tone: Tone.danger),
              'CANCELLED' => const StatusPill('Replaced'),
              _ => StatusPill(c.statusLabel, tone: Tone.warning),
            },
          ),
        ],
      ]),
    );
  }
}
