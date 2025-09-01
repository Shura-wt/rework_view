import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';

class SessionManager {
  static const _kTokenKey = 'auth_token';
  static final SessionManager instance = SessionManager._internal();

  late final ApiClient client;
  String? _token;

  // You can change this to match your backend URL.
  String baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000');

  SessionManager._internal() {
    client = ApiClient(baseUrl: baseUrl);
  }

  bool get isAuthenticated => (_token != null && _token!.isNotEmpty);
  String? get token => _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kTokenKey);
    client.token = _token;
  }

  Future<Map<String, dynamic>> login({required String login, required String password}) async {
    final auth = AuthApi(client);
    final res = await auth.login(login: login, password: password);
    final token = res['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await _saveToken(token);
    }
    return res;
  }

  Future<void> logout() async {
    try {
      await AuthApi(client).logout();
    } catch (_) {
      // Ignore network errors on logout; still clear locally
    }
    await _saveToken(null);
  }

  Future<void> _saveToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token;
    client.token = token;
    if (token == null || token.isEmpty) {
      await prefs.remove(_kTokenKey);
    } else {
      await prefs.setString(_kTokenKey, token);
    }
  }
}