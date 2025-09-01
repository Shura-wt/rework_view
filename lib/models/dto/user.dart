import '../json_utils.dart';
import 'site_lite.dart';

class User {
  final int id;
  final String login;
  final List<String> roles;
  final List<SiteLite> sites;
  User({required this.id, required this.login, required this.roles, required this.sites});
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: asInt(json['id']) ?? 0,
        login: asString(json['login']) ?? '',
        roles: asList(json['roles']).map((e) => asString(e) ?? '').where((s) => s.isNotEmpty).toList(growable: false),
        sites: asList(json['sites']).map((e) => SiteLite.fromJson(asMap(e))).toList(growable: false),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'login': login,
        'roles': roles,
        'sites': sites.map((e) => e.toJson()).toList(growable: false),
      };
}
