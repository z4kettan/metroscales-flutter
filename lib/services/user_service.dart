import '../models/user.dart';
import 'api_client.dart';

class UserService {
  UserService(this._api);
  final ApiClient _api;

  Future<List<ShopUser>> list() async =>
      (await _api.get('/users') as List).cast<Map<String, dynamic>>().map(ShopUser.fromJson).toList();

  Future<void> create({
    required String name,
    required String username,
    required String password,
    required String role,
    required List<String> branchIds,
  }) =>
      _api.post('/users', body: {
        'name': name,
        'username': username,
        'password': password,
        'role': role,
        'branchIds': branchIds,
      });

  Future<void> update(
    String id, {
    String? name,
    String? username,
    String? password,
    String? role,
    List<String>? branchIds,
    bool? isActive,
  }) =>
      _api.patch('/users/$id', body: {
        'name': ?name,
        'username': ?username,
        'password': ?password,
        'role': ?role,
        'branchIds': ?branchIds,
        'isActive': ?isActive,
      });
}
