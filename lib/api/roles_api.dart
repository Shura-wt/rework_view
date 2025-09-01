import '../models/models.dart';
import 'base_api.dart';

class RolesApi {
  final ApiClient _client;
  RolesApi(this._client);

  Future<Role> create(String name) async {
    final res = await _client.post('/roles/', body: {'name': name});
    return Role.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<List<Role>> list() async {
    final res = await _client.get('/roles/');
    return (res as List)
        .map((e) => Role.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> deleteRole(int id) async {
    final res = await _client.delete('/roles/$id');
    return (res as Map).cast<String, dynamic>();
  }
}
