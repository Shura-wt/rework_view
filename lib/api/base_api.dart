import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic body;
  ApiException(this.message, {this.statusCode, this.body});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  String baseUrl;
  String? _token;
  Duration timeout;

  ApiClient({required this.baseUrl, String? token, this.timeout = const Duration(seconds: 20)})
      : _token = token;

  set token(String? value) => _token = value;
  String? get token => _token;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse(baseUrl + normalized).replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v?.toString())),
    );
  }

  Map<String, String> _headers({Map<String, String>? extra, bool isJson = true}) {
    final h = <String, String>{};
    if (isJson) h['Content-Type'] = 'application/json';
    if (_token != null && _token!.isNotEmpty) h['Authorization'] = 'Bearer $_token';
    if (extra != null) h.addAll(extra);
    return h;
  }

  Future<dynamic> _decode(http.Response res) async {
    final code = res.statusCode;
    if (code >= 200 && code < 300) {
      if (res.body.isEmpty) return null;
      final contentType = res.headers['content-type'] ?? '';
      if (contentType.contains('application/json')) {
        return jsonDecode(res.body);
      }
      return res.bodyBytes;
    }
    dynamic body;
    try {
      body = jsonDecode(res.body);
    } catch (_) {
      body = res.body;
    }
    throw ApiException('HTTP $code', statusCode: code, body: body);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, Map<String, String>? headers}) async {
    final res = await http.get(_uri(path, query), headers: _headers(extra: headers)).timeout(timeout);
    return _decode(res);
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? query, Map<String, String>? headers}) async {
    final res = await http.delete(_uri(path, query), headers: _headers(extra: headers)).timeout(timeout);
    return _decode(res);
  }

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query, Map<String, String>? headers}) async {
    final res = await http
        .post(_uri(path, query), headers: _headers(extra: headers), body: body is String ? body : jsonEncode(body))
        .timeout(timeout);
    return _decode(res);
  }

  Future<dynamic> put(String path, {Object? body, Map<String, dynamic>? query, Map<String, String>? headers}) async {
    final res = await http
        .put(_uri(path, query), headers: _headers(extra: headers), body: body is String ? body : jsonEncode(body))
        .timeout(timeout);
    return _decode(res);
  }

  Future<dynamic> patch(String path, {Object? body, Map<String, dynamic>? query, Map<String, String>? headers}) async {
    final res = await http
        .patch(_uri(path, query), headers: _headers(extra: headers), body: body is String ? body : jsonEncode(body))
        .timeout(timeout);
    return _decode(res);
  }

  Future<dynamic> multipart(String path, {
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path, query));
    request.headers.addAll(_headers(extra: headers, isJson: false));
    if (fields != null) request.fields.addAll(fields);
    request.files.addAll(files);
    final streamed = await request.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }
}
