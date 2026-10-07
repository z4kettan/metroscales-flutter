import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/format.dart';
import '../../models/sales.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/services.dart';
import '../../widgets/async_view.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/empty_state.dart';

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchases = ref.watch(purchasesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Purchases')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/purchase/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New purchase'),
      ),
      body: AsyncView(
        value: purchases,
        onRetry: () => ref.invalidate(purchasesProvider),
        builder: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'No purchases yet',
                message: 'Record stock you buy from suppliers. It is added to this branch\'s stock.',
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(purchasesProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _PurchaseCard(list[i]),
                ),
              ),
      ),
    );
  }
}

class _PurchaseCard extends ConsumerWidget {
  const _PurchaseCard(this.p);
  final Purchase p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showPurchase(context, ref, p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: context.cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.local_shipping_outlined, color: context.cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.supplier?.isNotEmpty == true ? p.supplier! : 'Purchase',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  [
                    day(p.purchasedAt),
                    '${p.lines.length} ${p.lines.length == 1 ? 'item' : 'items'}',
                    if (p.invoiceNo?.isNotEmpty == true) 'Inv ${p.invoiceNo}',
                  ].join(' · '),
                  style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 13),
                ),
              ]),
            ),
            Text(money(p.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
        ),
      ),
    );
  }
}

Future<void> _showPurchase(BuildContext context, WidgetRef ref, Purchase p) {
  final canDelete = ref.read(currentUserProvider)?.canManage ?? false;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(p.supplier?.isNotEmpty == true ? p.supplier! : 'Purchase', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            [day(p.purchasedAt), if (p.invoiceNo?.isNotEmpty == true) 'Invoice ${p.invoiceNo}'].join('  ·  '),
            style: TextStyle(color: context.cs.onSurfaceVariant),
          ),
          if (p.note?.isNotEmpty == true) ...[const SizedBox(height: 8), Text(p.note!)],
          const SizedBox(height: 16),
          for (final l in p.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${qtyWithUnit(l.quantity, l.unit)} × ${money(l.unitCost)}',
                        style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 13)),
                  ]),
                ),
                Text(money(l.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
          const Divider(height: 24),
          Row(children: [
            const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17))),
            Text(money(p.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          ]),
          if (canDelete) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.cs.error,
                side: BorderSide(color: context.cs.error.withValues(alpha: 0.35)),
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete purchase'),
              onPressed: () async {
                final ok = await confirm(ctx,
                    title: 'Delete this purchase?',
                    message: 'The purchased quantities are taken back out of stock.',
                    confirmLabel: 'Delete',
                    danger: true);
                if (!ok) return;
                try {
                  await ref.read(stockServiceProvider).deletePurchase(ref.read(branchIdProvider), p.id);
                  ref.invalidate(purchasesProvider);
                  ref.invalidate(itemsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) AppToast.success(context, 'Purchase deleted');
                } catch (e) {
                  if (context.mounted) AppToast.error(context, e);
                }
              },
            ),
          ],
        ],
      ),
    ),
  );
}
