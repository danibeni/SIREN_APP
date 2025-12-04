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
import 'package:siren_app/core/auth/auth_service.dart' as _i711;
import 'package:siren_app/core/auth/oauth2_service.dart' as _i527;
import 'package:siren_app/core/config/server_config_service.dart' as _i1000;
import 'package:siren_app/core/di/modules/config_module.dart' as _i956;
import 'package:siren_app/core/di/modules/core_module.dart' as _i1008;
import 'package:siren_app/core/network/dio_client.dart' as _i657;
import 'package:siren_app/features/config/presentation/cubit/app_initialization_cubit.dart'
    as _i462;
import 'package:siren_app/features/config/presentation/cubit/server_config_cubit.dart'
    as _i1033;
import 'package:siren_app/features/issues/data/datasources/issue_remote_datasource.dart'
    as _i407;
import 'package:siren_app/features/issues/data/datasources/issue_remote_datasource_impl.dart'
    as _i372;
import 'package:siren_app/features/issues/data/repositories/issue_repository_impl.dart'
    as _i711;
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart'
    as _i885;
import 'package:siren_app/features/issues/domain/usecases/create_issue_uc.dart'
    as _i725;
import 'package:siren_app/features/issues/presentation/bloc/create_issue_cubit.dart'
    as _i279;

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
  gh.lazySingleton<_i1000.ServerConfigService>(
    () => _i1000.ServerConfigService(
      secureStorage: gh<_i558.FlutterSecureStorage>(),
      logger: gh<_i831.Logger>(),
    ),
  );
  gh.lazySingleton<_i527.OAuth2Service>(
    () => _i527.OAuth2Service(
      gh<_i558.FlutterSecureStorage>(),
      gh<_i361.Dio>(),
      gh<_i831.Logger>(),
    ),
  );
  gh.lazySingleton<_i711.AuthService>(
    () => _i711.AuthService(
      oauth2Service: gh<_i527.OAuth2Service>(),
      logger: gh<_i831.Logger>(),
    ),
  );
  gh.lazySingleton<_i657.DioClient>(
    () => _i657.DioClient(
      authService: gh<_i711.AuthService>(),
      logger: gh<_i831.Logger>(),
    ),
  );
  gh.factory<_i462.AppInitializationCubit>(
    () => _i462.AppInitializationCubit(
      gh<_i1000.ServerConfigService>(),
      gh<_i711.AuthService>(),
    ),
  );
  gh.factory<_i1033.ServerConfigCubit>(
    () => _i1033.ServerConfigCubit(
      gh<_i1000.ServerConfigService>(),
      gh<_i711.AuthService>(),
    ),
  );
  gh.lazySingleton<_i407.IssueRemoteDataSource>(
    () => _i372.IssueRemoteDataSourceImpl(
      dioClient: gh<_i657.DioClient>(),
      serverConfigService: gh<_i1000.ServerConfigService>(),
      logger: gh<_i831.Logger>(),
    ),
  );
  gh.lazySingleton<_i885.IssueRepository>(
    () => _i711.IssueRepositoryImpl(
      remoteDataSource: gh<_i407.IssueRemoteDataSource>(),
    ),
  );
  gh.lazySingleton<_i725.CreateIssueUseCase>(
    () => _i725.CreateIssueUseCase(gh<_i885.IssueRepository>()),
  );
  gh.factory<_i279.CreateIssueCubit>(
    () => _i279.CreateIssueCubit(
      gh<_i725.CreateIssueUseCase>(),
      gh<_i407.IssueRemoteDataSource>(),
    ),
  );
  return getIt;
}

class _$ConfigModule extends _i956.ConfigModule {}

class _$CoreModule extends _i1008.CoreModule {}
