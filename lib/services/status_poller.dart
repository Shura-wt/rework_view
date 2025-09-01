// lib/services/status_poller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/session.dart';
import '../api/api.dart';
import '../models/models.dart';

class LatestStatusChange {
  final List<BaeStatus> changed; // Statuts réellement intégrés (modifiant l’état)
  final DateTime? lastUpdatedAt;
  LatestStatusChange({required this.changed, required this.lastUpdatedAt});
}

class LatestStatusPoller {
  static final LatestStatusPoller instance = LatestStatusPoller._internal();
  LatestStatusPoller._internal();

  void _debugPrintRegisteredStatuses(String sourceTag) {
    if (!kDebugMode) return;
    final map = perBaesNotifier.value;
    final items = map.entries
        .map((e) {
          final s = e.value;
          final label = errorCodeToLabel(s.erreur ?? -1);
          final up = (s.updatedAt ?? s.timestamp)?.toIso8601String() ?? '-';
          return 'BAES ${e.key}: id=${s.id} err=${s.erreur}($label) solved=${s.isSolved} ignored=${s.isIgnored} ts=$up';
        })
        .toList(growable: false);
    debugPrint('[DEBUG_LOG] status_poller_print [$sourceTag] registered_statuses_count=${items.length}');
    for (final line in items) {
      debugPrint('[DEBUG_LOG] status_poller_print -> $line');
    }
  }

  // Map des derniers statuts par BAES (clé = baesId)
  final ValueNotifier<Map<int, BaeStatus>> perBaesNotifier =
      ValueNotifier<Map<int, BaeStatus>>({});

  // Historique complet par BAES (clé = baesId)
  final ValueNotifier<Map<int, List<BaeStatus>>> perBaesHistoryNotifier =
      ValueNotifier<Map<int, List<BaeStatus>>>({});

  // Notifie quand un changement est appliqué (utile pour bandeau/info)
  final ValueNotifier<LatestStatusChange?> lastChangeNotifier =
      ValueNotifier<LatestStatusChange?>(null);

  // Notifiers unitaires par BAES (pour rafraîchir un widget ciblé)
  final Map<int, ValueNotifier<BaeStatus?>> _perBaesSingle = {};

  Timer? _timer;
  bool _running = false;
  bool _fetching = false;
  Duration _interval = const Duration(seconds: 5);

  DateTime? _lastUpdatedAt; // Converties par parseurs (UTC+02). À envoyer en UTC vers l’API.

  // Persistence key
  static const _kLastUpdatedKey = 'latest_status_last_updated_at';

  // Mapper code -> libellé lisible
  static String errorCodeToLabel(int code) {
    switch (code) {
      case 0:
        return 'erreur_connexion';
      case 4:
        return 'erreur_batterie';
      case 6:
        return 'ok';
      default:
        return 'unknown';
    }
  }

  ValueNotifier<BaeStatus?> getNotifierFor(int baesId) {
    return _perBaesSingle.putIfAbsent(baesId, () {
      final initial = perBaesNotifier.value[baesId];
      return ValueNotifier<BaeStatus?>(initial);
    });
  }

