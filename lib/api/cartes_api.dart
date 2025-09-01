import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'base_api.dart';

class CartesApi {
  final ApiClient _client;
  CartesApi(this._client);

  // POST /cartes/upload-carte (multipart)
  Future<Carte> uploadCarte({
    required String filePath,
    double? centerLat,
    double? centerLng,
    int? zoom,
    int? siteId,
    int? etageId,
    String? filename,
  }) async {
    final files = <http.MultipartFile>[
      await http.MultipartFile.fromPath('file', filePath, filename: filename),
    ];
    final fields = <String, String>{
      if (centerLat != null) 'center_lat': centerLat.toString(),
      if (centerLng != null) 'center_lng': centerLng.toString(),
      if (zoom != null) 'zoom': zoom.toString(),
      if (siteId != null) 'site_id': siteId.toString(),
      if (etageId != null) 'etage_id': etageId.toString(),
    };
    final res = await _client.multipart('/cartes/upload-carte', files: files, fields: fields);
    return Carte.fromJson((res as Map).cast<String, dynamic>());
  }

  // GET /cartes/uploads/{filename}
  Future<List<int>> getUploadedBytes(String filename) async {
    final res = await _client.get('/cartes/uploads/$filename');
    return (res as List<int>);
  }

  // GET /cartes/carte/{carte_id}
  Future<Carte> getCarte(int carteId) async {
    final res = await _client.get('/cartes/carte/$carteId');
    return Carte.fromJson((res as Map).cast<String, dynamic>());
  }

  // PUT /cartes/carte/{carte_id}
  Future<Carte> updateCarte(int carteId, {double? centerLat, double? centerLng, int? zoom, int? siteId, int? etageId}) async {
    final body = <String, dynamic>{
      if (centerLat != null) 'center_lat': centerLat,
      if (centerLng != null) 'center_lng': centerLng,
      if (zoom != null) 'zoom': zoom,
      'site_id': siteId,
      'etage_id': etageId,
    };
    final res = await _client.put('/cartes/carte/$carteId', body: body);
    return Carte.fromJson((res as Map).cast<String, dynamic>());
  }

  // Site carte endpoints
  Future<Carte> assignSiteCarte(int siteId, {String? chemin, double? centerLat, double? centerLng, int? zoom}) async {
    final body = <String, dynamic>{
      if (chemin != null) 'chemin': chemin,
      if (centerLat != null) 'center_lat': centerLat,
      if (centerLng != null) 'center_lng': centerLng,
      if (zoom != null) 'zoom': zoom,
    };
    final res = await _client.post('/sites/carte/$siteId/assign', body: body);
    final map = (res as Map).cast<String, dynamic>();
    return Carte.fromJson(asMap(map['carte']));
  }

  Future<Carte> getBySite(int siteId) async {
    final res = await _client.get('/sites/carte/get_by_site/$siteId');
    final map = (res as Map).cast<String, dynamic>();
    return Carte.fromJson(asMap(map['carte']));
  }

  Future<Carte> getByFloor(int floorId) async {
    final res = await _client.get('/sites/carte/get_by_floor/$floorId');
    final map = (res as Map).cast<String, dynamic>();
    return Carte.fromJson(asMap(map['carte']));
  }

  Future<Carte> updateBySite(int siteId, {double? centerLat, double? centerLng, int? zoom}) async {
    final body = <String, dynamic>{
      if (centerLat != null) 'center_lat': centerLat,
      if (centerLng != null) 'center_lng': centerLng,
      if (zoom != null) 'zoom': zoom,
    };
    final res = await _client.put('/sites/carte/update_by_site/$siteId', body: body);
    final map = (res as Map).cast<String, dynamic>();
    return Carte.fromJson(asMap(map['carte']));
  }

  // Etage carte endpoints
  Future<Carte> assignEtageCarte(int etageId, {String? chemin, double? centerLat, double? centerLng, int? zoom}) async {
    final body = <String, dynamic>{
      if (chemin != null) 'chemin': chemin,
      if (centerLat != null) 'center_lat': centerLat,
      if (centerLng != null) 'center_lng': centerLng,
      if (zoom != null) 'zoom': zoom,
    };
    final res = await _client.post('/etages/carte/$etageId/assign', body: body);
    final map = (res as Map).cast<String, dynamic>();
    return Carte.fromJson(asMap(map['carte']));
  }

  Future<Carte> updateBySiteEtage(int siteId, int etageId, {double? centerLat, double? centerLng, int? zoom}) async {
    final body = <String, dynamic>{
      if (centerLat != null) 'center_lat': centerLat,
      if (centerLng != null) 'center_lng': centerLng,
      if (zoom != null) 'zoom': zoom,
    };
    final res = await _client.put('/etages/carte/update_by_site_etage/$siteId/$etageId', body: body);
    final map = (res as Map).cast<String, dynamic>();
    return Carte.fromJson(asMap(map['carte']));
  }
}
