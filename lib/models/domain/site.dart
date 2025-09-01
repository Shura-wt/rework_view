import '../json_utils.dart';
import '../map/carte.dart';
import 'batiment.dart';

class Site {
  final int id;
  final String name;
  final Carte carte;
  final List<Batiment> batiments;

  Site({
    required this.id,
    required this.name,
    required this.carte,
    required this.batiments,
  });

  factory Site.fromJson(Map<String, dynamic> json) => Site(
        id: asInt(json['id']) ?? 0,
        name: asString(json['name']) ?? '',
        carte: Carte.fromJson(asMap(json['carte'])),
        batiments: asList(json['batiments'])
            .map((e) => Batiment.fromJson(asMap(e)))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'carte': carte.toJson(),
        'batiments': batiments.map((e) => e.toJson()).toList(growable: false),
      };
}
