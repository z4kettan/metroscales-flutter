import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_toast.dart';
import '../../models/scale.dart';
import '../../providers/data_providers.dart';
import '../../providers/services.dart';
import '../../widgets/async_view.dart';
import '../../widgets/buttons.dart';
import '../../widgets/section_card.dart';

final _printFormatProvider = FutureProvider.autoDispose.family<PrintFormat, String>(
  (ref, id) => ref.watch(scaleServiceProvider).printFormat(id),
);

/// Label formats and the footer lines ("postils") the scale prints.
class PrintFormatScreen extends ConsumerWidget {
  const PrintFormatScreen({super.key, required this.scaleId});
  final String scaleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = ref.watch(_printFormatProvider(scaleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Print format')),
      body: AsyncView(
        value: format,
        onRetry: () => ref.invalidate(_printFormatProvider(scaleId)),
        builder: (f) => _Form(scaleId: scaleId, format: f),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.scaleId, required this.format});
  final String scaleId;
  final PrintFormat format;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final _format1 = TextEditingController(text: widget.format.format1);
  late final _format2 = TextEditingController(text: widget.format.format2);
  late final _postils = [
    for (var i = 0; i < AppConstants.postilLines; i++)
      TextEditingController(text: i < widget.format.postils.length ? widget.format.postils[i] : ''),
  ];
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_format1, _format2, ..._postils]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      // Keep line positions but drop empty lines at the end
      final lines = _postils.map((c) => c.text.trim()).toList();
      while (lines.isNotEmpty && lines.last.isEmpty) {
        lines.removeLast();
      }
      await ref.read(scaleServiceProvider).savePrintFormat(
            widget.scaleId,
            PrintFormat(format1: _format1.text.trim(), format2: _format2.text.trim(), postils: lines),
          );
      ref.invalidate(scaleProvider(widget.scaleId));
      if (!mounted) return;
      AppToast.success(context, 'Print format saved and queued for the scale');
      context.pop();
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SectionCard(
              title: 'Label formats',
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(children: [
                TextField(
                  controller: _format1,
                  maxLength: 64,
                  decoration: const InputDecoration(labelText: 'Format 1', counterText: ''),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _format2,
                  maxLength: 64,
                  decoration: const InputDecoration(labelText: 'Format 2', counterText: ''),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Footer lines',
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(
                  'Printed at the bottom of each label, one per line. Leave unused lines empty.',
                  style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 13),
                ),
                for (var i = 0; i < _postils.length; i++) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _postils[i],
                    maxLength: 64,
                    decoration: InputDecoration(
                      labelText: 'Line ${i + 1}',
                      counterText: '',
                      prefixIcon: SizedBox(
                        width: 44,
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(fontWeight: FontWeight.w700, color: context.cs.outline),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
      BottomActionBar(child: PrimaryButton(label: 'Save print format', busy: _busy, onPressed: _save)),
    ]);
  }
}
