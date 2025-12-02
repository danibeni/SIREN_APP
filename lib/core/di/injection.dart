import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

/// GetIt instance for dependency injection
final getIt = GetIt.instance;

/// Initialize all dependencies using injectable code generation
///
/// This function registers all dependencies annotated with @injectable,
/// @lazySingleton, @singleton, etc.
/// Call this method during app startup (in main.dart) before runApp().
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: false,
)
Future<void> configureDependencies() async {
  init(getIt);
}

