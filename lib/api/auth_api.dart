import 'base_api.dart';

class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  /// POST /auth/login
  /// body: {"login": string, "password": string}
  /// Returns decoded JSON map with token and user/site info.
  Future<Map<String, dynamic>> login({required String login, required String password}) async {
    final res = await _client.post('/auth/login', body: {
      'login': login,
      'password': password,
    });
    return (res as Map).cast<String, dynamic>();
  }

  /// GET /auth/logout
  Future<Map<String, dynamic>> logout() async {
    final res = await _client.get('/auth/logout');
    return (res as Map).cast<String, dynamic>();
  }
}
