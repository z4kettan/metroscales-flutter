import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_toast.dart';
import '../../models/scale.dart';
import '../../providers/data_providers.dart';
import '../../providers/services.dart';
import '../../widgets/async_view.dart';
import '../../widgets/buttons.dart';
import '../../widgets/section_card.dart';

/// The scale's name, number and store name, and its WiFi network.
class ScaleSettingsScreen extends ConsumerWidget {
  const ScaleSettingsScreen({super.key, required this.scaleId});
  final String scaleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(scaleProvider(scaleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Scale details and WiFi')),
      body: AsyncView(
        value: scale,
        onRetry: () => ref.invalidate(scaleProvider(scaleId)),
        builder: (s) => _Form(scale: s),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.scale});
  final Scale scale;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _detailsForm = GlobalKey<FormState>();
  final _wifiForm = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.scale.name);
  late final _number = TextEditingController(text: '${widget.scale.number}');
  late final _store = TextEditingController(text: widget.scale.storeName);
  late final _ssid = TextEditingController(text: widget.scale.wifiSsid);
  final _password = TextEditingController();
  bool _savingDetails = false;
  bool _savingWifi = false;
  bool _showPassword = false;

  @override
  void dispose() {
    for (final c in [_name, _number, _store, _ssid, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(scaleProvider(widget.scale.id));
    ref.invalidate(scalesProvider);
  }

  Future<void> _saveDetails() async {
    if (!_detailsForm.currentState!.validate()) return;
    setState(() => _savingDetails = true);
    try {
      await ref.read(scaleServiceProvider).updateDetails(
            widget.scale.id,
            name: _name.text.trim(),
            number: int.parse(_number.text),
            storeName: _store.text.trim(),
          );
      _refresh();
      if (mounted) AppToast.success(context, 'Saved. The scale gets the new details on its next sync.');
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _savingDetails = false);
    }
  }

  Future<void> _saveWifi() async {
    if (!_wifiForm.currentState!.validate()) return;
    setState(() => _savingWifi = true);
    try {
      await ref.read(scaleServiceProvider).setWifi(widget.scale.id, _ssid.text.trim(), _password.text);
      _refresh();
      if (!mounted) return;
      AppToast.success(context, 'WiFi change queued for the scale');
      context.pop();
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _savingWifi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Form(
          key: _detailsForm,
          child: SectionCard(
            title: 'Details',
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _name,
                    maxLength: 40,
                    decoration: const InputDecoration(labelText: 'Scale name', counterText: ''),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _number,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Scale no.'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 1 || n > 99) ? '1 to 99' : null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              TextFormField(
                controller: _store,
                maxLength: 40,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Store name',
                  helperText: 'Printed on bills and labels',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: 'Save details', busy: _savingDetails, onPressed: _saveDetails),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Form(
          key: _wifiForm,
          child: SectionCard(
            title: 'WiFi',
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(
                'The scale switches to this network on its next sync. Make sure the name and password are right, '
                'or the scale will go offline until it is set up again on the scale itself.',
                style: TextStyle(color: context.cs.onSurfaceVariant, height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _ssid,
                maxLength: 32,
                decoration: const InputDecoration(
                  labelText: 'Network name (SSID)',
                  prefixIcon: Icon(Icons.wifi_rounded),
                  counterText: '',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the network name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: !_showPassword,
                maxLength: 63,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _savingWifi ? null : _saveWifi,
                child: _savingWifi
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2))
                    : const Text('Change WiFi'),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
