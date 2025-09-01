import '../json_utils.dart';
import '../geo/position.dart';
import 'bae_status.dart';

class Baes {
  final int id;
  final String name;
  final Position position;
  final List<BaeStatus> statuses;
  final int? etageId; // endpoints plats
  final String? label; // nullable
  final BaeStatus? latestStatus; // nullable

  Baes({
    required this.id,
    required this.name,
    required this.position,
    required this.statuses,
    this.etageId,
    this.label,
    this.latestStatus,
  });

  factory Baes.fromJson(Map<String, dynamic> json) => Baes(
        id: asInt(json['id']) ?? 0,
        name: asString(json['name']) ?? '',
        position: Position.fromJson(asMap(json['position'])),
        statuses: asList(json['statuses'])
            .map((e) => BaeStatus.fromJson(asMap(e)))
            .toList(growable: false),
        etageId: asInt(json['etage_id']),
        label: asString(json['label']),
        latestStatus: (asMap(json['latest_status']).isEmpty)
            ? null
            : BaeStatus.fromJson(asMap(json['latest_status'])),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'position': position.toJson(),
        'statuses': statuses.map((e) => e.toJson()).toList(growable: false),
        if (etageId != null) 'etage_id': etageId,
        if (label != null) 'label': label,
        if (latestStatus != null) 'latest_status': latestStatus!.toJson(),
      };
}
