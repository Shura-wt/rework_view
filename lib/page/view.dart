part of '../main.dart';

class VisualisationCartePage extends StatefulWidget {
  const VisualisationCartePage({super.key});

  @override
  State<VisualisationCartePage> createState() => _VisualisationCartePageState();
}

class _VisualisationCartePageState extends State<VisualisationCartePage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: const StatusHistoryPerBaesList(),

        ),
      ),
      floatingActionButton: VersatileFabColumn(
        fabs: [
          VersatileFab.icon(
            onPressed: () { Navigator.of(context).pop(); },
            icon: Icons.arrow_back,
            tooltip: 'Retour',
          ),
          VersatileFab.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ajouter')),
              );
            },
            icon: Icons.add,
            tooltip: 'Ajouter',
          ),
        ],
      ),
    );
  }
}
