import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/sales.dart';

/// One bill laid out like a receipt.
Future<void> showBillSheet(BuildContext context, Bill bill) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (ctx, scroll) {
        final cs = ctx.cs;
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text('Bill #${bill.billNo}', style: ctx.tt.headlineSmall),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _MetaChip(Icons.event_rounded, day(bill.billedAt)),
              _MetaChip(Icons.schedule_rounded, time(bill.billedAt)),
              if (bill.scaleName != null) _MetaChip(Icons.scale_rounded, bill.scaleName!),
            ]),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                for (final (i, l) in bill.lines.indexed) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            '${qtyWithUnit(l.quantity, l.unit)} × ${money(l.price)}',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                          ),
                        ]),
                      ),
                      Text(money(l.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            _TotalRow('Subtotal', money(bill.subtotal)),
            if (bill.tax > 0) _TotalRow('GST', money(bill.tax)),
            if (bill.discount > 0) _TotalRow('Discount', '− ${money(bill.discount)}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Expanded(child: Text('Total', style: ctx.tt.titleMedium?.copyWith(color: cs.onPrimaryContainer))),
                Text(money(bill.total), style: ctx.tt.titleLarge?.copyWith(color: cs.onPrimaryContainer)),
              ]),
            ),
          ],
        );
      },
    ),
  );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: context.cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: context.cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: context.cs.onSurfaceVariant, fontSize: 13)),
        ]),
      );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(color: context.cs.onSurfaceVariant))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );
}

/// A bill in a list: number, time and scale on the left, total on the right.
class BillTile extends StatelessWidget {
  const BillTile(this.bill, {super.key});
  final Bill bill;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return ListTile(
      onTap: () => showBillSheet(context, bill),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: cs.secondaryContainer,
        foregroundColor: cs.onSecondaryContainer,
        child: const Icon(Icons.receipt_long_rounded, size: 20),
      ),
      title: Text('Bill #${bill.billNo}'),
      subtitle: Text(
        [time(bill.billedAt), '${bill.lines.length} ${bill.lines.length == 1 ? 'item' : 'items'}', ?bill.scaleName]
            .join(' · '),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(money(bill.total), style: context.tt.titleSmall?.copyWith(fontSize: 15)),
          if (bill.discount > 0)
            Text('− ${money(bill.discount)}', style: TextStyle(fontSize: 12, color: context.status.warning, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
