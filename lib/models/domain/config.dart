class Config {
  final int id;
  final String key;
  final String value;

  // Static constants for known configuration keys
  static const String timeoutKey = "timeout";

  // Environnement de développement
  static const String baseUrlDev = "http://localhost:5000";

  // Environnement de production
  static const String baseUrlProd = "http://apibaes.isymap.com:5000";

  // Pour sélectionner l'environnement à utiliser, vous pouvez définir une constante :
  static const bool isProduction = false;

  // URL de base utilisée dans l'application
  static String get baseUrl => isProduction ? baseUrlProd : baseUrlDev;

  Config({
    required this.id,
    required this.key,
    required this.value,
  });

  /// Creates a Config object from a JSON map.
  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      key: (json['key'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
    );
  }

  /// Converts this Config object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
    };
  }

  /// Creates a copy of this Config with the given fields replaced with new values.
  Config copyWith({
    int? id,
    String? key,
    String? value,
  }) {
    return Config(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }
}
