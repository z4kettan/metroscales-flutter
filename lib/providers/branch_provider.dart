import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/branch.dart';
import 'auth_provider.dart';
import 'services.dart';

/// Branches the signed-in user can see.
final branchesProvider = FutureProvider<List<Branch>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.watch(branchServiceProvider).list();
});

/// The branch the user picked; remembered between launches.
final selectedBranchIdProvider = NotifierProvider<SelectedBranchNotifier, String?>(SelectedBranchNotifier.new);

class SelectedBranchNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.read(tokenServiceProvider).getBranchId().then((id) {
      if (id != null && state == null) state = id;
    });
    return null;
  }

  void select(String id) {
    state = id;
    ref.read(tokenServiceProvider).saveBranchId(id);
  }
}

/// The branch every screen works on: the picked one if still visible,
/// otherwise the first branch.
final currentBranchProvider = Provider<Branch?>((ref) {
  final branches = ref.watch(branchesProvider).value ?? const [];
  if (branches.isEmpty) return null;
  final id = ref.watch(selectedBranchIdProvider);
  return branches.firstWhere((b) => b.id == id, orElse: () => branches.first);
});

/// The current branch id. Only read this on screens shown after a branch exists.
final branchIdProvider = Provider<String>((ref) => ref.watch(currentBranchProvider)?.id ?? '');
