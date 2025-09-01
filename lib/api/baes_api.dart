import '../models/models.dart';
import 'base_api.dart';

class BaesApi {
  final ApiClient _client;
  BaesApi(this._client);

  Future<List<Baes>> list() async {
    final res = await _client.get('/baes/');
    return (res as List)
        .map((e) => Baes.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<Baes> getById(int baesId) async {
    final res = await _client.get('/baes/$baesId');
    return Baes.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<Baes> create({
    required String name,
    String? label,
    Position? position,
    int? etageId,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (label != null) body['label'] = label;
    if (position != null) body['position'] = position.toJson();
    if (etageId != null) body['etage_id'] = etageId;
    final res = await _client.post('/baes/', body: body);
    return Baes.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<Baes> update(int baesId, Map<String, dynamic> fields) async {
    final res = await _client.put('/baes/$baesId', body: fields);
    return Baes.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<Map<String, dynamic>> deleteBaes(int baesId) async {
    final res = await _client.delete('/baes/$baesId');
    return (res as Map).cast<String, dynamic>();
  }

  Future<List<Baes>> withoutEtage() async {
    final res = await _client.get('/baes/without-etage');
    return (res as List)
        .map((e) => Baes.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<List<Baes>> byUser(int userId) async {
    final res = await _client.get('/baes/user/$userId');
    return (res as List)
        .map((e) => Baes.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }
}
