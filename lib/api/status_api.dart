import '../models/models.dart';
import 'base_api.dart';

class StatusApi {
  final ApiClient _client;
  StatusApi(this._client);

  // GET /status/
  Future<List<BaeStatus>> list() async {
    final res = await _client.get('/status/');
    return (res as List)
        .map((e) => BaeStatus.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  // GET /status/{status_id}
  Future<BaeStatus> getById(int statusId) async {
    final res = await _client.get('/status/$statusId');
    return BaeStatus.fromJson((res as Map).cast<String, dynamic>());
  }

  // GET /status/after/{updated_at}
  Future<List<BaeStatus>> listAfter(DateTime updatedAt) async {
    final iso = updatedAt.toUtc().toIso8601String();
    final res = await _client.get('/status/after/$iso');
    return (res as List)
        .map((e) => BaeStatus.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  // GET /status/baes/{baes_id}
  Future<List<BaeStatus>> byBaes(int baesId) async {
    final res = await _client.get('/status/baes/$baesId');
    return (res as List)
        .map((e) => BaeStatus.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  // POST /status/
  Future<BaeStatus> create({
    required int baesId,
    required int erreur,
    num? temperature,
    bool? vibration,
    DateTime? timestamp,
  }) async {
    final body = <String, dynamic>{
      'baes_id': baesId,
      'erreur': erreur,
      if (temperature != null) 'temperature': temperature,
      if (vibration != null) 'vibration': vibration,
      if (timestamp != null) 'timestamp': timestamp.toUtc().toIso8601String(),
    };
    final res = await _client.post('/status/', body: body);
    return BaeStatus.fromJson((res as Map).cast<String, dynamic>());
  }

  // PUT /status/{status_id}/status
  Future<BaeStatus> updateStatus(int statusId, {
    bool? isSolved,
    bool? isIgnored,
    int? acknowledgedByUserId,
    DateTime? acknowledgedAt,
  }) async {
    final body = <String, dynamic>{
      if (isSolved != null) 'is_solved': isSolved,
      if (isIgnored != null) 'is_ignored': isIgnored,
      'acknowledged_by_user_id': acknowledgedByUserId,
      'acknowledged_at': acknowledgedAt?.toUtc().toIso8601String(),
    };
    final res = await _client.put('/status/$statusId/status', body: body);
    return BaeStatus.fromJson((res as Map).cast<String, dynamic>());
  }

  // PUT /status/baes/{baes_id}/type/{_erreur}
  Future<BaeStatus> updateBaesType(int baesId, int erreur, {bool? isSolved, bool? isIgnored}) async {
    final body = <String, dynamic>{
      if (isSolved != null) 'is_solved': isSolved,
      if (isIgnored != null) 'is_ignored': isIgnored,
    };
    final res = await _client.put('/status/baes/$baesId/type/$erreur', body: body);
    return BaeStatus.fromJson((res as Map).cast<String, dynamic>());
  }

  // GET /status/acknowledged
  Future<List<BaeStatus>> acknowledged() async {
    final res = await _client.get('/status/acknowledged');
    return (res as List)
        .map((e) => BaeStatus.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  // GET /status/etage/{etage_id}
  Future<List<BaeStatus>> byEtage(int etageId) async {
    final res = await _client.get('/status/etage/$etageId');
    return (res as List)
        .map((e) => BaeStatus.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  // GET /status/latest
  Future<List<BaeStatus>> latest() async {
    final res = await _client.get('/status/latest');
    return (res as List)
        .map((e) => BaeStatus.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  // DELETE /status/{status_id}
  Future<Map<String, dynamic>> deleteStatus(int statusId) async {
    final res = await _client.delete('/status/$statusId');
    return (res as Map).cast<String, dynamic>();
  }

  // GET /status/user/{user_id}
  Future<List<BaeStatus>> byUser(int userId) async {
    final res = await _client.get('/status/user/$userId');
    return (res as List)
        .map((e) => BaeStatus.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }
}
