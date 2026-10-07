import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/format.dart';
import '../../models/sales.dart';
import '../../providers/branch_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/async_view.dart';
import '../../widgets/tab_page.dart';
import '../../widgets/section_card.dart';
import 'csv_export.dart';
import 'sales_chart.dart';

enum _Preset { today, yesterday, week, month, custom }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _Preset _preset = _Preset.week;
  late DateRange _range = _rangeFor(_Preset.week);
  bool _byItem = false;

  static DateRange _rangeFor(_Preset p) {
    final today = dateOnly(DateTime.now());
    return switch (p) {
      _Preset.today => (from: today, to: today),
      _Preset.yesterday => (from: today.subtract(const Duration(days: 1)), to: today.subtract(const Duration(days: 1))),
      _Preset.week => (from: today.subtract(const Duration(days: 6)), to: today),
      _Preset.month => (from: DateTime(today.year, today.month), to: today),
      _Preset.custom => (from: today, to: today),
    };
  }

  Future<void> _select(_Preset p) async {
    if (p == _Preset.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: dateOnly(DateTime.now()),
        initialDateRange: DateTimeRange(start: _range.from, end: _range.to),
      );
      if (picked == null) return;
      setState(() {
        _preset = p;
        _range = (from: dateOnly(picked.start), to: dateOnly(picked.end));
      });
      return;
    }
    setState(() {
      _preset = p;
      _range = _rangeFor(p);
    });
  }

  String get _rangeLabel =>
      _range.from == _range.to ? day(_range.from) : '${dayShort(_range.from)} – ${day(_range.to)}';

  Future<void> _export() async {
    final branch = ref.read(currentBranchProvider)?.name ?? 'branch';
    final period = '${isoDay(_range.from)}_${isoDay(_range.to)}';
    try {
      if (_byItem) {
        final rows = await ref.read(itemSalesProvider(_range).future);
        await shareCsv(
          fileName: 'item-sales_${branch}_$period.csv',
          subject: 'Item sales, $branch, $_rangeLabel',
          rows: [
            ['PLU', 'Item', 'Unit', 'Quantity', 'Amount'],
            for (final r in rows) [r.plu, r.name, unitLabel(r.unit), r.quantity, r.amount.toStringAsFixed(2)],
          ],
        );
      } else {
        final rows = await ref.read(dailySalesProvider(_range).future);
        await shareCsv(
          fileName: 'daily-sales_${branch}_$period.csv',
          subject: 'Daily sales, $branch, $_rangeLabel',
          rows: [
            ['Date', 'Bills', 'Total', 'Discount', 'GST'],
            for (final r in rows)
              [isoDay(r.date), r.bills, r.total.toStringAsFixed(2), r.discount.toStringAsFixed(2), r.tax.toStringAsFixed(2)],
          ],
        );
      }
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daily = ref.watch(dailySalesProvider(_range));
    return TabPage(
      title: 'Reports',
      onRefresh: () {
        ref.invalidate(itemSalesProvider(_range));
        return ref.refresh(dailySalesProvider(_range).future);
      },
      actions: [
        IconButton(tooltip: 'Share as Excel (CSV)', icon: const Icon(Icons.ios_share_rounded), onPressed: _export),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final (p, label) in [
                  (_Preset.today, 'Today'),
                  (_Preset.yesterday, 'Yesterday'),
                  (_Preset.week, 'Last 7 days'),
                  (_Preset.month, 'This month'),
                  (_Preset.custom, 'Custom'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      avatar: p == _Preset.custom && _preset != p ? const Icon(Icons.date_range_rounded, size: 18) : null,
                      selected: _preset == p,
                      onSelected: (_) => _select(p),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPagePadding(
          sliver: SliverList.list(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
              child: Row(children: [
                Icon(Icons.event_rounded, size: 18, color: context.cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(_rangeLabel, style: context.tt.labelLarge?.copyWith(color: context.cs.onSurfaceVariant)),
              ]),
            ),
            AsyncView(
              value: daily,
              onRetry: () => ref.invalidate(dailySalesProvider(_range)),
              builder: (days) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _Totals(days),
                if (days.length > 1) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Sales by day',
                    icon: Icons.bar_chart_rounded,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                    child: SalesBarChart(
                      days: days,
                      height: 170,
                      onTap: (d) => context.push('/bills?date=${isoDay(d.date)}'),
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('By day'), icon: Icon(Icons.calendar_view_day_rounded)),
                ButtonSegment(value: true, label: Text('By item'), icon: Icon(Icons.inventory_2_rounded)),
              ],
              selected: {_byItem},
              onSelectionChanged: (s) => setState(() => _byItem = s.first),
            ),
            const SizedBox(height: 12),
            if (_byItem) _ItemTable(range: _range) else _DayTable(days: daily.value),
          ]),
        ),
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals(this.days);
  final List<DaySales> days;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final total = days.fold<double>(0, (s, d) => s + d.total);
    final bills = days.fold<int>(0, (s, d) => s + d.bills);
    final discount = days.fold<double>(0, (s, d) => s + d.discount);
    final tax = days.fold<double>(0, (s, d) => s + d.tax);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
        color: cs.primary,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total sales', style: context.tt.titleMedium?.copyWith(color: cs.onPrimary.withValues(alpha: 0.85))),
            const SizedBox(height: 6),
            FittedBox(child: Text(money(total), style: context.tt.displaySmall?.copyWith(color: cs.onPrimary, fontSize: 40))),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        _Metric(Icons.receipt_long_rounded, 'Bills', '$bills', cs.secondaryContainer, cs.onSecondaryContainer),
        const SizedBox(width: 10),
        _Metric(Icons.functions_rounded, 'Average bill', moneyCompact(bills == 0 ? 0 : (total / bills).roundToDouble()),
            cs.tertiaryContainer, cs.onTertiaryContainer),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _Metric(Icons.local_offer_rounded, 'Discount', money(discount), cs.surfaceContainerHigh, cs.onSurface),
        const SizedBox(width: 10),
        _Metric(Icons.account_balance_rounded, 'GST', money(tax), cs.surfaceContainerHigh, cs.onSurface),
      ]),
    ]);
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.label, this.value, this.bg, this.fg);
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
                FittedBox(child: Text(value, style: context.tt.titleMedium?.copyWith(color: fg))),
                Text(label, style: TextStyle(color: fg.withValues(alpha: 0.8), fontSize: 12.5, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
      );
}

