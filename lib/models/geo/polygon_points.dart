import '../json_utils.dart';

class PolygonPoints {
  final List<List<double>> points; // [[lat, lng], ...]
  PolygonPoints({required this.points});
  factory PolygonPoints.fromJson(Map<String, dynamic> json) {
    final raw = asList(json['points']);
    final pts = <List<double>>[];
    for (final item in raw) {
      final pair = asList(item);
      if (pair.length >= 2) {
        pts.add([asDouble(pair[0]) ?? 0.0, asDouble(pair[1]) ?? 0.0]);
      }
    }
    return PolygonPoints(points: pts);
  }
  Map<String, dynamic> toJson() => {
        'points': points.map((e) => [e[0], e[1]]).toList(growable: false),
      };
}
