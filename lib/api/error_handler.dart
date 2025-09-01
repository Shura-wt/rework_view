import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'api.dart';

class ApiErrorHandler {
  static String messageFromError(Object error, {String? action}) {
    // Network/timeout
    if (error is TimeoutException) {
      return 'La requête a pris trop de temps. Veuillez réessayer.';
    }
    if (error is SocketException) {
      return 'Impossible de joindre le serveur. Vérifiez votre connexion internet.';
    }

    // API-level
    if (error is ApiException) {
      final code = error.statusCode ?? 0;
      switch (code) {
        case 400:
          return 'Requête invalide. Merci de vérifier les informations saisies.';
        case 401:
          // For generic actions, indicate session/auth issue
          return action == 'login'
              ? 'Identifiants de connexion incorrects.'
              : 'Session expirée ou non autorisée. Veuillez vous reconnecter.';
        case 403:
          return 'Accès refusé. Vous n’avez pas les permissions nécessaires.';
        case 404:
          return 'Ressource introuvable.';
        case 408:
          return 'La requête a expiré. Veuillez réessayer.';
        case 409:
          return 'Conflit détecté. L’opération ne peut pas être effectuée.';
        case 413:
          return 'La taille des données envoyées est trop importante.';
        case 429:
          return 'Trop de requêtes. Veuillez patienter avant de réessayer.';
        default:
          if (code >= 500 && code <= 599) {
            return 'Erreur serveur. Veuillez réessayer plus tard.';
          }
          // If backend message exists, prefer it as fallback readable text
          return error.message.isNotEmpty
              ? error.message
              : 'Une erreur est survenue. Veuillez réessayer.';
      }
    }

    // Fallback
    return 'Une erreur inattendue est survenue. Veuillez réessayer.';
  }

  static void logDebug(Object error, {String context = 'api'}) {
    if (error is ApiException) {
      debugPrint('[DEBUG_LOG] $context ApiException: code=${error.statusCode} message=${error.message} body=${error.body}');
    } else {
      debugPrint('[DEBUG_LOG] $context Unexpected error: $error');
    }
  }

  static void showSnackBar(BuildContext context, Object error, {String? action, String? fallback}) {
    final msg = fallback ?? messageFromError(error, action: action);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Convenience runner to wrap async API calls with uniform error handling.
  static Future<T?> run<T>(BuildContext context, Future<T> Function() task, {String? action, void Function(T value)? onSuccess}) async {
    try {
      final value = await task();
      if (onSuccess != null) onSuccess(value);
      return value;
    } on Object catch (e) {
      logDebug(e, context: action ?? 'api');
      showSnackBar(context, e, action: action);
      return null;
    }
  }
}
