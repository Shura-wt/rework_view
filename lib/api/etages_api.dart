import '../models/models.dart';
import 'base_api.dart';

class EtagesApi {
  final ApiClient _client;
  EtagesApi(this._client);

  Future<List<EtageLite>> list() async {
    final res = await _client.get('/etages/');
    return (res as List)
        .map((e) => EtageLite.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<EtageLite> getById(int etageId) async {
    final res = await _client.get('/etages/$etageId');
    return EtageLite.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<EtageLite> create({required String name, required int batimentId}) async {
    final res = await _client.post('/etages/', body: {
      'name': name,
      'batiment_id': batimentId,
    });
    return EtageLite.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<EtageLite> update(int etageId, {String? name}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    final res = await _client.put('/etages/$etageId', body: body);
    return EtageLite.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<Map<String, dynamic>> deleteEtage(int etageId) async {
    final res = await _client.delete('/etages/$etageId');
    return (res as Map).cast<String, dynamic>();
  }

  Future<List<Baes>> getBaes(int etageId) async {
    final res = await _client.get('/etages/$etageId/baes');
    return (res as List)
        .map((e) => Baes.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }
}
