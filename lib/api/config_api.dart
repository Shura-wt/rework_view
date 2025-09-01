import '../models/models.dart';
import 'base_api.dart';

class ConfigApi {
  final ApiClient _client;
  ConfigApi(this._client);

  Future<List<ConfigEntry>> list() async {
    final res = await _client.get('/config/');
    return (res as List)
        .map((e) => ConfigEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<ConfigEntry> create({required String key, required dynamic value}) async {
    final res = await _client.post('/config/', body: {
      'key': key,
      'value': value,
    });
    return ConfigEntry.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<ConfigEntry> update(int configId, {String? key, dynamic value}) async {
    final body = <String, dynamic>{
      if (key != null) 'key': key,
      if (value != null) 'value': value,
    };
    final res = await _client.put('/config/$configId', body: body);
    return ConfigEntry.fromJson((res as Map).cast<String, dynamic>());
  }

  Future<ConfigEntry> getByKey(String key) async {
    final res = await _client.get('/config/key/$key');
    return ConfigEntry.fromJson((res as Map).cast<String, dynamic>());
  }
}