class _DayTable extends StatelessWidget {
  const _DayTable({required this.days});
  final List<DaySales>? days;

  @override
  Widget build(BuildContext context) {
    final list = days?.reversed.toList();
    if (list == null) return const SizedBox.shrink();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (final (i, d) in list.indexed) ...[
          if (i > 0) const Divider(indent: 16),
          ListTile(
            onTap: d.bills == 0 ? null : () => context.push('/bills?date=${isoDay(d.date)}'),
            title: Text(friendlyDay(d.date), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(d.bills == 0 ? 'No bills' : '${d.bills} ${d.bills == 1 ? 'bill' : 'bills'}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(money(d.total), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: d.bills == 0 ? Colors.transparent : context.cs.outline),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _ItemTable extends ConsumerWidget {
  const _ItemTable({required this.range});
  final DateRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemSalesProvider(range));
    return AsyncView(
      value: items,
      onRetry: () => ref.invalidate(itemSalesProvider(range)),
      builder: (list) {
        if (list.isEmpty) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No items sold in this period', textAlign: TextAlign.center, style: TextStyle(color: context.cs.onSurfaceVariant)),
            ),
          );
        }
        final max = list.first.amount;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (final (i, r) in list.indexed) ...[
              if (i > 0) const Divider(indent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(children: [
                  Row(children: [
                    SizedBox(
                      width: 26,
                      child: Text('${i + 1}', style: TextStyle(color: context.cs.outline, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${qtyWithUnit(r.quantity, r.unit)} · PLU ${r.plu}',
                            style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 12.5)),
                      ]),
                    ),
                    Text(money(r.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: max == 0 ? 0 : r.amount / max,
                        minHeight: 5,
                        color: context.cs.primary,
                        backgroundColor: context.cs.outlineVariant,
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ]),
        );
      },
    );
  }
}
