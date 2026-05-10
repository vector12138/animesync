
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/progress_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  await storage.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(storage)),
        ChangeNotifierProvider(create: (_) => ProgressProvider(storage)),
      ],
      child: const AnimeSyncApp(),
    ),
  );
}

class AnimeSyncApp extends StatelessWidget {
  const AnimeSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnimeSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0D9488), // teal
        brightness: Brightness.dark,
      ),
      home: const _ScreenRouter(),
    );
  }
}

class _ScreenRouter extends StatelessWidget {
  const _ScreenRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return switch (auth.currentScreen) {
      AuthStage.setup => const SetupScreen(),
      AuthStage.auth => const AuthScreen(),
      AuthStage.home => const HomeScreen(),
    };
  }
}
