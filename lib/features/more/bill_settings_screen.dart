import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../models/branch.dart';
import '../../providers/branch_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/services.dart';
import '../../widgets/async_view.dart';
import '../../widgets/buttons.dart';
import '../../widgets/section_card.dart';

/// Text printed at the top and bottom of bills, for the current branch.
class BillSettingsScreen extends ConsumerWidget {
  const BillSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(billSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bill settings')),
      body: AsyncView(
        value: settings,
        onRetry: () => ref.invalidate(billSettingsProvider),
        builder: (s) => _Form(initial: s),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.initial});
  final BillSettings initial;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final _header = TextEditingController(text: widget.initial.header);
  late final _offer = TextEditingController(text: widget.initial.offerTitle);
  late final _itemFooter = TextEditingController(text: widget.initial.itemFooter);
  late final _billFooter = TextEditingController(text: widget.initial.billFooter);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_header, _offer, _itemFooter, _billFooter]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_header, _offer, _itemFooter, _billFooter]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(branchServiceProvider).saveBillSettings(
            ref.read(branchIdProvider),
            BillSettings(
              header: _header.text.trim(),
              offerTitle: _offer.text.trim(),
              itemFooter: _itemFooter.text.trim(),
              billFooter: _billFooter.text.trim(),
            ),
          );
      ref.invalidate(billSettingsProvider);
      if (!mounted) return;
      AppToast.success(context, 'Bill settings saved and sent to the scales');
      context.pop();
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(TextEditingController c, String label, String hint) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: TextField(
          controller: c,
          maxLength: 64,
          decoration: InputDecoration(labelText: label, hintText: hint, counterText: ''),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final branch = ref.watch(currentBranchProvider);
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SectionCard(
              title: branch == null ? 'Bill text' : 'Bill text · ${branch.name}',
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: [
                _field(_header, 'Header', 'Shop name at the top'),
                _field(_offer, 'Offer title', 'e.g. Fresh daily'),
                _field(_itemFooter, 'Item footer', 'Below the item lines'),
                _field(_billFooter, 'Bill footer', 'e.g. Thank you, visit again'),
              ]),
            ),
            const SectionLabel('Preview'),
            _Preview(
              header: _header.text,
              offer: _offer.text,
              itemFooter: _itemFooter.text,
              billFooter: _billFooter.text,
            ),
          ],
        ),
      ),
      BottomActionBar(child: PrimaryButton(label: 'Save bill settings', busy: _busy, onPressed: _save)),
    ]);
  }
}

/// A rough picture of the 58 mm receipt.
class _Preview extends StatelessWidget {
  const _Preview({required this.header, required this.offer, required this.itemFooter, required this.billFooter});
  final String header;
  final String offer;
  final String itemFooter;
  final String billFooter;

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.5, color: AppColors.text);
    Widget line(String t, {bool bold = false}) => t.trim().isEmpty
        ? const SizedBox.shrink()
        : Text(t, textAlign: TextAlign.center, style: mono.copyWith(fontWeight: bold ? FontWeight.w700 : null));
    return Center(
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [BoxShadow(color: Color(0x0F101828), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          line(header, bold: true),
          line(offer),
          const Text('- - - - - - - - - - - - - - -', textAlign: TextAlign.center, style: mono),
          const Text('Thakkali  0.500 kg   ₹20.00', style: mono),
          const Text('Payar     0.250 kg   ₹10.00', style: mono),
          line(itemFooter),
          const Text('- - - - - - - - - - - - - - -', textAlign: TextAlign.center, style: mono),
          Text('TOTAL              ₹30.00', style: mono.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          line(billFooter),
        ]),
      ),
    );
  }
}
