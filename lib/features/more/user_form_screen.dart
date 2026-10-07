import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_toast.dart';
import '../../models/branch.dart';
import '../../models/user.dart';
import '../../providers/branch_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/services.dart';
import '../../widgets/buttons.dart';
import '../../widgets/section_card.dart';

/// Add a user, or edit [user].
class UserFormScreen extends ConsumerStatefulWidget {
  const UserFormScreen({super.key, this.user});
  final ShopUser? user;

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?.name);
  late final _email = TextEditingController(text: widget.user?.email);
  final _pin = TextEditingController();
  late bool _owner = widget.user?.role == UserRole.owner;
  late bool _active = widget.user?.isActive ?? true;
  late final Set<String> _branchIds = {...?widget.user?.branches.map((b) => b.id)};
  bool _busy = false;

  bool get _editing => widget.user != null;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_owner && _branchIds.isEmpty) {
      AppToast.info(context, 'Choose at least one branch for this staff member');
      return;
    }
    setState(() => _busy = true);
    final service = ref.read(userServiceProvider);
    final role = _owner ? 'OWNER' : 'STAFF';
    try {
      if (_editing) {
        await service.update(
          widget.user!.id,
          name: _name.text.trim(),
          email: _email.text.trim(),
          pin: _pin.text.isEmpty ? null : _pin.text,
          role: role,
          branchIds: _branchIds.toList(),
          isActive: _active,
        );
      } else {
        await service.create(
          name: _name.text.trim(),
          email: _email.text.trim(),
          pin: _pin.text,
          role: role,
          branchIds: _branchIds.toList(),
        );
      }
      ref.invalidate(usersProvider);
      if (!mounted) return;
      AppToast.success(context, _editing ? 'User saved' : 'User added. Share their email and PIN with them.');
      context.pop();
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchesProvider).value ?? const <Branch>[];
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit user' : 'New user')),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(label: _editing ? 'Save changes' : 'Add user', busy: _busy, onPressed: _save),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SectionCard(
              title: 'Details',
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', helperText: 'Used to sign in'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pin,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                  decoration: InputDecoration(
                    labelText: _editing ? 'New PIN' : 'PIN',
                    helperText: _editing ? 'Leave empty to keep the current PIN' : '4 to 8 digits',
                  ),
                  validator: (v) {
                    if (_editing && (v == null || v.isEmpty)) return null;
                    return (v == null || v.length < 4) ? 'PIN must be 4 to 8 digits' : null;
                  },
                ),
              ]),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Access',
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, label: Text('Staff')),
                    ButtonSegment(value: true, label: Text('Owner')),
                  ],
                  selected: {_owner},
                  onSelectionChanged: (s) => setState(() => _owner = s.first),
                ),
                const SizedBox(height: 10),
                Text(
                  _owner
                      ? 'Owners see every branch and can change prices, items, scales and users.'
                      : 'Staff see only the branches you pick below.',
                  style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 13),
                ),
                if (!_owner) ...[
                  const SizedBox(height: 6),
                  for (final b in branches)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _branchIds.contains(b.id),
                      title: Text(b.name),
                      onChanged: (v) => setState(() => v == true ? _branchIds.add(b.id) : _branchIds.remove(b.id)),
                    ),
                ],
              ]),
            ),
            if (_editing) ...[
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  title: const Text('Can sign in', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Turn off to block this user without deleting them'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
