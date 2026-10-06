import 'json.dart';

/// Sales totals for one day.
class DaySales {
  final DateTime date;
  final int bills;
  final double total;
  final double discount;
  final double tax;

  const DaySales({required this.date, this.bills = 0, this.total = 0, this.discount = 0, this.tax = 0});

  factory DaySales.fromJson(Map<String, dynamic> j) => DaySales(
        date: DateTime.parse(j['date'] as String),
        bills: toInt(j['bills']),
        total: toDouble(j['total']),
        discount: toDouble(j['discount']),
        tax: toDouble(j['tax']),
      );
}

class Bill {
  final String id;
  final String billNo;
  final DateTime billedAt;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String? scaleName;
  final List<BillLine> lines;

  const Bill({
    required this.id,
    required this.billNo,
    required this.billedAt,
    this.subtotal = 0,
    this.discount = 0,
    this.tax = 0,
    this.total = 0,
    this.scaleName,
    this.lines = const [],
  });

  factory Bill.fromJson(Map<String, dynamic> j) {
    final scale = j['scale'] as Map<String, dynamic>?;
    return Bill(
      id: j['id'] as String,
      billNo: '${j['billNo']}',
      billedAt: toDate(j['billedAt']) ?? DateTime.now(),
      subtotal: toDouble(j['subtotal']),
      discount: toDouble(j['discount']),
      tax: toDouble(j['tax']),
      total: toDouble(j['total']),
      scaleName: scale == null ? null : '${scale['name']} (${scale['number']})',
      lines: mapList(j['lines']).map(BillLine.fromJson).toList(),
    );
  }
}

class BillLine {
  final int plu;
  final String name;
  final String unit;
  final double quantity;
  final double price;
  final double amount;

  const BillLine({
    required this.plu,
    required this.name,
    this.unit = 'KG',
    this.quantity = 0,
    this.price = 0,
    this.amount = 0,
  });

  factory BillLine.fromJson(Map<String, dynamic> j) => BillLine(
        plu: toInt(j['plu']),
        name: j['name'] as String? ?? '',
        unit: j['unit'] as String? ?? 'KG',
        quantity: toDouble(j['quantity']),
        price: toDouble(j['price']),
        amount: toDouble(j['amount']),
      );
}

/// How much of one item sold in a period.
class ItemSales {
  final int plu;
  final String name;
  final String unit;
  final int lines;
  final double quantity;
  final double amount;

  const ItemSales({
    required this.plu,
    required this.name,
    this.unit = 'KG',
    this.lines = 0,
    this.quantity = 0,
    this.amount = 0,
  });

  factory ItemSales.fromJson(Map<String, dynamic> j) => ItemSales(
        plu: toInt(j['plu']),
        name: j['name'] as String? ?? '',
        unit: j['unit'] as String? ?? 'KG',
        lines: toInt(j['lines']),
        quantity: toDouble(j['quantity']),
        amount: toDouble(j['amount']),
      );
}

class Purchase {
  final String id;
  final DateTime purchasedAt;
  final String? supplier;
  final String? invoiceNo;
  final String? note;
  final double total;
  final List<PurchaseLine> lines;

  const Purchase({
    required this.id,
    required this.purchasedAt,
    this.supplier,
    this.invoiceNo,
    this.note,
    this.total = 0,
    this.lines = const [],
  });

  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(
        id: j['id'] as String,
        purchasedAt: toDate(j['purchasedAt']) ?? DateTime.now(),
        supplier: str(j['supplier']),
        invoiceNo: str(j['invoiceNo']),
        note: str(j['note']),
        total: toDouble(j['total']),
        lines: mapList(j['lines']).map(PurchaseLine.fromJson).toList(),
      );
}

class PurchaseLine {
  final String itemId;
  final String name;
  final int plu;
  final String unit;
  final double quantity;
  final double unitCost;
  final double amount;

  const PurchaseLine({
    required this.itemId,
    required this.name,
    this.plu = 0,
    this.unit = 'KG',
    this.quantity = 0,
    this.unitCost = 0,
    this.amount = 0,
  });

  factory PurchaseLine.fromJson(Map<String, dynamic> j) {
    final item = j['item'] as Map<String, dynamic>?;
    return PurchaseLine(
      itemId: j['itemId'] as String,
      name: item?['name'] as String? ?? '',
      plu: toInt(item?['plu']),
      unit: item?['unit'] as String? ?? 'KG',
      quantity: toDouble(j['quantity']),
      unitCost: toDouble(j['unitCost']),
      amount: toDouble(j['amount']),
    );
  }
}
