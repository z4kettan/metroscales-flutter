import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
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
      appBar: AppBar(title: Text(scale.value?.title ?? 'Scale')),
      body: AsyncView(
        value: scale,
        onRetry: () => ref.invalidate(scaleProvider(scaleId)),
        builder: (s) => RefreshIndicator(
          onRefresh: () => ref.refresh(scaleProvider(scaleId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
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
                    subtitle: 'Items and prices to scale',
                    onTap: () => _run(context, ref, s, 'PUSH_ITEMS'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.download_rounded,
                    title: 'Read items',
                    subtitle: 'Import items from scale',
                    onTap: () => _run(context, ref, s, 'PULL_ITEMS'),
                  ),
                ),
              ]),
              if (canManage) ...[
                const SectionLabel('Settings'),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    _NavTile(
                      icon: Icons.tune_rounded,
                      title: 'Scale details and WiFi',
                      subtitle: s.wifiSsid == null ? 'Name, store name, WiFi' : 'WiFi: ${s.wifiSsid}',
                      onTap: () => context.push('/scale/${s.id}/settings'),
                    ),
                    const Divider(indent: 56),
                    _NavTile(
                      icon: Icons.receipt_outlined,
                      title: 'Print format',
                      subtitle: 'Label formats and footer lines',
                      onTap: () => context.push('/scale/${s.id}/print-format'),
                    ),
                    const Divider(indent: 56),
                    _NavTile(
                      icon: Icons.keyboard_outlined,
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
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: AppColors.danger.withValues(alpha: 0.35)),
                  ),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Clear all items on scale'),
                ),
              ],
            ],
          ),
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
    return Card(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: s.online ? AppColors.successSoft : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.scale_rounded, size: 28, color: s.online ? AppColors.success : AppColors.textMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(s.model ?? 'Weighing scale', style: const TextStyle(color: AppColors.textSecondary)),
              ]),
            ),
            StatusPill.online(s.online),
          ]),
        ),
        const Divider(),
        InfoRow('MAC address', formatMac(s.mac)),
        InfoRow('Last seen', since(s.lastSeenAt)),
        if (s.storeName != null) InfoRow('Store name', s.storeName!),
        if (s.lastIp != null) InfoRow('IP address', s.lastIp!),
        if (s.firmware != null) InfoRow('Firmware', s.firmware!),
        const SizedBox(height: 6),
      ]),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.infoSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4, color: Color(0xFF194185)))),
        ]),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            ]),
          ),
        ),
      );
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
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Nothing sent to this scale yet.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (final (i, c) in commands.take(8).indexed) ...[
          if (i > 0) const Divider(indent: 16),
          ListTile(
            dense: true,
            title: Text(c.label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            subtitle: Text(c.error ?? since(c.createdAt)),
            trailing: _statusPill(c),
          ),
        ],
      ]),
    );
  }

  Widget _statusPill(ScaleCommand c) => switch (c.status) {
        'DONE' => StatusPill(c.statusLabel, color: AppColors.success, background: AppColors.successSoft),
        'FAILED' => StatusPill(c.statusLabel, color: AppColors.danger, background: AppColors.dangerSoft),
        'CANCELLED' => StatusPill('Replaced', color: AppColors.textSecondary, background: AppColors.divider),
        _ => StatusPill(c.statusLabel, color: AppColors.warning, background: AppColors.warningSoft),
      };
}
