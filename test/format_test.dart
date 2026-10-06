import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:metroscales/core/utils/format.dart';
import 'package:metroscales/models/scale.dart';
import 'package:metroscales/models/item.dart';

void main() {
  setUpAll(() => initializeDateFormatting('en_IN'));

  test('money uses rupees and Indian grouping', () {
    expect(money(123456.5), '₹1,23,456.50');
    expect(moneyCompact(250), '₹250');
    expect(moneyCompact(250.5), '₹250.50');
  });

  test('quantities drop trailing zeros and show the unit', () {
    expect(qtyWithUnit(0.25, 'KG'), '0.25 kg');
    expect(qtyWithUnit(2, 'PACK'), '2 pack');
  });

  test('MAC addresses are shown with colons', () {
    expect(formatMac('0023f01a9740'), '00:23:F0:1A:97:40');
    expect(formatMac('bad'), 'bad');
  });

  test('initials', () {
    expect(initials('Counter Staff'), 'CS');
    expect(initials('admin'), 'A');
  });

  test('a scale counts waiting commands from recent history', () {
    final s = Scale.fromJson({
      'id': '1',
      'mac': '0023F01A9740',
      'name': 'Y201',
      'number': 1,
      'online': false,
      'recentCommands': [
        {'id': 'a', 'type': 'PUSH_ITEMS', 'status': 'PENDING'},
        {'id': 'b', 'type': 'SET_WIFI', 'status': 'DONE'},
      ],
    });
    expect(s.title, 'Y201 (1)');
    expect(s.pendingCommands, 1);
    expect(s.recentCommands.first.label, 'Send items and prices');
  });

  test('items read the branch price, falling back to the default price', () {
    final withBranch = Item.fromJson({'id': '1', 'plu': 4, 'name': 'Thakkali', 'defaultPrice': 30, 'price': 32});
    final without = Item.fromJson({'id': '2', 'plu': 5, 'name': 'Payar', 'defaultPrice': 40});
    expect(withBranch.price, 32);
    expect(without.price, 40);
  });
}
