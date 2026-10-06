import 'json.dart';

enum UserRole { dealerAdmin, owner, staff }

UserRole parseRole(String? r) => switch (r) {
      'DEALER_ADMIN' => UserRole.dealerAdmin,
      'OWNER' => UserRole.owner,
      _ => UserRole.staff,
    };

String roleName(UserRole r) => switch (r) {
      UserRole.dealerAdmin => 'Dealer',
      UserRole.owner => 'Owner',
      UserRole.staff => 'Staff',
    };

/// The signed-in user.
class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? customerName;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.customerName,
  });

  /// Owners manage prices, items, scales and users; staff record stock and purchases.
  bool get canManage => role != UserRole.staff;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: parseRole(j['role'] as String?),
        customerName: (j['customer'] as Map<String, dynamic>?)?['name'] as String?,
      );
}

/// A user of the shop, as listed on the Users screen.
class ShopUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final List<({String id, String name})> branches;

  const ShopUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.branches,
  });

  factory ShopUser.fromJson(Map<String, dynamic> j) => ShopUser(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: parseRole(j['role'] as String?),
        isActive: j['isActive'] as bool? ?? true,
        branches: [for (final b in mapList(j['branches'])) (id: b['id'] as String, name: b['name'] as String)],
      );
}
