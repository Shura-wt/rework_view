import 'package:flutter/material.dart';
import '../services/status_poller.dart';
import '../models/models.dart';

/// Widget de test: affiche la liste des derniers statuts par BAES.
/// Se met automatiquement à jour lorsqu'un polling applique de nouveaux statuts.
class StatusPerBaesList extends StatelessWidget {
  const StatusPerBaesList({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<int, BaeStatus>>(
      valueListenable: LatestStatusPoller.instance.perBaesNotifier,
      builder: (context, map, _) {
        if (map.isEmpty) {
          return const Center(child: Text('Aucun statut enregistré'));
        }
        final entries = map.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        return ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final baesId = entries[index].key;
            final s = entries[index].value;
            final label = LatestStatusPoller.errorCodeToLabel(s.erreur ?? -1);
            final updated = s.updatedAt ?? s.timestamp; // déjà UTC+02 côté parseurs
            final solved = s.isSolved == true ? 'résolu' : 'non résolu';
            final ignored = s.isIgnored == true ? ' (ignoré)' : '';
            return ListTile(
              dense: true,
              title: Text('BAES #$baesId — $label$ignored'),
              subtitle: Text('État: $solved • MAJ: ${updated ?? '-'}'),
              trailing: Text('#${s.id ?? '-'}'),
            );
          },
        );
      },
    );
  }
}
