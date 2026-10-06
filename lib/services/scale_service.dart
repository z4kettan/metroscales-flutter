import '../models/scale.dart';
import 'api_client.dart';

class ScaleService {
  ScaleService(this._api);
  final ApiClient _api;

  Future<List<Scale>> list(String branchId) async =>
      (await _api.get('/scales', query: {'branchId': branchId}) as List)
          .cast<Map<String, dynamic>>()
          .map(Scale.fromJson)
          .toList();

  Future<Scale> get(String id) async => Scale.fromJson(await _api.get('/scales/$id') as Map<String, dynamic>);

  Future<void> updateDetails(String id, {String? name, int? number, String? storeName}) =>
      _api.patch('/scales/$id', body: {'name': ?name, 'number': ?number, 'storeName': ?storeName});

  Future<void> setWifi(String id, String ssid, String password) =>
      _api.post('/scales/$id/wifi', body: {'ssid': ssid, 'password': password});

  Future<PrintFormat> printFormat(String id) async =>
      PrintFormat.fromJson(await _api.get('/scales/$id/print-format') as Map<String, dynamic>?);

  Future<void> savePrintFormat(String id, PrintFormat f) => _api.put('/scales/$id/print-format', body: {
        'format1': f.format1,
        'format2': f.format2,
        'postils': f.postils,
      });

  Future<List<Shortcut>> shortcuts(String id) async =>
      (await _api.get('/scales/$id/shortcuts') as List).cast<Map<String, dynamic>>().map(Shortcut.fromJson).toList();

  /// [changes] maps (keyNo, layer) to an item id, or null to clear the key.
  Future<void> saveShortcuts(String id, Map<(int, int), String?> changes) => _api.put('/scales/$id/shortcuts', body: {
        'shortcuts': [
          for (final e in changes.entries) {'keyNo': e.key.$1, 'layer': e.key.$2, 'itemId': e.value},
        ],
      });

  /// PUSH_ITEMS, PULL_ITEMS or CLEAR_PLU. Returns whether the scale is online now.
  Future<bool> runCommand(String id, String type) async =>
      (await _api.post('/scales/$id/commands', body: {'type': type}) as Map<String, dynamic>)['online'] as bool? ??
      false;

  Future<List<ScaleCommand>> history(String id) async =>
      (await _api.get('/scales/$id/commands') as List).cast<Map<String, dynamic>>().map(ScaleCommand.fromJson).toList();
}
