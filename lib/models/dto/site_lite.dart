import '../json_utils.dart';

class SiteLite {
  final int id;
  final String name;
  SiteLite({required this.id, required this.name});
  factory SiteLite.fromJson(Map<String, dynamic> json) => SiteLite(
        id: asInt(json['id']) ?? 0,
        name: asString(json['name']) ?? '',
      );
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
