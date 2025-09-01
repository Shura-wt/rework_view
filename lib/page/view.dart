part of '../main.dart';

class VisualisationCartePage extends StatefulWidget {
  const VisualisationCartePage({super.key});
  @override
  State<VisualisationCartePage> createState() => _VisualisationCartePageState();
}

class _VisualisationCartePageState extends State<VisualisationCartePage>{
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Page de gestion de la carte'),
      ),
    );
  }
}
