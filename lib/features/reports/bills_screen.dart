import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../providers/data_providers.dart';
import '../../widgets/async_view.dart';
import '../../widgets/empty_state.dart';
import 'bill_sheet.dart';

/// Every bill from one day in the current branch.
class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = dateOnly(date);
    final bills = ref.watch(dayBillsProvider(key));
    return Scaffold(
      appBar: AppBar(title: Text('Bills · ${friendlyDay(key)}')),
      body: AsyncView(
        value: bills,
        onRetry: () => ref.invalidate(dayBillsProvider(key)),
        builder: (list) {
          if (list.isEmpty) {
            return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No bills on this day');
          }
          final total = list.fold<double>(0, (s, b) => s + b.total);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(dayBillsProvider(key).future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Total', style: TextStyle(color: AppColors.textSecondary)),
                          Text(money(total), style: Theme.of(context).textTheme.headlineSmall),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        const Text('Bills', style: TextStyle(color: AppColors.textSecondary)),
                        Text('${list.length}', style: Theme.of(context).textTheme.headlineSmall),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    for (final (i, b) in list.indexed) ...[
                      if (i > 0) const Divider(indent: 72),
                      BillTile(b),
                    ],
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
