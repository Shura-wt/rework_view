import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'base_api.dart';

class UserSiteRoleApi {
  final ApiClient _client;
  UserSiteRoleApi(this._client);

  // CRUD on /user_site_role
  Future<List<Relation>> list() async {
    final res = await _client.get('/user_site_role');
    return (res as List)
        .map((e) => Relation.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<Relation> getById(int id) async {
    final res = await _client.get('/user_site_role/$id');
    return Relation.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<Relation> create({required int userId, int? siteId, required int roleId}) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'site_id': siteId,
      'role_id': roleId,
    };
    debugPrint('[DEBUG] UserSiteRoleApi.create(userId=$userId, siteId=$siteId, roleId=$roleId)');
    final res = await _client.post('/user_site_role', body: body);
    final rel = Relation.fromJson((res as Map).cast<String, dynamic>());
    debugPrint('[DEBUG] UserSiteRoleApi.create -> id=${rel.id}, roleId=${rel.roleId}, siteId=${rel.siteId}, userId=${rel.userId}');
    return rel;
  }

  Future<Relation> update(int id, Map<String, dynamic> fields) async {
    debugPrint('[DEBUG] UserSiteRoleApi.update(id=$id, fields=$fields)');
    final res = await _client.put('/user_site_role/$id', body: fields);
    final rel = Relation.fromJson((res as Map).cast<String, dynamic>());
    debugPrint('[DEBUG] UserSiteRoleApi.update -> id=${rel.id}, roleId=${rel.roleId}, siteId=${rel.siteId}, userId=${rel.userId}');
    return rel;
  }

  Future<Map<String, dynamic>> deleteRelation(int id) async {
    debugPrint('[DEBUG] UserSiteRoleApi.deleteRelation(id=$id)');
    final res = await _client.delete('/user_site_role/$id');
    final map = (res as Map).cast<String, dynamic>();
    debugPrint('[DEBUG] UserSiteRoleApi.deleteRelation -> $map');
    return map;
  }

  // GET /user_site_role/user/{user_id}/permissions
  Future<Map<String, dynamic>> userPermissions(int userId) async {
    final res = await _client.get('/user_site_role/user/$userId/permissions');
    return (res as Map).cast<String, dynamic>();
  }

  // GET /user_site_role/site/{site_id}/users
  Future<List<Map<String, dynamic>>> siteUsers(int siteId) async {
    final res = await _client.get('/user_site_role/site/$siteId/users');

    if (res is List) {
      return res
          .where((e) => e is Map)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList(growable: false);
    }

    if (res is Map) {
      final map = (res).cast<String, dynamic>();
      final candidates = map['users'] ?? map['data'] ?? map['results'] ?? map['list'] ?? map['items'];
      if (candidates is List) {
        return candidates
            .where((e) => e is Map)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList(growable: false);
      }
      return [map];
    }

    return const [];
  }

  // DELETE /user_site_role/user/{user_id}/site/{site_id}
  Future<Map<String, dynamic>> deleteUserSite(int userId, int siteId) async {
    debugPrint('[DEBUG] UserSiteRoleApi.deleteUserSite(userId=$userId, siteId=$siteId)');
    final res = await _client.delete('/user_site_role/user/$userId/site/$siteId');
    final map = (res as Map).cast<String, dynamic>();
    debugPrint('[DEBUG] UserSiteRoleApi.deleteUserSite -> $map');
    return map;
  }

  // POST /user_site_role/user/{user_id}/global-role
  Future<Map<String, dynamic>> assignGlobalRole(int userId, int roleId) async {
    debugPrint('[DEBUG] UserSiteRoleApi.assignGlobalRole(userId=$userId, roleId=$roleId)');
    final res = await _client.post('/user_site_role/user/$userId/global-role', body: {'role_id': roleId});
    final map = (res as Map).cast<String, dynamic>();
    debugPrint('[DEBUG] UserSiteRoleApi.assignGlobalRole -> $map');
    return map;
  }
}
