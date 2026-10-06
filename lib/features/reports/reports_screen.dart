import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/format.dart';
import '../../models/sales.dart';
import '../../providers/branch_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/async_view.dart';
import '../../widgets/branch_switcher.dart';
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: const BranchTitle('Reports'),
        actions: [
          IconButton(tooltip: 'Share as Excel (CSV)', icon: const Icon(Icons.ios_share_rounded), onPressed: _export),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(itemSalesProvider(_range));
          return ref.refresh(dailySalesProvider(_range).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
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
                        avatar: p == _Preset.custom ? const Icon(Icons.date_range_rounded, size: 16) : null,
                        selected: _preset == p,
                        onSelected: (_) => _select(p),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _preset == p ? AppColors.primaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
              child: Text(_rangeLabel, style: Theme.of(context).textTheme.bodySmall),
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
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                    child: SalesBarChart(
                      days: days,
                      height: 160,
                      onTap: (d) => context.push('/bills?date=${isoDay(d.date)}'),
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('By day'), icon: Icon(Icons.calendar_view_day_rounded)),
                ButtonSegment(value: true, label: Text('By item'), icon: Icon(Icons.inventory_2_outlined)),
              ],
              selected: {_byItem},
              onSelectionChanged: (s) => setState(() => _byItem = s.first),
            ),
            const SizedBox(height: 12),
            if (_byItem) _ItemTable(range: _range) else _DayTable(days: daily.value),
          ],
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals(this.days);
  final List<DaySales> days;

  @override
  Widget build(BuildContext context) {
    final total = days.fold<double>(0, (s, d) => s + d.total);
    final bills = days.fold<int>(0, (s, d) => s + d.bills);
    final discount = days.fold<double>(0, (s, d) => s + d.discount);
    final tax = days.fold<double>(0, (s, d) => s + d.tax);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total sales', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(money(total),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 30, letterSpacing: -0.6)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _Metric('Bills', '$bills'),
            _Metric('Average bill', moneyCompact(bills == 0 ? 0 : (total / bills).roundToDouble())),
          ]),
          const SizedBox(height: 12),
          Row(children: [_Metric('Discount', money(discount)), _Metric('GST', money(tax))]),
        ]),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ]),
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
              Icon(Icons.chevron_right_rounded, color: d.bills == 0 ? Colors.transparent : AppColors.textMuted),
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
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No items sold in this period', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
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
                      child: Text('${i + 1}', style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${qtyWithUnit(r.quantity, r.unit)} · PLU ${r.plu}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
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
                        color: AppColors.primary,
                        backgroundColor: AppColors.divider,
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
