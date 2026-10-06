import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
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
    if (next.isAfter(dateOnly(DateTime.now()))) return;
    setState(() => _date = next);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final branches = ref.watch(branchesProvider);
    final branch = ref.watch(currentBranchProvider);

    if (branches.hasValue && branch == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.storefront_outlined,
          title: 'No branch yet',
          message: 'Your dealer has not set up a branch for your account. Contact them to get started.',
        ),
      );
    }

    final summary = branch == null ? null : ref.watch(daySummaryProvider(_date));
    final week = branch == null ? null : ref.watch(dailySalesProvider(_week));
    final bills = branch == null ? null : ref.watch(dayBillsProvider(_date));
    final isToday = _date == dateOnly(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _Header(name: user?.name ?? '', shop: user?.customerName),
              const SizedBox(height: 16),
              _DateBar(
                label: friendlyDay(_date),
                onPrev: () => _shiftDay(-1),
                onNext: isToday ? null : () => _shiftDay(1),
                onPick: _pickDate,
              ),
              const SizedBox(height: 12),
              _SalesHero(summary: summary?.value, loading: summary?.isLoading ?? true, error: summary?.error, onTap: () => context.push('/bills?date=${isoDay(_date)}')),
              const SizedBox(height: 12),
              if (branch != null) _ScalesStatus(branch: branch),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Last 7 days',
                trailing: TextButton(onPressed: () => context.go('/reports'), child: const Text('Reports')),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                child: SizedBox(
                  height: 150,
                  child: switch (week) {
                    AsyncData(:final value) => SalesBarChart(
                        days: value,
                        selected: _date,
                        onTap: (d) => setState(() => _date = dateOnly(d.date)),
                      ),
                    AsyncError() => const Center(child: Text('Could not load', style: TextStyle(color: AppColors.textSecondary))),
                    _ => const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                  },
                ),
              ),
              const SectionLabel('Quick actions'),
              _QuickActions(canManage: user?.canManage ?? false),
              const SectionLabel('Bills'),
              _RecentBills(bills: bills, date: _date),
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
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            shop ?? _greeting,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          const BranchSwitcherLarge(),
        ]),
      ),
      InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.push('/profile'),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primarySoft,
          foregroundColor: AppColors.primaryDark,
          child: Text(initials(name), style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }
}

/// The branch name as the page heading, tappable to switch.
class BranchSwitcherLarge extends ConsumerWidget {
  const BranchSwitcherLarge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branch = ref.watch(currentBranchProvider);
    final many = (ref.watch(branchesProvider).value?.length ?? 0) > 1;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: many ? () => showBranchPicker(context, ref) : null,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
          child: Text(
            branch?.name ?? ' ',
            style: Theme.of(context).textTheme.headlineSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (many) const Icon(Icons.expand_more_rounded, color: AppColors.textSecondary),
      ]),
    );
  }
}

class _DateBar extends StatelessWidget {
  const _DateBar({required this.label, required this.onPrev, required this.onNext, required this.onPick});
  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 48,
        child: Row(children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left_rounded), tooltip: 'Previous day'),
          Expanded(
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded), tooltip: 'Next day'),
        ]),
      ),
    );
  }
}

class _SalesHero extends StatelessWidget {
  const _SalesHero({required this.summary, required this.loading, required this.error, required this.onTap});
  final DaySales? summary;
  final bool loading;
  final Object? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Total sales', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
              const Spacer(),
              Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white.withValues(alpha: 0.8)),
            ]),
            const SizedBox(height: 6),
            SizedBox(
              height: 42,
              child: Align(
                alignment: Alignment.centerLeft,
                child: error != null
                    ? Text('Could not load', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 16))
                    : loading && s == null
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : FittedBox(
                            child: Text(
                              money(s?.total),
                              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.8),
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 14),
            Row(children: [
              _HeroStat(label: 'Bills', value: '${s?.bills ?? 0}'),
              _HeroStat(label: 'Discount', value: moneyCompact(s?.discount)),
              _HeroStat(label: 'GST', value: moneyCompact(s?.tax)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12.5)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
      );
}

class _ScalesStatus extends StatelessWidget {
  const _ScalesStatus({required this.branch});
  final Branch branch;

  @override
  Widget build(BuildContext context) {
    final total = branch.scaleCount;
    final online = branch.onlineScaleCount;
    final allOnline = total > 0 && online == total;
    final color = total == 0 ? AppColors.textSecondary : (allOnline ? AppColors.success : AppColors.warning);
    final soft = total == 0 ? AppColors.divider : (allOnline ? AppColors.successSoft : AppColors.warningSoft);

    return Card(
      child: ListTile(
        onTap: () => context.go('/scales'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.scale_rounded, color: color, size: 22),
        ),
        title: Text(
          total == 0 ? 'No scales in this branch' : '$online of $total ${total == 1 ? 'scale' : 'scales'} online',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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
      if (canManage) (Icons.sell_outlined, 'Update prices', '/prices'),
      (Icons.inventory_outlined, 'Update stock', '/stock'),
      (Icons.local_shipping_outlined, 'Purchase', '/purchase/new'),
      if (canManage) (Icons.add_box_outlined, 'Add item', '/item'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: [
        for (final (icon, label, path) in actions)
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push(path),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  Icon(icon, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentBills extends StatelessWidget {
  const _RecentBills({required this.bills, required this.date});
  final AsyncValue<List<Bill>>? bills;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    if (bills?.hasError ?? false) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Could not load bills. Pull down to retry.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    final list = bills?.value;
    if (list == null) {
      return const Card(child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2.4))));
    }
    if (list.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(children: [
            Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 28),
            SizedBox(height: 8),
            Text('No bills on this day', style: TextStyle(color: AppColors.textSecondary)),
          ]),
        ),
      );
    }
    final shown = list.take(5).toList();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (final (i, b) in shown.indexed) ...[
          if (i > 0) const Divider(indent: 72),
          BillTile(b),
        ],
        if (list.length > shown.length) ...[
          const Divider(),
          TextButton(
            onPressed: () => context.push('/bills?date=${isoDay(date)}'),
            child: Text('See all ${list.length} bills'),
          ),
        ],
      ]),
    );
  }
}
