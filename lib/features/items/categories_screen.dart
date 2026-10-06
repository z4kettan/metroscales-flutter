import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../models/item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/services.dart';
import '../../widgets/async_view.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/empty_state.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final name = await promptText(context, title: 'New category', label: 'Category name', confirmLabel: 'Add');
    if (name == null) return;
    try {
      await ref.read(catalogServiceProvider).createCategory(name);
      ref.invalidate(categoriesProvider);
      if (context.mounted) AppToast.success(context, 'Category added');
    } catch (e) {
      if (context.mounted) AppToast.error(context, e);
    }
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, Category c) async {
    final name = await promptText(context, title: 'Rename category', label: 'Category name', initial: c.name);
    if (name == null || name == c.name) return;
    try {
      await ref.read(catalogServiceProvider).renameCategory(c.id, name);
      ref.invalidate(categoriesProvider);
      ref.invalidate(itemsProvider);
    } catch (e) {
      if (context.mounted) AppToast.error(context, e);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Category c) async {
    final ok = await confirm(
      context,
      title: 'Delete ${c.name}?',
      message: c.itemCount == 0
          ? 'This category has no items.'
          : 'Its ${c.itemCount} ${c.itemCount == 1 ? 'item stays' : 'items stay'} but will have no category.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok) return;
    try {
      await ref.read(catalogServiceProvider).deleteCategory(c.id);
      ref.invalidate(categoriesProvider);
      ref.invalidate(itemsProvider);
      if (context.mounted) AppToast.success(context, 'Category deleted');
    } catch (e) {
      if (context.mounted) AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final canManage = ref.watch(currentUserProvider)?.canManage ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add category'),
            )
          : null,
      body: AsyncView(
        value: categories,
        onRetry: () => ref.invalidate(categoriesProvider),
        builder: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              title: 'No categories',
              message: 'Group items into categories like Vegetables or Fruits to find them faster.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  for (final (i, c) in list.indexed) ...[
                    if (i > 0) const Divider(indent: 68),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primaryDark,
                        child: Text('${c.code}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${c.itemCount} ${c.itemCount == 1 ? 'item' : 'items'}'),
                      trailing: canManage
                          ? PopupMenuButton<String>(
                              onSelected: (v) => v == 'rename' ? _rename(context, ref, c) : _delete(context, ref, c),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'rename', child: Text('Rename')),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete', style: TextStyle(color: AppColors.danger)),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ],
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}
