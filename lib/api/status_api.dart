import '../models/models.dart';
import 'base_api.dart';

class StatusApi {
  final ApiClient _client;
  StatusApi(this._client);

  List<BaeStatus> _toStatusList(dynamic res) {
    if (res == null) return const <BaeStatus>[];
    if (res is List) {
      return res
          .where((e) => e is Map)
          .map((e) => BaeStatus.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
    }
    if (res is Map) {
      final map = (res).cast<String, dynamic>();
      // Common wrappers
      for (final key in const ['data', 'items', 'results', 'statuses', 'list']) {
        final v = map[key];
        if (v is List) {
          return v
              .where((e) => e is Map)
              .map((e) => BaeStatus.fromJson((e as Map).cast<String, dynamic>()))
              .toList(growable: false);
        }
      }
      // Single object fallback
      return [BaeStatus.fromJson(map)];
    }
    return const <BaeStatus>[];
  }

  // GET /status/
  Future<List<BaeStatus>> list() async {
    final res = await _client.get('/status/');
    return _toStatusList(res);
  }

  // GET /status/{status_id}
  Future<BaeStatus> getById(int statusId) async {
    final res = await _client.get('/status/$statusId');
    return BaeStatus.fromJson((res as Map).cast<String, dynamic>());
  }

  // GET /status/after/{updated_at}
  Future<List<BaeStatus>> listAfter(DateTime updatedAt) async {
    // IMPORTANT: our parser adds +02h for display. Compensate it here before sending to API (UTC+00 expected).
    final corrected = updatedAt.subtract(const Duration(hours: 2));
    final iso = corrected.toUtc().toIso8601String();
    final res = await _client.get('/status/after/$iso');
    return _toStatusList(res);
  }

  // GET /status/baes/{baes_id}
  Future<List<BaeStatus>> byBaes(int baesId) async {
    final res = await _client.get('/status/baes/$baesId');
    return _toStatusList(res);
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
    return _toStatusList(res);
  }

  // GET /status/etage/{etage_id}
  Future<List<BaeStatus>> byEtage(int etageId) async {
    final res = await _client.get('/status/etage/$etageId');
    return _toStatusList(res);
  }

  // GET /status/latest
  Future<List<BaeStatus>> latest() async {
    final res = await _client.get('/status/latest');
    return _toStatusList(res);
  }

  // DELETE /status/{status_id}
  Future<Map<String, dynamic>> deleteStatus(int statusId) async {
    final res = await _client.delete('/status/$statusId');
    return (res as Map).cast<String, dynamic>();
  }

  // GET /status/user/{user_id}
  Future<List<BaeStatus>> byUser(int userId) async {
    final res = await _client.get('/status/user/$userId');
    return _toStatusList(res);
  }
}
