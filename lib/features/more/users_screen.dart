import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/async_view.dart';
import '../../widgets/status_pill.dart';

/// The shop's app users. Owners add staff and choose their branches.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    final me = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/user'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add user'),
      ),
      body: AsyncView(
        value: users,
        onRetry: () => ref.invalidate(usersProvider),
        builder: (list) => RefreshIndicator(
          onRefresh: () => ref.refresh(usersProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  for (final (i, u) in list.indexed) ...[
                    if (i > 0) const Divider(indent: 72),
                    ListTile(
                      onTap: u.id == me?.id ? () => context.push('/profile') : () => context.push('/user', extra: u),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: u.isActive ? context.cs.primaryContainer : context.cs.outlineVariant,
                        foregroundColor: u.isActive ? context.cs.onPrimaryContainer : context.cs.outline,
                        child: Text(initials(u.name), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      title: Row(children: [
                        Flexible(
                          child: Text(
                            u.id == me?.id ? '${u.name} (you)' : u.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!u.isActive)
                          const StatusPill('Disabled', tone: Tone.danger),
                      ]),
                      subtitle: Text(
                        u.role == UserRole.owner
                            ? '@${u.username}\nOwner · all branches'
                            : '@${u.username}\nStaff · ${u.branches.isEmpty ? 'no branches' : u.branches.map((b) => b.name).join(', ')}',
                      ),
                      isThreeLine: true,
                      trailing: Icon(Icons.chevron_right_rounded, color: context.cs.outline),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Staff can see sales, update stock and record purchases in their branches. '
                  'Only owners can change prices, items, scales and users.',
                  style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
