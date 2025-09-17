import 'package:flutter/material.dart';

import '../api/users_api.dart';
import '../api/user_site_role_api.dart';
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

  // Ancien cache global (conservé si besoin ailleurs)
  List<String>? _cachedRawRoles;
  DateTime? _fetchedAt;
  Duration cacheTtl = const Duration(seconds: 30);
  String? _tokenRef; // token utilisé pour remplir le cache

  // Nouveau cache spécifique au site sélectionné
  Set<AppRole>? _cachedSiteRoles;
  DateTime? _siteFetchedAt;
  int? _siteRef; // selectedSiteId au moment du cache

  void clearCache() {
    _cachedRawRoles = null;
    _fetchedAt = null;
    _tokenRef = SessionManager.instance.token;

    _cachedSiteRoles = null;
    _siteFetchedAt = null;
    _siteRef = SessionManager.instance.selectedSiteId;
  }

  Future<List<String>> currentRawRoles({bool forceRefresh = false}) async {
    if (!SessionManager.instance.isAuthenticated) return const [];

    // Invalide si le token a changé
    final currentToken = SessionManager.instance.token;
    if (_tokenRef != currentToken) {
      _cachedRawRoles = null;
      _fetchedAt = null;
      _tokenRef = currentToken;

      // Invalider aussi le cache site
      _cachedSiteRoles = null;
      _siteFetchedAt = null;
      _siteRef = SessionManager.instance.selectedSiteId;
    }

    final now = DateTime.now();
    if (!forceRefresh && _cachedRawRoles != null && _fetchedAt != null && now.difference(_fetchedAt!) < cacheTtl) {
      return _cachedRawRoles!;
    }

    final api = UsersApi(SessionManager.instance.client);
    try {
      final me = await api.me();
      _cachedRawRoles = me.roles;
      _fetchedAt = DateTime.now();
      _tokenRef = currentToken;
      return _cachedRawRoles!;
    } catch (_) {
      // En cas d'erreur on retourne le cache si dispo, sinon vide
      return _cachedRawRoles ?? const [];
    }
  }

  // Détermine les rôles efficaces pour le site actuellement sélectionné.
  // Règle: si plusieurs rôles sur le même site, le plus fort l'emporte (user < technicien < admin < super-admin).
  // Les rôles d'autres sites ne comptent pas.
  Future<Set<AppRole>> currentRoles({bool forceRefresh = false}) async {
    if (!SessionManager.instance.isAuthenticated) return const <AppRole>{};

    // Invalidation par changement de token
    final currentToken = SessionManager.instance.token;
    if (_tokenRef != currentToken) {
      _cachedSiteRoles = null;
      _siteFetchedAt = null;
      _siteRef = null;
      _tokenRef = currentToken;
    }

    final siteId = SessionManager.instance.selectedSiteId;
    // Si aucun site sélectionné, aucune permission spécifique
    if (siteId == null) {
      return const <AppRole>{};
    }

    final now = DateTime.now();
    final isSameSite = (_siteRef == siteId);
    if (!forceRefresh && _cachedSiteRoles != null && _siteFetchedAt != null && isSameSite && now.difference(_siteFetchedAt!) < cacheTtl) {
      return _cachedSiteRoles!;
    }

    final usersApi = UsersApi(SessionManager.instance.client);
    final usrSiteRoleApi = UserSiteRoleApi(SessionManager.instance.client);

    try {
      final me = await usersApi.me();
      final entries = await usrSiteRoleApi.siteUsers(siteId);

      // Rôles trouvés pour l'utilisateur courant sur ce site
      final rolesFound = <AppRole>{};
      for (final raw in entries) {
        final uidDyn = raw['user_id'] ?? raw['userId'];
        final uid = uidDyn is int ? uidDyn : int.tryParse(uidDyn?.toString() ?? '');
        if (uid != me.id) continue;
        final roleNameDyn = raw['role_name'] ?? raw['roleName'] ?? raw['role'];
        final roleName = roleNameDyn?.toString();
        if (roleName == null) continue;
        final mapped = _mapToAppRole(roleName);
        if (mapped != null) rolesFound.add(mapped);
      }

      // Choix du rôle le plus fort
      AppRole? strongest;
      int strengthOf(AppRole r) {
        switch (r) {
          case AppRole.user:
            return 1;
          case AppRole.technicien:
            return 2;
          case AppRole.admin:
            return 3;
          case AppRole.superAdmin:
            return 4;
        }
      }
      for (final r in rolesFound) {
        if (strongest == null || strengthOf(r) > strengthOf(strongest!)) {
          strongest = r;
        }
      }

      Set<AppRole> result;
      if (strongest == null) {
        result = const <AppRole>{};
      } else {
        // Étendre au rôle et à ceux "plus faibles" pour compatibilité (ex: admin implique technicien et user)
        switch (strongest) {
          case AppRole.superAdmin:
            result = {AppRole.user, AppRole.technicien, AppRole.admin, AppRole.superAdmin};
            break;
          case AppRole.admin:
            result = {AppRole.user, AppRole.technicien, AppRole.admin};
            break;
          case AppRole.technicien:
            result = {AppRole.user, AppRole.technicien};
            break;
          case AppRole.user:
            result = {AppRole.user};
            break;
        }
      }

      _cachedSiteRoles = result;
      _siteFetchedAt = DateTime.now();
      _siteRef = siteId;
      return result;
    } catch (_) {
      // En cas d'erreur, retourner le cache si possible, sinon vide
      if (_cachedSiteRoles != null && _siteRef == siteId) return _cachedSiteRoles!;
      return const <AppRole>{};
    }
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

    // Rebuild automatiquement lorsque le site sélectionné change
    return ValueListenableBuilder<int?>(
      valueListenable: SessionManager.instance.selectedSiteIdNotifier,
      builder: (context, _, __) {
        return FutureBuilder<Set<AppRole>>(
          future: RolesService.instance.currentRoles(forceRefresh: true),
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
