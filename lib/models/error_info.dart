import 'package:flutter/material.dart';

class ErrorInfo {
  final String name;
  final IconData icon;
  const ErrorInfo(this.name, this.icon);
}

class StatusErrorVisuals {
  // Map code erreur -> info (nom + icône)
  static const Map<int, ErrorInfo> errorCode = {
    0: ErrorInfo("Erreur de connexion", Icons.wifi),
    4: ErrorInfo("Erreur batterie", Icons.battery_alert),
    6: ErrorInfo("Ok", Icons.check_circle),
    // ajoutez d'autres codes ici avec l'IconData souhaitée
  };

  static const ErrorInfo unknown = ErrorInfo("Inconnu", Icons.help_outline);

  static ErrorInfo infoFor(int? code) {
    if (code == null) return unknown;
    return errorCode[code] ?? unknown;
  }
}