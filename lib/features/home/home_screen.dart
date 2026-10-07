import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/branch.dart';
import '../../models/sales.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/branch_switcher.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';
import '../reports/bill_sheet.dart';
import '../reports/sales_chart.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _date = dateOnly(DateTime.now());

  DateRange get _week => (from: _date.subtract(const Duration(days: 6)), to: _date);
  bool get _isToday => _date == dateOnly(DateTime.now());

  Future<void> _refresh() async {
    ref.invalidate(branchesProvider);
    ref.invalidate(daySummaryProvider(_date));
    ref.invalidate(dayBillsProvider(_date));
    ref.invalidate(dailySalesProvider(_week));
    await ref.read(daySummaryProvider(_date).future);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: dateOnly(DateTime.now()),
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  void _shiftDay(int days) {
    final next = _date.add(Duration(days: days));
    if (!next.isAfter(dateOnly(DateTime.now()))) setState(() => _date = next);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final branches = ref.watch(branchesProvider);
    final branch = ref.watch(currentBranchProvider);

    if (branches.hasValue && branch == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.storefront_rounded,
          title: 'No branch yet',
          message: 'Your dealer has not set up a branch for your account. Contact them to get started.',
        ),
      );
    }

    final summary = branch == null ? null : ref.watch(daySummaryProvider(_date));
    final week = branch == null ? null : ref.watch(dailySalesProvider(_week));
    final bills = branch == null ? null : ref.watch(dayBillsProvider(_date));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Header(name: user?.name ?? '', shop: user?.customerName),
              const SizedBox(height: 20),
              _DateBar(
                label: friendlyDay(_date),
                onPrev: () => _shiftDay(-1),
                onNext: _isToday ? null : () => _shiftDay(1),
                onPick: _pickDate,
              ),
              const SizedBox(height: 16),
              _SalesHero(
                summary: summary?.value,
                loading: summary?.isLoading ?? true,
                error: summary?.error,
                onTap: () => context.push('/bills?date=${isoDay(_date)}'),
              ),
              const SizedBox(height: 12),
              _StatRow(summary: summary?.value),
              const SizedBox(height: 12),
              if (branch != null) _ScalesStatus(branch: branch),
              const SectionLabel('Quick actions'),
              _QuickActions(canManage: user?.canManage ?? false),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Last 7 days',
                icon: Icons.bar_chart_rounded,
                trailing: TextButton(onPressed: () => context.go('/reports'), child: const Text('Reports')),
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
                child: SizedBox(
                  height: 180,
                  child: switch (week) {
                    AsyncData(:final value) => SalesBarChart(
                        days: value,
                        selected: _date,
                        height: 180,
                        onTap: (d) => setState(() => _date = dateOnly(d.date)),
                      ),
                    AsyncError() => Center(
                        child: Text('Could not load', style: TextStyle(color: context.cs.onSurfaceVariant)),
                      ),
                    _ => const Center(child: CircularProgressIndicator()),
                  },
                ),
              ),
              SectionLabel(
                'Bills',
                trailing: TextButton(
                  onPressed: () => context.push('/bills?date=${isoDay(_date)}'),
                  child: const Text('See all'),
                ),
              ),
              _RecentBills(bills: bills),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, this.shop});
  final String name;
  final String? shop;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$_greeting, $name', style: context.tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(
              shop ?? 'Metro Scales',
              style: context.tt.headlineMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        ),
        const SizedBox(width: 12),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.push('/profile'),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: cs.tertiaryContainer,
            foregroundColor: cs.onTertiaryContainer,
            child: Text(initials(name), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      const BranchChip(),
    ]);
  }
}

class _DateBar extends StatelessWidget {
  const _DateBar({required this.label, required this.onPrev, required this.onNext, required this.onPick});
  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => Row(children: [
        IconButton.filledTonal(onPressed: onPrev, icon: const Icon(Icons.chevron_left_rounded), tooltip: 'Previous day'),
        const SizedBox(width: 4),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPick,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            icon: const Icon(Icons.calendar_month_rounded, size: 20),
            label: Text(label),
          ),
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded), tooltip: 'Next day'),
      ]);
}

