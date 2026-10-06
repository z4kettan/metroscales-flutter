import '../core/utils/format.dart';
import '../models/sales.dart';
import 'api_client.dart';

class ReportService {
  ReportService(this._api);
  final ApiClient _api;

  Future<DaySales> summary(String branchId, DateTime date) async => DaySales.fromJson(
        await _api.get('/reports/summary', query: {'branchId': branchId, 'date': isoDay(date)}) as Map<String, dynamic>,
      );

  Future<List<DaySales>> daily(String branchId, DateTime from, DateTime to) async =>
      (await _api.get('/reports/daily', query: {'branchId': branchId, 'from': isoDay(from), 'to': isoDay(to)}) as List)
          .cast<Map<String, dynamic>>()
          .map(DaySales.fromJson)
          .toList();

  Future<List<Bill>> bills(String branchId, DateTime date) async =>
      (await _api.get('/reports/bills', query: {'branchId': branchId, 'date': isoDay(date)}) as List)
          .cast<Map<String, dynamic>>()
          .map(Bill.fromJson)
          .toList();

  Future<List<ItemSales>> itemSales(String branchId, DateTime from, DateTime to) async =>
      (await _api.get('/reports/items', query: {'branchId': branchId, 'from': isoDay(from), 'to': isoDay(to)}) as List)
          .cast<Map<String, dynamic>>()
          .map(ItemSales.fromJson)
          .toList();
}
