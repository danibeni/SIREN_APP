import 'injection.dart';

/// Dependency Injection container for SIREN application
///
/// This class manages all dependencies following Clean Architecture principles.
/// Dependencies are registered using `injectable` code generation.
///
/// **Registration is automatic** via annotations:
/// - `@injectable` - Factory (new instance each time)
/// - `@lazySingleton` - Singleton created on first access
/// - `@singleton` - Singleton created immediately
///
/// Dependencies are registered in order: Data Sources → Repositories → Use Cases → Blocs
///
/// **Usage:**
/// ```dart
/// // In main.dart
/// await configureDependencies();
/// runApp(MyApp());
/// ```
///
/// **To add new dependencies:**
/// 1. Add `@injectable`, `@lazySingleton`, or `@singleton` annotation to your class
/// 2. Use constructor injection for dependencies
/// 3. Run `flutter pub run build_runner build --delete-conflicting-outputs`
///
/// **For third-party dependencies** (e.g., FlutterSecureStorage, Logger):
/// - Use `@module` in `/lib/core/di/modules/core_module.dart`
///
/// See `AGENTS.md` for complete dependency injection guidelines.

/// Initialize all dependencies
///
/// This is a convenience wrapper around `configureDependencies()` from `injection.dart`.
/// Call this method during app startup (in main.dart) before runApp().
///
/// **Note:** This function uses code generation. After adding new `@injectable` classes,
/// run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate.
Future<void> initializeDependencies() async {
  await configureDependencies();
}
