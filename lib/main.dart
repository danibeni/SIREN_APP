import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:siren_app/core/auth/auth_service.dart';
import 'package:siren_app/core/di/di_container.dart';
import 'package:siren_app/core/di/injection.dart' as injection;
import 'package:siren_app/core/theme/app_colors.dart';
import 'package:siren_app/features/config/presentation/pages/app_initialization_page.dart';
import 'package:siren_app/features/config/presentation/pages/server_config_page.dart';
import 'package:siren_app/features/config/presentation/pages/settings_page.dart';
import 'package:siren_app/features/issues/presentation/pages/issue_form_page.dart';

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
      final authService = injection.getIt<AuthService>();
      authService.handleAuthCallback(
        code,
        error: error,
        errorDescription: errorDescription,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'SIREN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: true,
          fillColor: AppColors.surface,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryButton,
            foregroundColor: Colors.white,
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
        '/create-issue': (context) => const IssueFormPage(),
      },
    );
  }
}


/// Placeholder home page - will be replaced with IssueListPage in Story 4
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
              Icons.assignment,
              size: 80,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 24),
            Text(
              'Issue Management',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create and manage technical issues',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            Text(
              'Tap + to create a new issue',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed('/create-issue');
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Issue created successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Issue'),
      ),
    );
  }
}
