# Project Guidelines (Dart/Flutter)

This document describes the project-specific guidelines for contributing to the rework_view Flutter app. It complements the official Dart and Flutter style guides and the rules enabled in analysis_options.yaml.

Scope and goals:
- Keep the codebase consistent and easy to navigate.
- Encourage safe, testable code with clear layering (API ↔ Models ↔ UI).
- Minimize regressions through predictable patterns (error handling, routing, auth, etc.).

Tech stack and versions:
- Flutter SDK: see pubspec.yaml (currently SDK ^3.8.1)
- Lint baseline: flutter_lints ^5.0.0 (see analysis_options.yaml)
- Networking: http (see lib/api/base_api.dart)
- Storage/Prefs: shared_preferences
- Utilities: provider (available), intl, uuid, collection

Project structure and responsibilities:
- lib/api: API clients for backend endpoints.
  - base_api.dart: ApiClient and ApiException (common HTTP layer).
  - error_handler.dart: ApiErrorHandler with message mapping, logging, and UI helpers.
  - Grouped API files (e.g., users_api.dart, sites_api.dart) should expose typed methods that wrap ApiClient calls and convert payloads to DTOs/Domain models.
- lib/auth: Session and guards.
  - session.dart: SessionManager handles token init/persistence and provides isAuthenticated.
  - roles_guard.dart: Gate helpers for role-based UI/actions.
- lib/models: Data layer.
  - domain/…: App-level domain models used by UI/business logic.
  - dto/…: Data transfer objects that mirror server payloads.
  - api/…: API-payload helpers (if any) for request/response shapes.
  - Barrel export: models/models.dart gathers public types for convenient imports.
- lib/services: Long-running/background services (e.g., status polling via LatestStatusPoller).
- lib/page: Screens and navigation targets (e.g., home, login, admin pages).
- lib/widgets: Reusable UI components (e.g., drawer, status lists, FABs, backgrounds).
- web/: PWA assets and manifest.

Naming and file conventions:
- Files: snake_case.dart (e.g., user_site_role_api.dart, status_poller.dart).
- Classes/Enums/TypeDefs: PascalCase (e.g., ApiClient, LatestStatusPoller).
- Members/Variables/Functions: lowerCamelCase.
- Constants: lowerCamelCase with const, or ALL_CAPS only when unavoidable.
- Keep French domain terms where already used (ex: BAE, étage, bâtiment), but aim for consistent English API surface in code comments and method names when possible; do not rename existing public APIs without discussion.

Imports:
- Prefer package imports for cross-module access within the app (package:rework_view/…).
- Relative imports within the same feature/module are acceptable.
- Reuse barrel files where provided (e.g., import 'package:rework_view/models/models.dart').

State management and side effects:
- Keep widgets as dumb as possible; delegate side effects and background work to services (e.g., LatestStatusPoller in lib/services).
- Provider is available if you need scoped state. Prefer ChangeNotifier + Provider for simple app-wide state. Discuss before introducing additional state libraries.
- Side effects tied to navigation or auth should go through SessionManager and guards.

Routing and navigation:
- Define named routes in MaterialApp.routes (see lib/main.dart) and use Navigator.pushNamed for navigation.
- Protect routes/screens that require authentication with an AuthGate or guard widget. Admin-only pages should verify roles (see roles_guard.dart).

API usage and error handling:
- Use ApiClient (lib/api/base_api.dart) for all HTTP calls. Do not import http directly in UI code.
- Wrap endpoint groups in dedicated files in lib/api (e.g., users_api.dart) that:
  - Compose the URL from a shared base.
  - Serialize/deserialize using DTOs and parsers in lib/models.
  - Translate to domain models for UI where appropriate.
- Error handling:
  - For UI-integrated calls, use ApiErrorHandler.run(context, () async { … }, action: '…') to centralize snackbars and logging.
  - For background/services, call ApiErrorHandler.logDebug(e, context: 'service:…') and surface user-facing messages at the UI boundary.
  - Map authentication/authorization failures to re-login flows as needed.

Data models and parsing:
- Keep DTOs focused on JSON wire format. Use domain models in UI/business logic.
- Add parsing helpers in lib/models/parsers.dart or on the model type itself.
- Prefer immutable models (final fields) and copyWith() where mutation is needed.

Auth/session:
- Initialize SessionManager at app start (see main.dart). If authenticated, start LatestStatusPoller.
- Store and supply the bearer token via ApiClient.token. Avoid duplicating token handling in API call sites.

UI and theming:
- Prefer const constructors and widgets where possible (performance).
- Use Material 3 and app theme extensions; keep colors and sizes centralized.
- Follow accessibility best practices: semantics, minimum tap targets, sufficient contrast.

Logging:
- Use debugPrint for debugging. Avoid print in production code.
- Do not leak tokens or PII in logs.

Testing:
- Widget tests live under test/. Add regression tests alongside features.
- For API-heavy logic, write unit tests that mock ApiClient; avoid hitting the network.
- Keep test names descriptive: should_doX_whenY.

Performance and reliability:
- Use const widgets and keys where appropriate.
- Debounce rapid API actions in UI.
- Always set timeouts on network calls (handled by ApiClient.timeout).

Working with apispec.json:
- apispec.json documents backend endpoints (OpenAPI-like). When adding/changing API calls:
  - Align request/response shapes with the spec.
  - Update DTOs and parsers accordingly.
  - Note breaking changes in PRs.

Git and PR process:
- Create feature branches from main.
- Follow conventional commits where possible (feat:, fix:, chore:, docs:, refactor:, test:).
- Keep PRs small and focused; include context in the description and screenshots/GIFs for UI changes.
- Link issues and describe manual test steps.

Code style reminders (Dart/Flutter):
- Prefer single quotes for strings unless interpolation or escaping is awkward.
- Use trailing commas to enable better formatting.
- Avoid dynamic where possible; type your APIs.
- Prefer final for locals/fields that don’t change.

How to run locally:
- flutter pub get
- flutter run -d chrome (web) or -d windows/android/ios as applicable
- flutter analyze (lint) and flutter test (unit/widget tests)

Decision log and deviations:
- If you need to deviate from these guidelines, note the rationale in the PR description. Significant deviations should be discussed first.
