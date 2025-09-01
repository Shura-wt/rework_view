import 'base_api.dart';

class UsersSitesApi {
  final ApiClient _client;
  UsersSitesApi(this._client);

  // GET /users/sites/{user_id}/sites
  Future<List<Map<String, dynamic>>> listSitesForUser(int userId) async {
    final res = await _client.get('/users/sites/$userId/sites');
    return (res as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList(growable: false);
  }

  // POST /users/sites/{user_id}/sites
  Future<Map<String, dynamic>> assignSiteToUser(int userId, {required int siteId, int? roleId}) async {
    final body = <String, dynamic>{
      'site_id': siteId,
      if (roleId != null) 'role_id': roleId,
    };
    final res = await _client.post('/users/sites/$userId/sites', body: body);
    return (res as Map).cast<String, dynamic>();
  }

  // DELETE /users/sites/{user_id}/sites/{site_id}
  Future<Map<String, dynamic>> removeSiteFromUser(int userId, int siteId) async {
    final res = await _client.delete('/users/sites/$userId/sites/$siteId');
    return (res as Map).cast<String, dynamic>();
  }
}
