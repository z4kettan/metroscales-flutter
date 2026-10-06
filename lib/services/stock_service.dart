import '../models/sales.dart';
import 'api_client.dart';

class StockService {
  StockService(this._api);
  final ApiClient _api;

  /// Saves new prices for this branch. Returns how many scales they were queued for.
  Future<int> setPrices(String branchId, Map<String, double> prices) async {
    final data = await _api.put('/branches/$branchId/prices', body: {
      'prices': [for (final e in prices.entries) {'itemId': e.key, 'price': e.value}],
    }) as Map<String, dynamic>?;
    return (data?['queuedForScales'] as num?)?.toInt() ?? 0;
  }

  Future<void> setStock(String branchId, Map<String, double> stock, {String? note}) =>
      _api.put('/branches/$branchId/stock', body: {
        'stock': [for (final e in stock.entries) {'itemId': e.key, 'quantity': e.value}],
        'note': ?note,
      });

  Future<void> clearStock(String branchId) => _api.post('/branches/$branchId/stock/clear');

  Future<List<Purchase>> purchases(String branchId) async =>
      (await _api.get('/branches/$branchId/purchases') as List)
          .cast<Map<String, dynamic>>()
          .map(Purchase.fromJson)
          .toList();

  Future<Purchase> createPurchase(
    String branchId, {
    required DateTime purchasedAt,
    String? supplier,
    String? invoiceNo,
    String? note,
    required List<({String itemId, double quantity, double unitCost})> lines,
  }) async =>
      Purchase.fromJson(await _api.post('/branches/$branchId/purchases', body: {
        'purchasedAt': purchasedAt.toUtc().toIso8601String(),
        'supplier': ?supplier,
        'invoiceNo': ?invoiceNo,
        'note': ?note,
        'lines': [
          for (final l in lines) {'itemId': l.itemId, 'quantity': l.quantity, 'unitCost': l.unitCost},
        ],
      }) as Map<String, dynamic>);

  Future<void> deletePurchase(String branchId, String id) => _api.delete('/branches/$branchId/purchases/$id');
}
