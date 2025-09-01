import '../json_utils.dart';
import '../map/carte.dart';
import 'baes.dart';

class Etage {
  final int id;
  final String name;
  final Carte carte;
  final List<Baes> baes;

  Etage({
    required this.id,
    required this.name,
    required this.carte,
    required this.baes,
  });

  factory Etage.fromJson(Map<String, dynamic> json) => Etage(
        id: asInt(json['id']) ?? 0,
        name: asString(json['name']) ?? '',
        carte: Carte.fromJson(asMap(json['carte'])),
        baes: asList(json['baes']).map((e) => Baes.fromJson(asMap(e))).toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'carte': carte.toJson(),
        'baes': baes.map((e) => e.toJson()).toList(growable: false),
      };
}
