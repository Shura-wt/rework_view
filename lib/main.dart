import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/session.dart';

part 'page/admin/gestion_carte.dart';
part 'page/admin/gestion_utilisateurs.dart';
part 'page/home.dart';
part 'page/login.dart';
part 'page/view.dart';

part 'components/drawer.dart';
part 'components/gradiant_background.dart';

// Models

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Configuration des routes
      routes: {
        '/login': (context) => const LoginPage(),
        // Page home (protégée, mais accessible par tout rôle)
        '/home': (context) => const HomePage(),
        '/view': (context) => const VisualisationCartePage(),
        // Pages admin (nécessitent requiresAdmin = true)
        '/admin/carte': (context) => const HomePage(initialPage: 'carte'),
        '/admin/utilisateurs': (context) => const HomePage(initialPage: 'utilisateurs'),
      },

      // Page de démarrage: AuthGate redirige selon la présence du token
      home: const AuthGate(),

      title: 'BAES Front',
      theme: ThemeData(
        useMaterial3: true,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Choisit l'écran selon l'état d'authentification.
    if (SessionManager.instance.isAuthenticated) {
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }
}
