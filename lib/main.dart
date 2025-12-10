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
import 'package:siren_app/features/issues/presentation/pages/issue_detail_page.dart';
import 'package:siren_app/features/issues/presentation/pages/issue_form_page.dart';
import 'package:siren_app/features/issues/presentation/pages/issue_list_page.dart';

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
    if (uri.scheme == 'siren' &&
        uri.host == 'oauth' &&
        uri.path == '/callback') {
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
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 2,
          shadowColor: AppColors.primaryBlue.withOpacity(0.3),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
          toolbarHeight: 56,
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
        '/home': (context) => const IssueListPage(),
        '/issues': (context) => const IssueListPage(),
        '/create-issue': (context) => const IssueFormPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/issue-detail') {
          final issueId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => IssueDetailPage(issueId: issueId),
          );
        }
        return null;
      },
    );
  }
}
