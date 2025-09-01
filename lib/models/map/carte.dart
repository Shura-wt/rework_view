import '../json_utils.dart';

enum CarteOwner { site, etage, unknown }

class Carte {
  final int id;
  final int? etageId;
  final int? siteId;
  final String chemin;
  final double? centerLat;
  final double? centerLng;
  final int? zoom;

  Carte({
    required this.id,
    required this.etageId,
    required this.siteId,
    required this.chemin,
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
  });

  factory Carte.fromJson(Map<String, dynamic> json) => Carte(
        id: asInt(json['id']) ?? 0,
        etageId: asInt(json['etage_id']),
        siteId: asInt(json['site_id']),
        chemin: asString(json['chemin']) ?? '',
        centerLat: asDouble(json['center_lat']),
        centerLng: asDouble(json['center_lng']),
        zoom: asInt(json['zoom']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'etage_id': etageId,
        'site_id': siteId,
        'chemin': chemin,
        'center_lat': centerLat,
        'center_lng': centerLng,
        'zoom': zoom,
      };

  CarteOwner get ownerType =>
      (etageId != null) ? CarteOwner.etage : (siteId != null) ? CarteOwner.site : CarteOwner.unknown;
}
