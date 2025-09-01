import '../models/models.dart';
import 'base_api.dart';

class GeneralApi {
  final ApiClient _client;
  GeneralApi(this._client);

  // GET /general/user/{user_id}/alldata
  Future<ApiPayload> userAllData(int userId) async {
    final res = await _client.get('/general/user/$userId/alldata');
    return ApiPayload.fromJson((res as Map).cast<String, dynamic>());
  }

  // GET /general/batiment/{batiment_id}/alldata
  Future<Batiment> batimentAllData(int batimentId) async {
    final res = await _client.get('/general/batiment/$batimentId/alldata');
    return Batiment.fromJson((res as Map).cast<String, dynamic>());
  }

  // GET /general/version
  Future<String> version() async {
    final res = await _client.get('/general/version');
    final map = (res as Map).cast<String, dynamic>();
    return asString(map['version']) ?? '';
  }
}
