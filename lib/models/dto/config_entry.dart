import '../json_utils.dart';

class ConfigEntry {
  final int id;
  final String key;
  final String value;
  ConfigEntry({required this.id, required this.key, required this.value});
  factory ConfigEntry.fromJson(Map<String, dynamic> json) => ConfigEntry(
        id: asInt(json['id']) ?? 0,
        key: asString(json['key']) ?? '',
        value: asString(json['value']) ?? '',
      );
  Map<String, dynamic> toJson() => {'id': id, 'key': key, 'value': value};
}
