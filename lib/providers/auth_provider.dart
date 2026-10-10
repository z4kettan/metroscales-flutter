import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/session_manager.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import 'services.dart';

/// The signed-in user, or null when signed out.
final authProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    SessionManager.instance.register(_expire);
    final token = await ref.read(tokenServiceProvider).getAccessToken();
    if (token == null) return null;
    try {
      return await ref.read(authServiceProvider).me();
    } on ApiException catch (e) {
      // Keep the user signed in when the server is just unreachable.
      if (e.statusCode == 401 || e.statusCode == 403) {
        await ref.read(tokenServiceProvider).clear();
        return null;
      }
      rethrow;
    }
  }

  Future<void> login(String username, String password) async {
    final user = await ref.read(authServiceProvider).login(username, password);
    state = AsyncData(user);
  }

  Future<void> refreshUser() async {
    state = AsyncData(await ref.read(authServiceProvider).me());
  }

  void setUser(AppUser user) => state = AsyncData(user);

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = const AsyncData(null);
  }

  Future<void> _expire() async {
    await ref.read(tokenServiceProvider).clear();
    state = const AsyncData(null);
  }
}

/// The signed-in user once known. Screens behind the login can rely on it.
final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authProvider).value);
