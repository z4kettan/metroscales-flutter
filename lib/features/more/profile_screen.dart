import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/format.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/services.dart';
import '../../widgets/buttons.dart';
import '../../widgets/section_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: Column(children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: Text(initials(user.name), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              Text(user.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                [roleName(user.role), ?user.customerName].join(' · '),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          _DetailsCard(user: user),
          const SizedBox(height: 12),
          const _PinCard(),
        ],
      ),
    );
  }
}

class _DetailsCard extends ConsumerStatefulWidget {
  const _DetailsCard({required this.user});
  final AppUser user;

  @override
  ConsumerState<_DetailsCard> createState() => _DetailsCardState();
}

class _DetailsCardState extends ConsumerState<_DetailsCard> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _email = TextEditingController(text: widget.user.email);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final user = await ref.read(authServiceProvider).updateProfile(name: _name.text.trim(), email: _email.text.trim());
      ref.read(authProvider.notifier).setUser(user);
      if (mounted) AppToast.success(context, 'Profile saved');
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _form,
        child: SectionCard(
          title: 'Details',
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Save details', busy: _busy, onPressed: _save),
          ]),
        ),
      );
}

class _PinCard extends ConsumerStatefulWidget {
  const _PinCard();

  @override
  ConsumerState<_PinCard> createState() => _PinCardState();
}

class _PinCardState extends ConsumerState<_PinCard> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).changePin(_current.text, _next.text);
      _current.clear();
      _next.clear();
      _repeat.clear();
      if (mounted) AppToast.success(context, 'PIN changed');
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pin = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)];
    return Form(
      key: _form,
      child: SectionCard(
        title: 'Change PIN',
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(children: [
          TextFormField(
            controller: _current,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: pin,
            decoration: const InputDecoration(labelText: 'Current PIN'),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter your current PIN' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _next,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: pin,
            decoration: const InputDecoration(labelText: 'New PIN', helperText: '4 to 8 digits'),
            validator: (v) => (v == null || v.length < 4) ? 'PIN must be 4 to 8 digits' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _repeat,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: pin,
            decoration: const InputDecoration(labelText: 'Repeat new PIN'),
            validator: (v) => v != _next.text ? 'PINs do not match' : null,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2))
                : const Text('Change PIN'),
          ),
        ]),
      ),
    );
  }
}
