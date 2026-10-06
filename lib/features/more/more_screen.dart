import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/section_card.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canManage = user?.canManage ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (user != null)
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push('/profile'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      child: Text(initials(user.name), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          [roleName(user.role), ?user.customerName].join(' · '),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ]),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ]),
                ),
              ),
            ),
          const SectionLabel('Stock'),
          _Group([
            if (canManage) _Entry(Icons.sell_outlined, 'Update prices', 'Change prices for this branch', '/prices'),
            _Entry(Icons.inventory_outlined, 'Update stock', 'Correct stock after a count', '/stock'),
            _Entry(Icons.local_shipping_outlined, 'Purchases', 'Stock bought from suppliers', '/purchases'),
            _Entry(Icons.category_outlined, 'Categories', 'Group your items', '/categories'),
          ]),
          if (canManage) ...[
            const SectionLabel('Shop settings'),
            _Group([
              _Entry(Icons.receipt_long_outlined, 'Bill settings', 'Header and footer printed on bills', '/bill-settings'),
              _Entry(Icons.group_outlined, 'Users', 'Staff who can use the app', '/users'),
            ]),
          ],
          const SectionLabel('Account'),
          _Group([
            _Entry(Icons.person_outline_rounded, 'Profile and PIN', 'Your name, email and PIN', '/profile'),
          ]),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
            onPressed: () async {
              final ok = await confirm(context, title: 'Sign out?', message: 'You will need your email and PIN to sign in again.', confirmLabel: 'Sign out');
              if (ok) await ref.read(authProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 20),
          Text(
            '${AppConstants.appName} ${AppConstants.appVersion}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Entry {
  const _Entry(this.icon, this.title, this.subtitle, this.path);
  final IconData icon;
  final String title;
  final String subtitle;
  final String path;
}

class _Group extends StatelessWidget {
  const _Group(this.entries);
  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (final (i, e) in entries.indexed) ...[
            if (i > 0) const Divider(indent: 64),
            ListTile(
              onTap: () => context.push(e.path),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                child: Icon(e.icon, color: AppColors.primary, size: 20),
              ),
              title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(e.subtitle),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ),
          ],
        ]),
      );
}
