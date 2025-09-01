import '../json_utils.dart';
import '../geo/polygon_points.dart';
import 'etage.dart';

class Batiment {
  final int id;
  final String name;
  final PolygonPoints polygonPoints;
  final List<Etage> etages;
  final int? siteId; // pour endpoint liste de batiments

  Batiment({
    required this.id,
    required this.name,
    required this.polygonPoints,
    required this.etages,
    this.siteId,
  });

  factory Batiment.fromJson(Map<String, dynamic> json) => Batiment(
        id: asInt(json['id']) ?? 0,
        name: asString(json['name']) ?? '',
        polygonPoints: PolygonPoints.fromJson(asMap(json['polygon_points'])),
        etages: asList(json['etages']).map((e) => Etage.fromJson(asMap(e))).toList(growable: false),
        siteId: asInt(json['site_id']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'polygon_points': polygonPoints.toJson(),
        'etages': etages.map((e) => e.toJson()).toList(growable: false),
        if (siteId != null) 'site_id': siteId,
      };
}
