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
    final res = await _client.post('/user_site_role', body: body);
    return Relation.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<Relation> update(int id, Map<String, dynamic> fields) async {
    final res = await _client.put('/user_site_role/$id', body: fields);
    return Relation.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<Map<String, dynamic>> deleteRelation(int id) async {
    final res = await _client.delete('/user_site_role/$id');
    return (res as Map).cast<String, dynamic>();
  }

  // GET /user_site_role/user/{user_id}/permissions
  Future<Map<String, dynamic>> userPermissions(int userId) async {
    final res = await _client.get('/user_site_role/user/$userId/permissions');
    return (res as Map).cast<String, dynamic>();
  }

  // GET /user_site_role/site/{site_id}/users
  Future<List<Map<String, dynamic>>> siteUsers(int siteId) async {
    final res = await _client.get('/user_site_role/site/$siteId/users');
    return (res as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList(growable: false);
  }

  // DELETE /user_site_role/user/{user_id}/site/{site_id}
  Future<Map<String, dynamic>> deleteUserSite(int userId, int siteId) async {
    final res = await _client.delete('/user_site_role/user/$userId/site/$siteId');
    return (res as Map).cast<String, dynamic>();
  }

  // POST /user_site_role/user/{user_id}/global-role
  Future<Map<String, dynamic>> assignGlobalRole(int userId, int roleId) async {
    final res = await _client.post('/user_site_role/user/$userId/global-role', body: {'role_id': roleId});
    return (res as Map).cast<String, dynamic>();
  }
}
