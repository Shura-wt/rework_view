import '../json_utils.dart';

class Relation {
  final int id;
  final int roleId;
  final String roleName;
  final int siteId;
  final String siteName;
  final int userId;
  final String userLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  Relation({
    required this.id,
    required this.roleId,
    required this.roleName,
    required this.siteId,
    required this.siteName,
    required this.userId,
    required this.userLogin,
    this.createdAt,
    this.updatedAt,
  });
  factory Relation.fromJson(Map<String, dynamic> json) => Relation(
        id: asInt(json['id']) ?? 0,
        roleId: asInt(json['role_id']) ?? 0,
        roleName: asString(json['role_name']) ?? '',
        siteId: asInt(json['site_id']) ?? 0,
        siteName: asString(json['site_name']) ?? '',
        userId: asInt(json['user_id']) ?? 0,
        userLogin: asString(json['user_login']) ?? '',
        createdAt: asDateTime(json['created_at']),
        updatedAt: asDateTime(json['updated_at']),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'role_id': roleId,
        'role_name': roleName,
        'site_id': siteId,
        'site_name': siteName,
        'user_id': userId,
        'user_login': userLogin,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
