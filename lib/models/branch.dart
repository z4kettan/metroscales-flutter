import 'json.dart';

class Branch {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final int scaleCount;
  final int onlineScaleCount;

  const Branch({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.scaleCount = 0,
    this.onlineScaleCount = 0,
  });

  factory Branch.fromJson(Map<String, dynamic> j) => Branch(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        address: str(j['address']),
        phone: str(j['phone']),
        scaleCount: toInt(j['scaleCount']),
        onlineScaleCount: toInt(j['onlineScaleCount']),
      );
}

/// What the scale prints at the top and bottom of every bill.
class BillSettings {
  final String header;
  final String billFooter;
  final String itemFooter;
  final String offerTitle;

  const BillSettings({this.header = '', this.billFooter = '', this.itemFooter = '', this.offerTitle = ''});

  factory BillSettings.fromJson(Map<String, dynamic>? j) => BillSettings(
        header: j?['header'] as String? ?? '',
        billFooter: j?['billFooter'] as String? ?? '',
        itemFooter: j?['itemFooter'] as String? ?? '',
        offerTitle: j?['offerTitle'] as String? ?? '',
      );
}
