/// Small helpers for reading API JSON safely.
double toDouble(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
int toInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
DateTime? toDate(Object? v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();
String? str(Object? v) => v == null ? null : '$v';
List<Map<String, dynamic>> mapList(Object? v) =>
    (v as List? ?? const []).cast<Map<String, dynamic>>();
