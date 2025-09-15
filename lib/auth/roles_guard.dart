import 'package:flutter/material.dart';

import '../api/users_api.dart';
import '../auth/session.dart';

// Rôles disponibles dans l'application côté UI
// Remarque: on accepte aussi les variantes avec tirets/majuscules depuis l'API
enum AppRole { user, technicien, admin, superAdmin }

String _normalizeRole(String raw) {
  return raw.toLowerCase().replaceAll('-', '').replaceAll('_', '').trim();
}

AppRole? _mapToAppRole(String raw) {
  final norm = _normalizeRole(raw);
  switch (norm) {
    case 'user':
      return AppRole.user;
    case 'technicien':
    case 'technician': // tolérance orthographe EN éventuelle
      return AppRole.technicien;
    case 'admin':
      return AppRole.admin;
    case 'superadmin':
      return AppRole.superAdmin;
  }
  return null;
}

/// Utilitaires rôle côté UI
class RoleUtils {
  /// Normalise une liste brute (depuis l'API) en Set<AppRole>
  static Set<AppRole> normalizeAll(Iterable<String> rawRoles) {
    return rawRoles.map(_mapToAppRole).whereType<AppRole>().toSet();
  }

  /// Vérifie si l'utilisateur possède AU MOINS UN des rôles requis
  static bool hasAny(Iterable<String> userRoles, Iterable<AppRole> anyOf) {
    final user = normalizeAll(userRoles);
    return anyOf.any(user.contains);
  }

  /// Vérifie si l'utilisateur possède TOUS les rôles requis
  static bool hasAll(Iterable<String> userRoles, Iterable<AppRole> allOf) {
    final user = normalizeAll(userRoles);
    return allOf.every(user.contains);
  }

  /// Admin like = admin OU super-admin
  static bool isAdminLike(Iterable<String> userRoles) {
    final user = normalizeAll(userRoles);
    return user.contains(AppRole.admin) || user.contains(AppRole.superAdmin);
  }
}

/// Service simple pour récupérer/cacher les rôles du user courant
class RolesService {
  RolesService._();
  static final RolesService instance = RolesService._();

  List<String>? _cachedRawRoles;
  DateTime? _fetchedAt;
  Duration cacheTtl = const Duration(seconds: 30);

  Future<List<String>> currentRawRoles({bool forceRefresh = false}) async {
    if (!SessionManager.instance.isAuthenticated) return const [];

    final now = DateTime.now();
    if (!forceRefresh && _cachedRawRoles != null && _fetchedAt != null && now.difference(_fetchedAt!) < cacheTtl) {
      return _cachedRawRoles!;
    }

    final api = UsersApi(SessionManager.instance.client);
    try {
      final me = await api.me();
      _cachedRawRoles = me.roles;
      _fetchedAt = DateTime.now();
      return _cachedRawRoles!;
    } catch (_) {
      // En cas d'erreur on retourne le cache si dispo, sinon vide
      return _cachedRawRoles ?? const [];
    }
  }

  Future<Set<AppRole>> currentRoles({bool forceRefresh = false}) async {
    final raw = await currentRawRoles(forceRefresh: forceRefresh);
    return RoleUtils.normalizeAll(raw);
  }

  Future<bool> hasAny(Iterable<AppRole> roles) async {
    final r = await currentRoles();
    return roles.any(r.contains);
  }

  Future<bool> hasAll(Iterable<AppRole> roles) async {
    final r = await currentRoles();
    return roles.every(r.contains);
  }
}

/// Widget de garde pour masquer/afficher un fragment selon les rôles
class RoleGate extends StatelessWidget {
  final List<AppRole> anyOf; // au moins un
  final List<AppRole> allOf; // et tous (optionnel)
  final Widget child; // contenu autorisé
  final Widget? fallback; // contenu alternatif si refus
  final Widget? loading; // pendant le chargement

  const RoleGate({
    super.key,
    this.anyOf = const [],
    this.allOf = const [],
    required this.child,
    this.fallback,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    // Si aucun rôle requis => toujours afficher
    if (anyOf.isEmpty && allOf.isEmpty) return child;

    return FutureBuilder<Set<AppRole>>(
      future: RolesService.instance.currentRoles(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return loading ?? const SizedBox.shrink();
        }
        final roles = snap.data ?? const <AppRole>{};
        final allowAny = anyOf.isEmpty || anyOf.any(roles.contains);
        final allowAll = allOf.isEmpty || allOf.every(roles.contains);
        final allowed = allowAny && allowAll;
        if (allowed) return child;
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Garde de page complète (renvoie un Scaffold "Accès refusé" par défaut)
class PageGuard extends StatelessWidget {
  final List<AppRole> anyOf;
  final List<AppRole> allOf;
  final Widget child;
  final Widget? fallback; // si non autorisé

  const PageGuard({
    super.key,
    this.anyOf = const [],
    this.allOf = const [],
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return RoleGate(
      anyOf: anyOf,
      allOf: allOf,
      child: child,
      fallback: fallback ?? _defaultDenied(),
      loading: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _defaultDenied() {
    return Scaffold(
      appBar: AppBar(title: const Text('Accès refusé')),
      body: const Center(
        child: Text('Vous n\'avez pas les droits suffisants pour accéder à cette page.'),
      ),
    );
  }
}
