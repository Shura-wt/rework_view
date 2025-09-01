part of '../../main.dart';

class GestionCartePage extends StatefulWidget {
  const GestionCartePage({super.key});

  @override
  State<GestionCartePage> createState() => _GestionCartePageState();
}

class _GestionCartePageState extends State<GestionCartePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Page de gestion de la carte'),
      ),
    );
  }
}

