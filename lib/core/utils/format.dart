import 'package:intl/intl.dart';

final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final _moneyShort = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _qty = NumberFormat('#,##0.###', 'en_IN');
final _day = DateFormat('d MMM yyyy');
final _dayShort = DateFormat('d MMM');
final _time = DateFormat('h:mm a');
final _iso = DateFormat('yyyy-MM-dd');

String money(num? v) => _money.format(v ?? 0);

/// Whole rupees when there are no paise, for headline figures.
String moneyCompact(num? v) {
  final n = v ?? 0;
  return n == n.roundToDouble() ? _moneyShort.format(n) : _money.format(n);
}

String qty(num? v) => _qty.format(v ?? 0);

String unitLabel(String unit) => unit == 'PACK' ? 'pack' : 'kg';

String qtyWithUnit(num? v, String unit) => '${qty(v)} ${unitLabel(unit)}';

String day(DateTime d) => _day.format(d);
String dayShort(DateTime d) => _dayShort.format(d);
String time(DateTime d) => _time.format(d.toLocal());
String isoDay(DateTime d) => _iso.format(d);
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// "Today", "Yesterday" or the date.
String friendlyDay(DateTime d) {
  final today = dateOnly(DateTime.now());
  final diff = today.difference(dateOnly(d)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return day(d);
}

/// 0023F01A9740 -> 00:23:F0:1A:97:40
String formatMac(String mac) {
  final m = mac.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
  if (m.length != 12) return mac;
  return [for (var i = 0; i < 12; i += 2) m.substring(i, i + 2)].join(':');
}

/// "just now", "5 min ago", "3 h ago", "2 days ago", or "Never".
String since(DateTime? t) {
  if (t == null) return 'Never';
  final d = DateTime.now().difference(t.toLocal());
  if (d.inSeconds < 60) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  if (d.inDays < 30) return '${d.inDays} ${d.inDays == 1 ? 'day' : 'days'} ago';
  return day(t.toLocal());
}

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
