import 'package:flutter/foundation.dart';
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

  // GET /me - utilisateur courant avec roles et sites accessibles
  Future<User> me() async {
    final res = await _client.get('/me');
    return User.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<User> create({required String login, required String password, Map<String, dynamic>? extra}) async {
    final body = {'login': login, 'password': password, ...?extra};
    debugPrint('[DEBUG] UsersApi.create(login=$login, password=<hidden>, extraKeys=${extra?.keys.toList()})');
    final res = await _client.post('/users/', body: body);
    final user = User.fromJson((res as Map).cast<String, dynamic>());
    debugPrint('[DEBUG] UsersApi.create -> id=${user.id}, login=${user.login}');
    return user;
  }

  Future<User> update(int userId, Map<String, dynamic> fields) async {
    final safe = Map<String, dynamic>.from(fields);
    if (safe.containsKey('password')) safe['password'] = '<hidden>';
    debugPrint('[DEBUG] UsersApi.update(userId=$userId, fields=$safe)');
    final res = await _client.put('/users/$userId', body: fields);
    final user = User.fromJson((res as Map).cast<String, dynamic>());
    debugPrint('[DEBUG] UsersApi.update -> id=${user.id}, login=${user.login}');
    return user;
  }

  Future<Map<String, dynamic>> deleteUser(int userId) async {
    debugPrint('[DEBUG] UsersApi.deleteUser(userId=$userId)');
    final res = await _client.delete('/users/$userId');
    final map = (res as Map).cast<String, dynamic>();
    debugPrint('[DEBUG] UsersApi.deleteUser -> $map');
    return map;
  }

  Future<Map<String, dynamic>> createWithRelations({
    required Map<String, dynamic> user,
    required List<Map<String, dynamic>> relations,
  }) async {
    final safeUser = Map<String, dynamic>.from(user);
    if (safeUser.containsKey('password')) safeUser['password'] = '<hidden>';
    debugPrint('[DEBUG] UsersApi.createWithRelations(user=$safeUser, relationsCount=${relations.length})');
    final res = await _client.post('/users/create-with-relations', body: {
      'user': user,
      'relations': relations,
    });
    final map = (res as Map).cast<String, dynamic>();
    debugPrint('[DEBUG] UsersApi.createWithRelations -> $map');
    return map;
  }

  Future<Map<String, dynamic>> updateWithRelations(int userId, {
    required Map<String, dynamic> user,
    required List<Map<String, dynamic>> relations,
  }) async {
    final safeUser = Map<String, dynamic>.from(user);
    if (safeUser.containsKey('password')) safeUser['password'] = '<hidden>';
    debugPrint('[DEBUG] UsersApi.updateWithRelations(userId=$userId, user=$safeUser, relationsCount=${relations.length})');
    final res = await _client.put('/users/$userId/update-with-relations', body: {
      'user': user,
      'relations': relations,
    });
    final map = (res as Map).cast<String, dynamic>();
    debugPrint('[DEBUG] UsersApi.updateWithRelations -> $map');
    return map;
  }
}
