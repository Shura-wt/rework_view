import '../models/models.dart';
import 'base_api.dart';

class UsersApi {
  final ApiClient _client;
  UsersApi(this._client);

  Future<List<User>> list() async {
    final res = await _client.get('/users/');
    final list = (res as List)
        .map((e) => User.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
    return list;
  }

  Future<User> getById(int userId) async {
    final res = await _client.get('/users/$userId');
    return User.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<User> create({required String login, required String password, Map<String, dynamic>? extra}) async {
    final body = {'login': login, 'password': password, ...?extra};
    final res = await _client.post('/users/', body: body);
    return User.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<User> update(int userId, Map<String, dynamic> fields) async {
    final res = await _client.put('/users/$userId', body: fields);
    return User.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<Map<String, dynamic>> deleteUser(int userId) async {
    final res = await _client.delete('/users/$userId');
    return (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createWithRelations({
    required Map<String, dynamic> user,
    required List<Map<String, dynamic>> relations,
  }) async {
    final res = await _client.post('/users/create-with-relations', body: {
      'user': user,
      'relations': relations,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateWithRelations(int userId, {
    required Map<String, dynamic> user,
    required List<Map<String, dynamic>> relations,
  }) async {
    final res = await _client.put('/users/$userId/update-with-relations', body: {
      'user': user,
      'relations': relations,
    });
    return (res as Map).cast<String, dynamic>();
  }
}
