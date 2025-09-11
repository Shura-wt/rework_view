import '../models/models.dart';
import 'base_api.dart';

class SitesApi {
  final ApiClient _client;
  SitesApi(this._client);

  Future<List<SiteLite>> list() async {
    final res = await _client.get('/sites/');
    final list = (res as List)
        .map((e) => SiteLite.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
    return list;
  }

  Future<SiteLite> getById(int siteId) async {
    final res = await _client.get('/sites/$siteId');
    return SiteLite.fromJson((res as Map).cast<String, dynamic>());
  }

  // GET /sites/{site_id}/full
  Future<Site> getFull(int siteId, {String? include}) async {
    final res = await _client.get('/sites/$siteId/full', query: {
      if (include != null && include.isNotEmpty) 'include': include,
    });
    return Site.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<SiteLite> create(String name) async {
    final res = await _client.post('/sites/', body: {'name': name});
    return SiteLite.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<SiteLite> update(int siteId, {String? name}) async {
    final res = await _client.put('/sites/$siteId', body: {
      if (name != null) 'name': name,
    });
    return SiteLite.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<Map<String, dynamic>> deleteSite(int siteId) async {
    final res = await _client.delete('/sites/$siteId');
    return (res as Map).cast<String, dynamic>();
  }

  // GET /sites/{site_id}/baes/unassigned (optionnel)
  Future<List<Baes>> unassignedBaes(int siteId) async {
    final res = await _client.get('/sites/$siteId/baes/unassigned');
    return (res as List)
        .where((e) => e is Map)
        .map((e) => Baes.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }
}
