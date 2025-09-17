import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../api/api.dart';
import '../models/domain/config.dart';

class SessionManager {
  static const _kTokenKey = 'auth_token';
  static const _kSelectedSiteKey = 'selected_site_id';
  static final SessionManager instance = SessionManager._internal();

  late final ApiClient client;
  String? _token;

  // Site sélectionné globalement (persisté)
  int? _selectedSiteId;
  // Notifie les listeners lorsqu'un site est sélectionné/désélectionné
  final ValueNotifier<int?> selectedSiteIdNotifier = ValueNotifier<int?>(null);

  int? get selectedSiteId => _selectedSiteId;
  set selectedSiteId(int? value) {
    _selectedSiteId = value;
    selectedSiteIdNotifier.value = value;
    // Persist asynchronously (fire-and-forget)
    _saveSelectedSiteId(value);
  }

  // Base URL centralisée via Config
  String baseUrl = Config.baseUrl;

  SessionManager._internal() {
    client = ApiClient(baseUrl: baseUrl);
  }

  bool get isAuthenticated => (_token != null && _token!.isNotEmpty);
  String? get token => _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kTokenKey);
    client.token = _token;

    // Charger la sélection de site persistée
    final persistedSid = prefs.getInt(_kSelectedSiteKey);
    _selectedSiteId = persistedSid;
    selectedSiteIdNotifier.value = persistedSid;
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
      await _saveToken(null);
      // Clear selected site on logout
      await _saveSelectedSiteId(null);
      _selectedSiteId = null;
      selectedSiteIdNotifier.value = null;
    } on Object {
      // Clear locally even if server failed, then rethrow so UI can inform the user
      await _saveToken(null);
      await _saveSelectedSiteId(null);
      _selectedSiteId = null;
      selectedSiteIdNotifier.value = null;
      rethrow;
    }
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

  Future<void> _saveSelectedSiteId(int? siteId) async {
    final prefs = await SharedPreferences.getInstance();
    if (siteId == null) {
      await prefs.remove(_kSelectedSiteKey);
    } else {
      await prefs.setInt(_kSelectedSiteKey, siteId);
    }
  }
}