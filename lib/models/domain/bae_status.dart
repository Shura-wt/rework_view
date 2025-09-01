import '../json_utils.dart';

class BaeStatus {
  final int id;
  final int erreur;
  final bool isIgnored;
  final bool isSolved;
  final num? temperature;
  final DateTime? timestamp;
  final bool vibration;
  // champs additionnels
  final int? baesId;
  final DateTime? updatedAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedByLogin;
  final int? acknowledgedByUserId;

  BaeStatus({
    required this.id,
    required this.erreur,
    required this.isIgnored,
    required this.isSolved,
    required this.temperature,
    required this.timestamp,
    required this.vibration,
    this.baesId,
    this.updatedAt,
    this.acknowledgedAt,
    this.acknowledgedByLogin,
    this.acknowledgedByUserId,
  });

  factory BaeStatus.fromJson(Map<String, dynamic> json) => BaeStatus(
        id: asInt(json['id']) ?? 0,
        erreur: asInt(json['erreur']) ?? 0,
        isIgnored: asBool(json['is_ignored']) ?? false,
        isSolved: asBool(json['is_solved']) ?? false,
        temperature: asNum(json['temperature']),
        timestamp: asDateTime(json['timestamp']),
        vibration: asBool(json['vibration']) ?? false,
        baesId: asInt(json['baes_id']),
        updatedAt: asDateTime(json['updated_at']),
        acknowledgedAt: asDateTime(json['acknowledged_at']),
        acknowledgedByLogin: asString(json['acknowledged_by_login']),
        acknowledgedByUserId: asInt(json['acknowledged_by_user_id']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'erreur': erreur,
        'is_ignored': isIgnored,
        'is_solved': isSolved,
        'temperature': temperature,
        'timestamp': timestamp?.toIso8601String(),
        'vibration': vibration,
        if (baesId != null) 'baes_id': baesId,
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        if (acknowledgedAt != null) 'acknowledged_at': acknowledgedAt!.toIso8601String(),
        if (acknowledgedByLogin != null) 'acknowledged_by_login': acknowledgedByLogin,
        if (acknowledgedByUserId != null) 'acknowledged_by_user_id': acknowledgedByUserId,
      };
}
