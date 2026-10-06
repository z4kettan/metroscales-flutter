import 'json.dart';

class Scale {
  final String id;
  final String mac;
  final String name;
  final int number;
  final String? model;
  final String? branchName;
  final String? storeName;
  final String? wifiSsid;
  final String? firmware;
  final String? lastIp;
  final DateTime? lastSeenAt;
  final bool online;
  final int pendingCommands;
  final List<ScaleCommand> recentCommands;

  const Scale({
    required this.id,
    required this.mac,
    required this.name,
    this.number = 1,
    this.model,
    this.branchName,
    this.storeName,
    this.wifiSsid,
    this.firmware,
    this.lastIp,
    this.lastSeenAt,
    this.online = false,
    this.pendingCommands = 0,
    this.recentCommands = const [],
  });

  /// "Y201 (1)" like the scale's own display.
  String get title => '$name ($number)';

  factory Scale.fromJson(Map<String, dynamic> j) {
    final recent = mapList(j['recentCommands']).map(ScaleCommand.fromJson).toList();
    return Scale(
      id: j['id'] as String,
      mac: j['mac'] as String? ?? '',
      name: j['name'] as String? ?? '',
      number: toInt(j['number']),
      model: str(j['model']),
      branchName: (j['branch'] as Map<String, dynamic>?)?['name'] as String?,
      storeName: str(j['storeName']),
      wifiSsid: str(j['wifiSsid']),
      firmware: str(j['firmware']),
      lastIp: str(j['lastIp']),
      lastSeenAt: toDate(j['lastSeenAt']),
      online: j['online'] as bool? ?? false,
      pendingCommands: j.containsKey('pendingCommands')
          ? toInt(j['pendingCommands'])
          : recent.where((c) => c.isWaiting).length,
      recentCommands: recent,
    );
  }
}

class ScaleCommand {
  final String id;
  final String type;
  final String status;
  final String? error;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const ScaleCommand({
    required this.id,
    required this.type,
    required this.status,
    this.error,
    this.createdAt,
    this.completedAt,
  });

  bool get isWaiting => status == 'PENDING' || status == 'SENT';

  String get label => switch (type) {
        'PUSH_ITEMS' => 'Send items and prices',
        'PULL_ITEMS' => 'Read items from scale',
        'CLEAR_PLU' => 'Clear all items on scale',
        'SET_PARAMETERS' => 'Update scale details',
        'SET_WIFI' => 'Change WiFi',
        'SET_PRINT_FORMAT' => 'Update print format',
        'SET_SHORTCUTS' => 'Update shortcut keys',
        'SET_BILL_SETTINGS' => 'Update bill header and footer',
        _ => type,
      };

  String get statusLabel => switch (status) {
        'PENDING' => 'Waiting',
        'SENT' => 'Sending',
        'DONE' => 'Done',
        'FAILED' => 'Failed',
        'CANCELLED' => 'Cancelled',
        _ => status,
      };

  factory ScaleCommand.fromJson(Map<String, dynamic> j) => ScaleCommand(
        id: j['id'] as String,
        type: j['type'] as String? ?? '',
        status: j['status'] as String? ?? 'PENDING',
        error: str(j['error']),
        createdAt: toDate(j['createdAt']),
        completedAt: toDate(j['completedAt']),
      );
}

class PrintFormat {
  final String format1;
  final String format2;
  final List<String> postils;

  const PrintFormat({this.format1 = '', this.format2 = '', this.postils = const []});

  factory PrintFormat.fromJson(Map<String, dynamic>? j) => PrintFormat(
        format1: j?['format1'] as String? ?? '',
        format2: j?['format2'] as String? ?? '',
        postils: (j?['postils'] as List? ?? const []).map((e) => '$e').toList(),
      );
}

class Shortcut {
  final int keyNo;
  final int layer;
  final String itemId;
  final String itemName;
  final int plu;

  const Shortcut({required this.keyNo, required this.layer, required this.itemId, this.itemName = '', this.plu = 0});

  factory Shortcut.fromJson(Map<String, dynamic> j) {
    final item = j['item'] as Map<String, dynamic>?;
    return Shortcut(
      keyNo: toInt(j['keyNo']),
      layer: toInt(j['layer']),
      itemId: j['itemId'] as String,
      itemName: item?['name'] as String? ?? '',
      plu: toInt(item?['plu']),
    );
  }
}
