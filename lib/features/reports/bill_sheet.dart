import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/sales.dart';

/// One bill laid out like a printed receipt.
Future<void> showBillSheet(BuildContext context, Bill bill) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Row(children: [
            Expanded(child: Text('Bill #${bill.billNo}', style: Theme.of(ctx).textTheme.titleLarge)),
            Text(moneyCompact(bill.total), style: Theme.of(ctx).textTheme.titleLarge),
          ]),
          const SizedBox(height: 4),
          Text(
            [day(bill.billedAt), time(bill.billedAt), ?bill.scaleName].join('  ·  '),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              for (final (i, l) in bill.lines.indexed) ...[
                if (i > 0) const Divider(indent: 14, endIndent: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          '${qtyWithUnit(l.quantity, l.unit)} × ${money(l.price)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ]),
                    ),
                    Text(money(l.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 16),
          _TotalRow('Subtotal', money(bill.subtotal)),
          if (bill.tax > 0) _TotalRow('GST', money(bill.tax)),
          if (bill.discount > 0) _TotalRow('Discount', '− ${money(bill.discount)}'),
          const Divider(height: 24),
          _TotalRow('Total', money(bill.total), bold: true),
        ],
      ),
    ),
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      fontSize: bold ? 17 : 14,
      color: bold ? AppColors.text : AppColors.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Expanded(child: Text(label, style: style)), Text(value, style: style)]),
    );
  }
}

/// A bill in a list: number, time and scale on the left, total on the right.
class BillTile extends StatelessWidget {
  const BillTile(this.bill, {super.key});
  final Bill bill;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: () => showBillSheet(context, bill),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: const Icon(Icons.receipt_long_rounded, size: 20, color: AppColors.textSecondary),
        ),
        title: Text('Bill #${bill.billNo}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [time(bill.billedAt), '${bill.lines.length} ${bill.lines.length == 1 ? 'item' : 'items'}', ?bill.scaleName].join(' · '),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(money(bill.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            if (bill.discount > 0)
              Text('− ${money(bill.discount)}', style: const TextStyle(fontSize: 12, color: AppColors.warning)),
          ],
        ),
      );
}
