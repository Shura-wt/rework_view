# Project Guidelines

Ce document décrit le projet Flutter « rework_view » et, surtout, comment l’app front est reliée à l’API REST qui communique avec la base de données Microsoft SQL Server 2017.

---

## Aperçu du projet
- Application Flutter (Dart) avec une couche réseau typée sous `lib\api\` et des modèles sous `lib\models\`.
- Pages principales sous `lib\page\`, dont des écrans d’administration (utilisateurs, cartes).
- La configuration réseau est centralisée via un client HTTP réutilisable et la session applicative.

Structure (principaux dossiers/fichiers):
- `lib\api\`: services d’accès API (une classe par ressource) + `ApiClient` générique
- `lib\auth\session.dart`: gestion du JWT et de la base URL côté app
- `lib\auth\roles_guard.dart`: garde d’accès par rôles
- `lib\page\...`: pages et vues
- `lib\models\...`: modèles domaine/DTO, parsers, utilitaires JSON
- `apispec.json`: schéma OpenAPI de l’API (à des fins de référence/outillage)

---

## Exécution / Analyse / Tests
- Installer les dépendances: `flutter pub get`
- Formatage: `dart format .`
- Analyse statique: `flutter analyze`
- Tests (s’ils existent): `flutter test`
- Lancer l’app: `flutter run` (ou `flutter run -d chrome` pour Web)

Code style:
- Respecter `analysis_options.yaml` (Flutter lints).
- Préférer des widgets `const`, classes et fichiers en `UpperCamelCase` / `snake_case.dart`.

---

## Intégration API BAES (front ↔ API ↔ MSSQL2017)

### Résumé et technologies utilisées (côté serveur)
- Objet: API REST pour gérer les BAES (Blocs Autonomes d’Éclairage de Sécurité) et le référentiel: sites, bâtiments, étages, équipements BAES, statuts/erreurs, cartes/coordonnées, utilisateurs et rôles.
- Principales fonctionnalités:
  - Authentification (JWT) et gestion de session légère (login/logout).
  - CRUD sur les entités: utilisateurs, rôles, sites, bâtiments, étages, BAES, statuts, cartes.
  - Attribution de rôles par site et rôles globaux via `user_site_role`.
  - Documentation Swagger (Flasgger) sur `/swagger/` et schéma exposé via `/apispec.json`.
  - CORS activé pour appels front-end.
- Technologies clés:
  - Backend: Python Flask.
  - BDD: Microsoft SQL Server 2017 via SQLAlchemy + pyodbc (ODBC Driver 17).
  - Migrations: Flask-Migrate (Alembic).
  - Auth et session: Flask-Login + JWT applicatif.
  - Documentation: Flasgger/Swagger UI.
  - Conteneurisation: Docker + docker-compose; exécution prod: uWSGI + supervisord.
  - Outils/utilitaires: Bridge MQTT -> API (`scripts/mqtt_to_baesapi.py`), CORS, logging.
  - Dernière mise à jour: 2025-09-01 11:29.

Notes importantes:
- Authentification: certaines routes peuvent exiger une session utilisateur (ex: logout). Le login retourne un JWT dans la réponse pour usage côté client.
- Legacy: les routes de statut sont disponibles sous le préfixe principal `/status`. Par compatibilité, elles existent aussi sous `/erreurs` (mêmes chemins relatifs et mêmes schémas).
- Formats: sauf mention contraire, `Content-Type: application/json` pour requêtes et réponses. Dates en `ISO 8601` (string).

### Comment le front est relié à l’API (chemin complet jusqu’à MSSQL2017)
- Le front Flutter NE communique PAS directement avec la base MSSQL. Il consomme uniquement l’API HTTP.
- L’API Flask traite les requêtes, applique les règles métier et persiste via SQLAlchemy sur MSSQL 2017 (driver ODBC 17).
- Chemin logique:
  1) Flutter → HTTP(S) JSON → API Flask
  2) API Flask → SQLAlchemy/pyodbc → Microsoft SQL Server 2017
  3) Réponse JSON → Flutter
- CORS est activé côté API pour autoriser le front (Web/mobile) à appeler les endpoints.

### Base URL, configuration et session côté Flutter
- La base URL est centralisée et injectée dans le client API.
  - Voir `lib\auth\session.dart`: `SessionManager` instancie `ApiClient(baseUrl: Config.baseUrl)`.
  - Le token JWT est chargé/persisté via `SharedPreferences` et propagé au client: `client.token = token`.
- Modifiez `Config.baseUrl` (dans `lib\models\domain\config.dart`) pour pointer sur dev/staging/prod.

### Client HTTP et en-têtes
- Client générique: `lib\api\base_api.dart` → `class ApiClient`
  - Gère `baseUrl`, `Authorization: Bearer <JWT>`, `Content-Type: application/json`, timeouts et erreurs.
  - Expose: `get`, `post`, `put`, `patch`, `delete`, `multipart`.
  - Les erreurs réseau/HTTP lèvent `ApiException` avec code et message backend quand disponible.
- En-têtes standards envoyés par défaut:
  - `Content-Type: application/json`
  - `Accept: application/json` (si nécessaire en extra)
  - `Authorization: Bearer <JWT>` après login

### Services API (mapping fichiers ↔ routes)
Les services sous `lib\api\` enveloppent `ApiClient` pour chaque ressource:
- `auth_api.dart` → `/auth` (login, logout)
- `users_api.dart` → `/users`
- `users_sites_api.dart` → `/users/sites`
- `user_site_role_api.dart` → `/user_site_role` (rôles globaux/assignations)
- `sites_api.dart` → `/sites`
- `batiments_api.dart` → `/batiments`
- `etages_api.dart` → `/etages`
- `baes_api.dart` → `/baes`
- `status_api.dart` → `/status` (alias legacy `/erreurs`)
- `cartes_api.dart` → `/cartes` (+ endpoints dérivés `/sites/carte`, `/etages/carte`)
- `general_api.dart` → `/general`
- `roles_api.dart` → `/roles`
- `config_api.dart` → `/config`
- `error_handler.dart` → utilitaires de gestion d’erreurs côté client

Modèles/DTO:
- Sous `lib\models\...` (domain, dto, geo, etc.), avec parsers JSON pour sérialiser/désérialiser les payloads.

### Flux d’authentification et autorisation
- Login: `POST /auth/login` → retourne un JWT (champ `token`) et éventuellement des infos utilisateur/site.
- Le JWT est stocké de manière persistante et ajouté automatiquement aux appels suivants via `ApiClient`.
- Logout: `GET /auth/logout` (peut exiger une session côté serveur). La session locale est purgée.
- Garde d’accès: `lib\auth\roles_guard.dart` évalue les rôles globaux et par site pour conditionner l’accès UI.

### Gestion des erreurs et états réseau
- Réponses 2xx: succès → décodage JSON automatique.
- 4xx/5xx: levée d’`ApiException` avec message backend si présent (`error` ou `message`).
- Cas à prévoir côté UI: JWT expiré/invalide → redirection login, offline/timeout → réessais et messages utilisateur.

### Swagger et schéma OpenAPI
- Explorer la documentation intégrée: `/swagger/`.
- Le schéma OpenAPI est disponible via `/apispec.json`. Une copie locale existe à la racine du repo: `apispec.json` (référence/outillage).
- Optionnel: génération d’un client plus typé via OpenAPI Generator si besoin.

### Sécurité et bonnes pratiques
- Ne pas journaliser le JWT ni des données sensibles.
- Stocker le JWT via un mécanisme approprié (ici `SharedPreferences` + mémoire process) et le purger au logout.
- Valider et assainir les entrées côté UI; afficher les messages d’erreur backend utiles à l’utilisateur.

### Performance
- Mutualiser les appels via services, activer des caches légers pour référentiels stables (sites/bâtiments/étages/statuts).
- Débouncer les recherches et annuler les requêtes non pertinentes en navigation.

---

## Workflow pour contributions (Junie et collaborateurs)
1. `flutter pub get`
2. `dart format .`
3. `flutter analyze`
4. `flutter test` (si des tests existent)
5. Vérifier la configuration `Config.baseUrl` et l’accessibilité de l’API (CORS, auth) avant soumission.

Ce guide est la source de vérité sur l’intégration front ↔ API BAES ↔ MSSQL2017. Mettez à jour cette page si l’API évolue (endpoints, auth, schéma, environnements).