class _SalesHero extends StatelessWidget {
  const _SalesHero({required this.summary, required this.loading, required this.error, required this.onTap});
  final DaySales? summary;
  final bool loading;
  final Object? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Card(
      color: cs.primary,
      child: InkWell(
        onTap: onTap,
        child: Stack(children: [
          Positioned(
            right: -30,
            bottom: -40,
            child: Icon(Icons.scale_rounded, size: 170, color: cs.onPrimary.withValues(alpha: 0.08)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Total sales', style: context.tt.titleMedium?.copyWith(color: cs.onPrimary.withValues(alpha: 0.85))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: cs.onPrimary.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(Icons.arrow_outward_rounded, size: 18, color: cs.onPrimary),
                ),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: error != null
                      ? Text('Could not load', style: TextStyle(color: cs.onPrimary, fontSize: 18))
                      : loading && summary == null
                          ? SizedBox(width: 26, height: 26, child: CircularProgressIndicator(color: cs.onPrimary))
                          : FittedBox(
                              child: Text(
                                money(summary?.total),
                                style: context.tt.displaySmall?.copyWith(color: cs.onPrimary, fontSize: 42),
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                summary == null
                    ? ' '
                    : summary!.bills == 0
                        ? 'No bills yet'
                        : 'Average bill ${moneyCompact((summary!.total / summary!.bills).roundToDouble())}',
                style: TextStyle(color: cs.onPrimary.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.summary});
  final DaySales? summary;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final s = summary;
    return Row(children: [
      _StatTile(
        icon: Icons.receipt_long_rounded,
        label: 'Bills',
        value: '${s?.bills ?? 0}',
        bg: cs.secondaryContainer,
        fg: cs.onSecondaryContainer,
      ),
      const SizedBox(width: 10),
      _StatTile(
        icon: Icons.local_offer_rounded,
        label: 'Discount',
        value: moneyCompact(s?.discount),
        bg: cs.tertiaryContainer,
        fg: cs.onTertiaryContainer,
      ),
      const SizedBox(width: 10),
      _StatTile(
        icon: Icons.account_balance_rounded,
        label: 'GST',
        value: moneyCompact(s?.tax),
        bg: cs.surfaceContainerHigh,
        fg: cs.onSurface,
      ),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value, required this.bg, required this.fg});
  final IconData icon;
  final String label;
  final String value;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(height: 14),
            FittedBox(child: Text(value, style: context.tt.titleLarge?.copyWith(color: fg))),
            Text(label, style: TextStyle(color: fg.withValues(alpha: 0.8), fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
      );
}

class _ScalesStatus extends StatelessWidget {
  const _ScalesStatus({required this.branch});
  final Branch branch;

  @override
  Widget build(BuildContext context) {
    final s = context.status;
    final cs = context.cs;
    final total = branch.scaleCount;
    final online = branch.onlineScaleCount;
    final allOnline = total > 0 && online == total;
    final (bg, fg) = total == 0
        ? (cs.surfaceContainerHighest, cs.onSurfaceVariant)
        : allOnline
            ? (s.successContainer, s.onSuccessContainer)
            : (s.warningContainer, s.onWarningContainer);

    return Card(
      child: ListTile(
        onTap: () => context.go('/scales'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: IconBox(Icons.scale_rounded, background: bg, foreground: fg, size: 48),
        title: Text(total == 0 ? 'No scales in this branch' : '$online of $total ${total == 1 ? 'scale' : 'scales'} online'),
        subtitle: Text(
          total == 0
              ? 'Ask your dealer to register your scale'
              : allOnline
                  ? 'Bills are syncing to the cloud'
                  : 'Offline scales sync when they reconnect',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.canManage});
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final actions = [
      if (canManage) (Icons.sell_rounded, 'Prices', '/prices'),
      (Icons.inventory_rounded, 'Stock', '/stock'),
      (Icons.local_shipping_rounded, 'Purchase', '/purchase/new'),
      if (canManage) (Icons.add_rounded, 'New item', '/item'),
    ];
    final cs = context.cs;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final (icon, label, path) in actions)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.push(path),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(22)),
                    child: Icon(icon, color: cs.onPrimaryContainer, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(label, style: context.tt.labelLarge, textAlign: TextAlign.center),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentBills extends StatelessWidget {
  const _RecentBills({required this.bills});
  final AsyncValue<List<Bill>>? bills;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    if (bills?.hasError ?? false) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load bills. Pull down to retry.', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      );
    }
    final list = bills?.value;
    if (list == null) {
      return const Card(child: SizedBox(height: 96, child: Center(child: CircularProgressIndicator())));
    }
    if (list.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(children: [
            Icon(Icons.receipt_long_rounded, color: cs.outline, size: 32),
            const SizedBox(height: 8),
            Text('No bills on this day', style: TextStyle(color: cs.onSurfaceVariant)),
          ]),
        ),
      );
    }
    return Card(
      child: Column(children: [
        for (final (i, b) in list.take(5).indexed) ...[
          if (i > 0) const Divider(indent: 72, endIndent: 16),
          BillTile(b),
        ],
      ]),
    );
  }
}
