import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_toast.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;
  bool _showPin = false;

  @override
  void dispose() {
    _email.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).login(_email.text, _pin.text);
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  const BrandMark(size: 48),
                  const SizedBox(width: 14),
                  Text(AppConstants.appName, style: context.tt.titleLarge),
                ]),
                const SizedBox(height: 40),
                Text('Welcome back', style: context.tt.displaySmall?.copyWith(fontSize: 38)),
                const SizedBox(height: 10),
                Text(
                  'Sign in to manage your scales, items and sales.',
                  style: context.tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                Card(
                  color: cs.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _form,
                      child: AutofillGroup(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email, AutofillHints.username],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: (v) =>
                                (v == null || !v.contains('@')) ? 'Enter the email your dealer set up' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _pin,
                            obscureText: !_showPin,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(8),
                            ],
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'PIN',
                              prefixIcon: const Icon(Icons.pin_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(_showPin ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                                onPressed: () => setState(() => _showPin = !_showPin),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 4) ? 'PIN is 4 to 8 digits' : null,
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(label: 'Sign in', icon: Icons.arrow_forward_rounded, busy: _busy, onPressed: _submit),
                        ]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Icon(Icons.help_outline_rounded, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Forgot your PIN? Ask your shop owner or dealer to reset it.',
                      style: context.tt.bodySmall,
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
