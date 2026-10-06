import 'json.dart';

class Category {
  final String id;
  final int code;
  final String name;
  final int itemCount;

  const Category({required this.id, required this.code, required this.name, this.itemCount = 0});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        code: toInt(j['code']),
        name: j['name'] as String? ?? '',
        itemCount: toInt((j['_count'] as Map<String, dynamic>?)?['items']),
      );
}

/// An item (PLU) with the price and stock of the selected branch.
class Item {
  final String id;
  final int plu;
  final String name;
  final String? barcode;
  final int tareGrams;
  final String unit; // KG or PACK
  final double gstPercent;
  final String gstMode; // INCLUDED or EXCLUDED
  final String? categoryId;
  final String? categoryName;
  final double defaultPrice;
  final double price;
  final double stock;

  const Item({
    required this.id,
    required this.plu,
    required this.name,
    this.barcode,
    this.tareGrams = 0,
    this.unit = 'KG',
    this.gstPercent = 0,
    this.gstMode = 'INCLUDED',
    this.categoryId,
    this.categoryName,
    this.defaultPrice = 0,
    this.price = 0,
    this.stock = 0,
  });

  bool get isPack => unit == 'PACK';

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] as String,
        plu: toInt(j['plu']),
        name: j['name'] as String? ?? '',
        barcode: str(j['barcode']),
        tareGrams: toInt(j['tareGrams']),
        unit: j['unit'] as String? ?? 'KG',
        gstPercent: toDouble(j['gstPercent']),
        gstMode: j['gstMode'] as String? ?? 'INCLUDED',
        categoryId: str(j['categoryId']),
        categoryName: (j['category'] as Map<String, dynamic>?)?['name'] as String?,
        defaultPrice: toDouble(j['defaultPrice']),
        price: toDouble(j['price'] ?? j['defaultPrice']),
        stock: toDouble(j['stock']),
      );
}
