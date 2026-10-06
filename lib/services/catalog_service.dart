import '../models/item.dart';
import 'api_client.dart';

class CatalogService {
  CatalogService(this._api);
  final ApiClient _api;

  // Categories
  Future<List<Category>> categories() async =>
      (await _api.get('/categories') as List).cast<Map<String, dynamic>>().map(Category.fromJson).toList();

  Future<void> createCategory(String name) => _api.post('/categories', body: {'name': name});
  Future<void> renameCategory(String id, String name) => _api.patch('/categories/$id', body: {'name': name});
  Future<void> deleteCategory(String id) => _api.delete('/categories/$id');

  // Items
  Future<List<Item>> items({required String branchId, String? categoryId, String? search, String sort = 'plu'}) async =>
      (await _api.get('/items', query: {
        'branchId': branchId,
        'categoryId': categoryId,
        'search': search,
        'sort': sort,
      }) as List)
          .cast<Map<String, dynamic>>()
          .map(Item.fromJson)
          .toList();

  Future<Item> item(String id, String branchId) async =>
      Item.fromJson(await _api.get('/items/$id', query: {'branchId': branchId}) as Map<String, dynamic>);

  Future<int> nextPlu() async => (await _api.get('/items/next-plu') as Map<String, dynamic>)['plu'] as int;

  Future<void> createItem(Map<String, dynamic> body) => _api.post('/items', body: body);
  Future<void> updateItem(String id, Map<String, dynamic> body) => _api.patch('/items/$id', body: body);
  Future<void> deleteItem(String id) => _api.delete('/items/$id');
  Future<void> deleteAllItems() => _api.post('/items/delete-all');
}
