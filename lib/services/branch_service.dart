import '../models/branch.dart';
import 'api_client.dart';

class BranchService {
  BranchService(this._api);
  final ApiClient _api;

  Future<List<Branch>> list() async =>
      (await _api.get('/branches') as List).cast<Map<String, dynamic>>().map(Branch.fromJson).toList();

  Future<BillSettings> billSettings(String branchId) async =>
      BillSettings.fromJson(await _api.get('/branches/$branchId/bill-settings') as Map<String, dynamic>?);

  Future<void> saveBillSettings(String branchId, BillSettings s) => _api.put('/branches/$branchId/bill-settings', body: {
        'header': s.header,
        'billFooter': s.billFooter,
        'itemFooter': s.itemFooter,
        'offerTitle': s.offerTitle,
      });
}
