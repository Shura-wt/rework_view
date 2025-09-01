// Null-safety ON — helpers de conversion robustes, sans dépendances externes
List<dynamic> asList(Object? v) => (v is List) ? v : const <dynamic>[];
Map<String, dynamic> asMap(Object? v) => (v is Map)
    ? v.cast<String, dynamic>()
    : <String, dynamic>{};
String? asString(Object? v) => (v == null) ? null : v.toString();
int? asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}
double? asDouble(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
num? asNum(Object? v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}
bool? asBool(Object? v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase().trim();
  if (s == 'true' || s == 'yes' || s == '1') return true;
  if (s == 'false' || s == 'no' || s == '0') return false;
  return null;
}
DateTime? asDateTime(Object? v) {
  if (v == null) return null;
  if (v is DateTime) {
    // Convert received UTC time to UTC+02 (France) as required.
    return v.add(const Duration(hours: 2));
  }
  final parsed = DateTime.tryParse(v.toString());
  if (parsed == null) return null;
  return parsed.add(const Duration(hours: 2));
}
