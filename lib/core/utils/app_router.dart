import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/items/categories_screen.dart';
import '../../features/items/item_form_screen.dart';
import '../../features/items/items_screen.dart';
import '../../features/more/bill_settings_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/more/profile_screen.dart';
import '../../features/more/user_form_screen.dart';
import '../../features/more/users_screen.dart';
import '../../features/reports/bills_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/scales/print_format_screen.dart';
import '../../features/scales/scale_detail_screen.dart';
import '../../features/scales/scale_settings_screen.dart';
import '../../features/scales/scales_screen.dart';
import '../../features/scales/shortcuts_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/stock/bulk_edit_screen.dart';
import '../../features/stock/purchase_form_screen.dart';
import '../../features/stock/purchases_screen.dart';
import '../../models/item.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Re-runs the router's redirect whenever the sign-in state changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthListenable(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      // Remember where the user was heading so a link or a reload lands there
      // once the session has been checked.
      final from = state.uri.queryParameters['from'];
      if (auth.isLoading && !auth.hasValue) {
        if (loc == '/splash') return null;
        return Uri(path: '/splash', queryParameters: {'from': state.uri.toString()}).toString();
      }
      final signedIn = auth.value != null;
      if (!signedIn) return loc == '/login' ? null : '/login';
      if (loc == '/login') return '/home';
      if (loc == '/splash') return (from == null || from.startsWith('/splash')) ? '/home' : from;
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/items', builder: (_, _) => const ItemsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/scales', builder: (_, _) => const ScalesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/more', builder: (_, _) => const MoreScreen())]),
        ],
      ),
      // Full-screen pages opened from the tabs
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/item',
        builder: (_, s) => ItemFormScreen(item: s.extra as Item?),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: '/categories', builder: (_, _) => const CategoriesScreen()),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/scale/:id',
        builder: (_, s) => ScaleDetailScreen(scaleId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            parentNavigatorKey: _rootKey,
            path: 'settings',
            builder: (_, s) => ScaleSettingsScreen(scaleId: s.pathParameters['id']!),
          ),
          GoRoute(
            parentNavigatorKey: _rootKey,
            path: 'print-format',
            builder: (_, s) => PrintFormatScreen(scaleId: s.pathParameters['id']!),
          ),
          GoRoute(
            parentNavigatorKey: _rootKey,
            path: 'shortcuts',
            builder: (_, s) => ShortcutsScreen(scaleId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/prices',
        builder: (_, _) => const BulkEditScreen(mode: BulkEditMode.price),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/stock',
        builder: (_, _) => const BulkEditScreen(mode: BulkEditMode.stock),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: '/purchases', builder: (_, _) => const PurchasesScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/purchase/new', builder: (_, _) => const PurchaseFormScreen()),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/bills',
        builder: (_, s) => BillsScreen(date: DateTime.tryParse(s.uri.queryParameters['date'] ?? '') ?? DateTime.now()),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: '/bill-settings', builder: (_, _) => const BillSettingsScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/users', builder: (_, _) => const UsersScreen()),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/user',
        builder: (_, s) => UserFormScreen(user: s.extra as ShopUser?),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: '/profile', builder: (_, _) => const ProfileScreen()),
    ],
  );
});
