import '../json_utils.dart';

class Role {
  final int id;
  final String name;
  Role({required this.id, required this.name});
  factory Role.fromJson(Map<String, dynamic> json) => Role(
        id: asInt(json['id']) ?? 0,
        name: asString(json['name']) ?? '',
      );
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