  Future<void> start({Duration interval = const Duration(seconds: 5)}) async {
    if (_running) return;
    _interval = interval;
    await _loadLastUpdatedFromPrefs();
    _running = true;
    // Chargement initial: récupère tous les statuts présents en base
    await _initialLoad();
    await _tick(); // Premier tick immédiat
    _timer = Timer.periodic(_interval, (_) => _tick());
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _initialLoad() async {
    try {
      final api = StatusApi(SessionManager.instance.client);
      final all = await api.list();
      if (all.isEmpty) return;
      _addToHistory(all);
      _mergeAndNotify(all);
      _updateLastUpdatedAtFrom(all);
      await _saveLastUpdatedToPrefs(_lastUpdatedAt);
      _debugPrintRegisteredStatuses('initial_full_load');
    } on Object catch (e) {
      ApiErrorHandler.logDebug(e, context: 'status_poller_initial_load');
    }
  }

  Future<void> _loadLastUpdatedFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_kLastUpdatedKey);
      if (s != null && s.isNotEmpty) {
        _lastUpdatedAt = DateTime.tryParse(s);
        if (kDebugMode) {
          debugPrint('[DEBUG_LOG] status_poller_load lastUpdatedAt=$_lastUpdatedAt');
        }
      }
    } catch (e) {
      ApiErrorHandler.logDebug(e, context: 'status_poller_load');
    }
  }

  Future<void> _saveLastUpdatedToPrefs(DateTime? dt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (dt == null) {
        await prefs.remove(_kLastUpdatedKey);
      } else {
        await prefs.setString(_kLastUpdatedKey, dt.toIso8601String());
      }
    } catch (e) {
      ApiErrorHandler.logDebug(e, context: 'status_poller_save');
    }
  }

  Future<void> _tick() async {
    if (!_running || _fetching) return;
    _fetching = true;
    try {
      final api = StatusApi(SessionManager.instance.client);

      // 1) Probe léger: /status/latest
      final latestList = await api.latest();
      if (latestList.isEmpty) return;

      // 2) Changement détecté ?
      final changed = _detectChange(latestList);
      if (!changed) return; // rien n’a changé

      // 3) S’il y a un changement, on tire les nouveautés depuis la dernière date connue
      final afterSince = _lastUpdatedAt ?? _maxUpdatedAt(latestList);
      if (afterSince == null) {
        // Première initialisation: merge des latest uniquement
        _addToHistory(latestList);
        _mergeAndNotify(latestList);
        _updateLastUpdatedAtFrom(latestList);
        _debugPrintRegisteredStatuses('initial_latest_merge');
        return;
      }

      List<BaeStatus> afterList = [];
      try {
        afterList = await api.listAfter(afterSince);
      } on Object catch (e) {
        ApiErrorHandler.logDebug(e, context: 'status_poller_after');
        // Fallback minimal: intégrer latestList quand même
        _addToHistory(latestList);
        _mergeAndNotify(latestList);
        _updateLastUpdatedAtFrom(latestList);
        _debugPrintRegisteredStatuses('fallback_latest_merge');
        return;
      }

      // 4) Fusionner latest + after
      final allNew = <BaeStatus>[...latestList, ...afterList];
      _addToHistory(allNew);
      final actuallyChanged = _mergeAndNotify(allNew);

      // 5) Mettre à jour lastUpdatedAt et persister
      _updateLastUpdatedAtFrom(allNew);
      await _saveLastUpdatedToPrefs(_lastUpdatedAt);

      // 6) Notifier les changements effectifs
      if (actuallyChanged.isNotEmpty) {
        lastChangeNotifier.value = LatestStatusChange(
          changed: actuallyChanged,
          lastUpdatedAt: _lastUpdatedAt,
        );
        _debugPrintRegisteredStatuses('latest_after_merge');
      }
    } on Object catch (e) {
      ApiErrorHandler.logDebug(e, context: 'status_poller_tick');
    } finally {
      _fetching = false;
    }
  }

  bool _detectChange(List<BaeStatus> latestList) {
    // Critère robuste: max(updatedAt/timestamp) > _lastUpdatedAt
    final maxUp = _maxUpdatedAt(latestList);
    if (maxUp == null) return false;
    final last = _lastUpdatedAt;
    if (last == null) return true;
    return maxUp.toUtc().isAfter(last.toUtc());
  }

  DateTime? _maxUpdatedAt(List<BaeStatus> list) {
    DateTime? maxDt;
    for (final s in list) {
      final u = s.updatedAt ?? s.timestamp;
      if (u == null) continue;
      if (maxDt == null || u.isAfter(maxDt)) maxDt = u;
    }
    return maxDt;
  }

  // Ajoute des statuts à l'historique par BAES (avec déduplication/tri/limite)
  void _addToHistory(List<BaeStatus> updates) {
    if (updates.isEmpty) return;
    final history = Map<int, List<BaeStatus>>.from(perBaesHistoryNotifier.value);

    // Indexer par BAES
    final grouped = <int, List<BaeStatus>>{};
    for (final s in updates) {
      final id = s.baesId;
      if (id == null) continue;
      grouped.putIfAbsent(id, () => []).add(s);
    }

    int _compare(BaeStatus a, BaeStatus b) {
      final ad = (a.updatedAt ?? a.timestamp) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = (b.updatedAt ?? b.timestamp) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad); // desc
    }

    for (final entry in grouped.entries) {
      final baesId = entry.key;
      final incoming = entry.value;
      final list = history.putIfAbsent(baesId, () => <BaeStatus>[]);

      // Dédup par id
      final existingIds = list.map((e) => e.id).whereType<int>().toSet();
      for (final s in incoming) {
        final sid = s.id;
        if (sid != null && existingIds.contains(sid)) continue;
        list.add(s);
        if (sid != null) existingIds.add(sid);
      }

      list.sort(_compare);
      const maxPerBaes = 200;
      if (list.length > maxPerBaes) {
        list.removeRange(maxPerBaes, list.length);
      }
      history[baesId] = list;
    }

    perBaesHistoryNotifier.value = history;
  }

  // Merge: garde le statut le plus récent par BAES; retourne ceux qui ont réellement changé
  List<BaeStatus> _mergeAndNotify(List<BaeStatus> updates) {
    final current = Map<int, BaeStatus>.from(perBaesNotifier.value);
    final changed = <BaeStatus>[];

    BaeStatus pickMoreRecent(BaeStatus a, BaeStatus b) {
      final aUp = a.updatedAt ?? a.timestamp;
      final bUp = b.updatedAt ?? b.timestamp;
      if (aUp != null && bUp != null) return aUp.isAfter(bUp) ? a : b;
      final aId = a.id ?? 0;
      final bId = b.id ?? 0;
      return aId >= bId ? a : b;
    }

    // Grouper par BAES
    final grouped = <int, List<BaeStatus>>{};
    for (final s in updates) {
      if (s.baesId == null) continue;
      grouped.putIfAbsent(s.baesId!, () => []).add(s);
    }

    grouped.forEach((baesId, list) {
      final latestForBaes = list.reduce(pickMoreRecent);
      final prev = current[baesId];
      if (_statusChanged(prev, latestForBaes)) {
        current[baesId] = latestForBaes;
        changed.add(latestForBaes);
      }
    });

    if (changed.isNotEmpty) {
      perBaesNotifier.value = current;
      // Mettre à jour les notifiers unitaires
      for (final s in changed) {
        final bId = s.baesId;
        if (bId != null && _perBaesSingle.containsKey(bId)) {
          _perBaesSingle[bId]!.value = s;
        }
      }
    }
    return changed;
  }

  void _updateLastUpdatedAtFrom(List<BaeStatus> list) {
    final maxUp = _maxUpdatedAt(list);
    if (maxUp == null) return;
    if (_lastUpdatedAt == null || maxUp.isAfter(_lastUpdatedAt!)) {
      _lastUpdatedAt = maxUp;
    }
  }

  bool _statusChanged(BaeStatus? prev, BaeStatus next) {
    if (prev == null) return true;
    final pUp = (prev.updatedAt ?? prev.timestamp)?.toUtc();
    final nUp = (next.updatedAt ?? next.timestamp)?.toUtc();
    if (pUp != null || nUp != null) {
      if (pUp == null || nUp == null) return true;
      if (!pUp.isAtSameMomentAs(nUp)) return true;
    }
    if (prev.baesId != next.baesId) return true;
    if (prev.erreur != next.erreur) return true;
    if (prev.isSolved != next.isSolved) return true;
    if (prev.isIgnored != next.isIgnored) return true;
    if ((prev.temperature ?? 0) != (next.temperature ?? 0)) return true;
    if ((prev.vibration ?? false) != (next.vibration ?? false)) return true;
    return false;
  }
}
