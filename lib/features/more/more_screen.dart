import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/user.dart';
import '../../providers/appearance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/section_card.dart';
import '../../widgets/tab_page.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canManage = user?.canManage ?? false;
    final cs = context.cs;

    return TabPage(
      title: 'More',
      showBranch: false,
      slivers: [
        SliverPagePadding(
          bottom: 32,
          sliver: SliverList.list(children: [
            if (user != null)
              Card(
                color: cs.primaryContainer,
                child: InkWell(
                  onTap: () => context.push('/profile'),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        child: Text(initials(user.name), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(user.name, style: context.tt.titleLarge?.copyWith(color: cs.onPrimaryContainer)),
                          const SizedBox(height: 2),
                          Text(user.email, style: TextStyle(color: cs.onPrimaryContainer.withValues(alpha: 0.8))),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(999)),
                            child: Text(
                              [roleName(user.role), ?user.customerName].join(' · '),
                              style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ),
                        ]),
                      ),
                      Icon(Icons.chevron_right_rounded, color: cs.onPrimaryContainer),
                    ]),
                  ),
                ),
              ),
            const SectionLabel('Stock'),
            _Group([
              if (canManage) const _Entry(Icons.sell_rounded, 'Update prices', 'Change prices for this branch', '/prices'),
              const _Entry(Icons.inventory_rounded, 'Update stock', 'Correct stock after a count', '/stock'),
              const _Entry(Icons.local_shipping_rounded, 'Purchases', 'Stock bought from suppliers', '/purchases'),
              const _Entry(Icons.category_rounded, 'Categories', 'Group your items', '/categories'),
            ]),
            if (canManage) ...[
              const SectionLabel('Shop settings'),
              const _Group([
                _Entry(Icons.receipt_long_rounded, 'Bill settings', 'Header and footer printed on bills', '/bill-settings'),
                _Entry(Icons.group_rounded, 'Users', 'Staff who can use the app', '/users'),
              ]),
            ],
            const SectionLabel('Appearance'),
            const _AppearanceCard(),
            const SectionLabel('Account'),
            const _Group([_Entry(Icons.person_rounded, 'Profile and PIN', 'Your name, email and PIN', '/profile')]),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: cs.errorContainer,
                foregroundColor: cs.onErrorContainer,
                minimumSize: const Size(0, 52),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
              onPressed: () async {
                final ok = await confirm(
                  context,
                  title: 'Sign out?',
                  message: 'You will need your email and PIN to sign in again.',
                  confirmLabel: 'Sign out',
                  icon: Icons.logout_rounded,
                );
                if (ok) await ref.read(authProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 20),
            Text(
              '${AppConstants.appName} ${AppConstants.appVersion}',
              textAlign: TextAlign.center,
              style: context.tt.bodySmall,
            ),
          ]),
        ),
      ],
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
        child: Column(children: [
          for (final e in entries)
            ListTile(
              onTap: () => context.push(e.path),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: IconBox(e.icon, size: 42),
              title: Text(e.title),
              subtitle: Text(e.subtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
        ]),
      );
}

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Light')),
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded), label: Text('Auto')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Dark')),
            ],
            selected: {a.mode},
            onSelectionChanged: (s) => notifier.setMode(s.first),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            value: a.wallpaperColours,
            onChanged: notifier.setWallpaperColours,
            title: const Text('Match wallpaper colours'),
            subtitle: const Text('Use your phone\'s colours (Android 12 and newer)'),
          ),
        ]),
      ),
    );
  }
}
