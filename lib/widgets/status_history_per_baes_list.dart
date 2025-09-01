import 'package:flutter/material.dart';
import '../services/status_poller.dart';
import '../models/models.dart';
import '../models/error_info.dart';

/// Widget de test: affiche l'historique complet des statuts par BAES.
/// Met en surbrillance (vert) le dernier statut reçu pour chaque BAES.
class StatusHistoryPerBaesList extends StatelessWidget {
  const StatusHistoryPerBaesList({super.key});

  @override
  Widget build(BuildContext context) {
    final poller = LatestStatusPoller.instance;
    return ValueListenableBuilder<Map<int, List<BaeStatus>>>(
      valueListenable: poller.perBaesHistoryNotifier,
      builder: (context, historyMap, _) {
        if (historyMap.isEmpty) {
          return const Center(child: Text('Aucun statut enregistré'));
        }
        // Ordonner les BAES par id croissant
        final baesIds = historyMap.keys.toList()..sort();
        return ValueListenableBuilder<Map<int, BaeStatus>>(
          valueListenable: poller.perBaesNotifier,
          builder: (context, latestMap, __) {
            return ListView.builder(
              itemCount: baesIds.length,
              itemBuilder: (context, index) {
                final baesId = baesIds[index];
                final list = List<BaeStatus>.from(historyMap[baesId] ?? const <BaeStatus>[]);
                // Sécurité: trier du plus récent au plus ancien
                list.sort((a, b) {
                  final ad = (a.updatedAt ?? a.timestamp) ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bd = (b.updatedAt ?? b.timestamp) ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bd.compareTo(ad);
                });
                final latest = latestMap[baesId];
                return ExpansionTile(
                  title: Text('BAES #$baesId — ${list.length} statut(s)'),
                  initiallyExpanded: false,
                  children: list.map((s) {
                    final info = StatusErrorVisuals.infoFor(s.erreur);
                    final updated = s.updatedAt ?? s.timestamp; // déjà UTC+02 côté parseurs
                    final solved = s.isSolved == true ? 'résolu' : 'non résolu';
                    final ignored = s.isIgnored == true ? ' (ignoré)' : '';

                    bool isLatest = false;
                    if (latest != null) {
                      if (s.id != null && latest.id != null) {
                        isLatest = s.id == latest.id;
                      } else {
                        final su = (s.updatedAt ?? s.timestamp)?.toUtc();
                        final lu = (latest.updatedAt ?? latest.timestamp)?.toUtc();
                        if (su != null && lu != null) {
                          isLatest = su.isAtSameMomentAs(lu);
                        }
                      }
                    }

                    final color = isLatest ? Colors.green : null;
                    return ListTile(
                      dense: true,
                      leading: Icon(info.icon, color: color ?? Colors.grey.shade700),
                      title: Text(
                        '${info.name}$ignored',
                        style: TextStyle(color: color, fontWeight: isLatest ? FontWeight.bold : FontWeight.w400),
                      ),
                      subtitle: Text('État: $solved • MAJ: ${updated ?? '-'}'),
                      trailing: Text('#${s.id ?? '-'}', style: TextStyle(color: color)),
                    );
                  }).toList(),
                );
              },
            );
          },
        );
      },
    );
  }
}
