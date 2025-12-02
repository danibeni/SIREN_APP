import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'core/di/di_container.dart';
import 'core/di/injection.dart';
import 'core/auth/auth_service.dart';
import 'features/config/presentation/pages/app_initialization_page.dart';
import 'features/config/presentation/pages/server_config_page.dart';
import 'features/config/presentation/pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDependencies();
  runApp(const SirenApp());
}

class SirenApp extends StatefulWidget {
  const SirenApp({super.key});

  @override
  State<SirenApp> createState() => _SirenAppState();
}

class _SirenAppState extends State<SirenApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'siren' && uri.host == 'oauth' && uri.path == '/callback') {
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      final errorDescription = uri.queryParameters['error_description'];
      final authService = getIt<AuthService>();
      authService.handleAuthCallback(
        code,
        error: error,
        errorDescription: errorDescription,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIREN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const AppInitializationPage(),
      routes: {
        '/config': (context) => const ServerConfigPage(),
        '/settings': (context) => const SettingsPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}


/// Placeholder home page - will be replaced with IssueListPage
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIREN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'Configuration Complete!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The app is configured and ready to use.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/settings'),
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
