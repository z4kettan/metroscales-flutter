import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Builds a CSV file and opens the phone's share sheet (WhatsApp, email,
/// Drive...). Excel opens these files directly.
Future<void> shareCsv({required String fileName, required List<List<Object?>> rows, String? subject}) async {
  final csv = rows.map((r) => r.map(_cell).join(',')).join('\r\n');
  // A byte-order mark makes Excel read the ₹ sign and Malayalam names correctly
  final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
  await SharePlus.instance.share(ShareParams(
    subject: subject,
    files: [XFile.fromData(bytes, mimeType: 'text/csv', name: fileName)],
    fileNameOverrides: [fileName],
  ));
}

String _cell(Object? v) {
  final s = v == null ? '' : '$v';
  return s.contains(RegExp(r'[",\r\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
}
