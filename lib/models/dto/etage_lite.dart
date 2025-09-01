import '../json_utils.dart';

class EtageLite {
  final int id;
  final String name;
  final int batimentId;
  EtageLite({required this.id, required this.name, required this.batimentId});
  factory EtageLite.fromJson(Map<String, dynamic> json) => EtageLite(
        id: asInt(json['id']) ?? 0,
        name: asString(json['name']) ?? '',
        batimentId: asInt(json['batiment_id']) ?? 0,
      );
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'batiment_id': batimentId};
}
