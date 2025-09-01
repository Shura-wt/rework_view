import '../json_utils.dart';

class Position {
  final double lat;
  final double lng;
  Position({required this.lat, required this.lng});
  factory Position.fromJson(Map<String, dynamic> json) => Position(
        lat: asDouble(json['lat']) ?? 0.0,
        lng: asDouble(json['lng']) ?? 0.0,
      );
  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}
