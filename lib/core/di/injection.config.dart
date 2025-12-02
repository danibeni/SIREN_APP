// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:logging/logging.dart' as _i831;

import '../../features/config/presentation/cubit/app_initialization_cubit.dart'
    as _i465;
import '../../features/config/presentation/cubit/server_config_cubit.dart'
    as _i34;
import '../auth/auth_service.dart' as _i88;
import '../auth/oauth2_service.dart' as _i151;
import '../config/server_config_service.dart' as _i629;
import '../network/dio_client.dart' as _i667;
import 'modules/config_module.dart' as _i810;
import 'modules/core_module.dart' as _i134;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt init(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  final configModule = _$ConfigModule();
  final coreModule = _$CoreModule();
  gh.lazySingleton<_i361.Dio>(() => configModule.provideDio());
  gh.lazySingleton<_i558.FlutterSecureStorage>(() => coreModule.secureStorage);
  gh.lazySingleton<_i831.Logger>(() => coreModule.logger);
  gh.lazySingleton<_i629.ServerConfigService>(
    () => _i629.ServerConfigService(
      secureStorage: gh<_i558.FlutterSecureStorage>(),
      logger: gh<_i831.Logger>(),
    ),
  );
  gh.lazySingleton<_i151.OAuth2Service>(
    () => _i151.OAuth2Service(
      gh<_i558.FlutterSecureStorage>(),
      gh<_i361.Dio>(),
      gh<_i831.Logger>(),
    ),
  );
  gh.lazySingleton<_i88.AuthService>(
    () => _i88.AuthService(
      oauth2Service: gh<_i151.OAuth2Service>(),
      logger: gh<_i831.Logger>(),
    ),
  );
  gh.lazySingleton<_i667.DioClient>(
    () => _i667.DioClient(
      authService: gh<_i88.AuthService>(),
      logger: gh<_i831.Logger>(),
    ),
  );
  gh.factory<_i465.AppInitializationCubit>(
    () => _i465.AppInitializationCubit(
      gh<_i629.ServerConfigService>(),
      gh<_i88.AuthService>(),
    ),
  );
  gh.factory<_i34.ServerConfigCubit>(
    () => _i34.ServerConfigCubit(
      gh<_i629.ServerConfigService>(),
      gh<_i88.AuthService>(),
    ),
  );
  return getIt;
}

class _$ConfigModule extends _i810.ConfigModule {}

class _$CoreModule extends _i134.CoreModule {}
