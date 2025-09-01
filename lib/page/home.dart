part of '../main.dart';

class HomePage extends StatefulWidget {
  final String? initialPage;

  const HomePage({super.key, this.initialPage});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage ?? 'home';
  }

  // Méthode pour créer un bouton de navigation.
  // On accepte un paramètre textStyle pour forcer la taille (ici fontSize: 75).
  TextButton _buildNavButton({
    required BuildContext context,
    required String page,
    required String text,
    required String route,
    TextStyle? textStyle,
  }) {
    bool isActive = _currentPage == page;
    // Style par défaut avec fontSize 75.
    TextStyle defaultStyle = const TextStyle(
      fontSize: 75,
      fontWeight: FontWeight.bold,
    );
    TextStyle finalStyle = (textStyle ?? defaultStyle).copyWith(
      color: isActive ? Colors.yellow : Colors.white,
      fontWeight: FontWeight.bold,
    );

    return TextButton(
      onPressed: () {
        if (!isActive) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: finalStyle,
          ),
          // Ligne de soulignement si le bouton est actif.
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 2.0),
              height: 2.0,
              width: 20.0,
              color: Colors.yellow,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sélection du contenu en fonction de _currentPage
    Widget bodyContent;
    switch (_currentPage) {
      case 'home':
        bodyContent = const VisualisationCartePage();
        break;
      case 'carte':
        bodyContent = const GestionCartePage();
        break;
      case 'utilisateurs':
        bodyContent = const GestionUtilisateursPage();
        break;
      default:
        bodyContent = const VisualisationCartePage();
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF0a526a),
          title: _buildNavButton(
            context: context,
            page: 'home',
            text: "Carte du site",
            route: '/home',
            textStyle: const TextStyle(fontSize: 30),
          ),
          actions: [
              _buildNavButton(
                context: context,
                page: 'carte',
                text: "Gestion carte",
                route: '/admin/carte',
                textStyle: const TextStyle(fontSize: 30),
              ),
              _buildNavButton(
                context: context,
                page: 'utilisateurs',
                text: "Gestion utilisateurs",
                route: '/admin/utilisateurs',
                textStyle: const TextStyle(fontSize: 30),
              ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                try {
                  // Stop polling before logging out to avoid authenticated calls after session cleared
                  LatestStatusPoller.instance.stop();
                  await SessionManager.instance.logout();
                } on Object catch (e) {
                  ApiErrorHandler.logDebug(e, context: 'logout');
                  if (mounted) {
                    ApiErrorHandler.showSnackBar(context, e, action: 'logout');
                  }
                } finally {
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              tooltip: "Se déconnecter",
            ),
          ],
        ),
      ),
      drawer: const LeftDrawer(),
      body: GradiantBackground.getSafeAreaGradiant(context, bodyContent),
    );
  }
}
