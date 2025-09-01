import '../models/models.dart';
import 'base_api.dart';

class BatimentsApi {
  final ApiClient _client;
  BatimentsApi(this._client);

  Future<List<Batiment>> list() async {
    final res = await _client.get('/batiments/');
    return (res as List)
        .map((e) => Batiment.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<Batiment> getById(int batimentId) async {
    final res = await _client.get('/batiments/$batimentId');
    return Batiment.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<Batiment> create({required String name, PolygonPoints? polygonPoints, int? siteId}) async {
    final body = <String, dynamic>{'name': name};
    if (polygonPoints != null) body['polygon_points'] = polygonPoints.toJson();
    if (siteId != null) body['site_id'] = siteId;
    final res = await _client.post('/batiments/', body: body);
    return Batiment.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<Batiment> update(int batimentId, {String? name, PolygonPoints? polygonPoints, int? siteId}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (polygonPoints != null) body['polygon_points'] = polygonPoints.toJson();
    // site_id can be integer or null according to API
    if (siteId != null) {
      body['site_id'] = siteId;
    } else if (siteId == null) {
      // Caller can explicitly pass null by providing siteId = null via a separate method if needed
    }
    final res = await _client.put('/batiments/$batimentId', body: body);
    return Batiment.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<Map<String, dynamic>> deleteBatiment(int batimentId) async {
    final res = await _client.delete('/batiments/$batimentId');
    return (res as Map).cast<String, dynamic>();
  }

  Future<List<EtageLite>> getFloors(int batimentId) async {
    final res = await _client.get('/batiments/$batimentId/floors');
    return (res as List)
        .map((e) => EtageLite.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }
}
