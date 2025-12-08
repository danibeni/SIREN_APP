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
import 'package:siren_app/features/issues/data/datasources/issue_local_datasource.dart'
    as _i93;
import 'package:siren_app/features/issues/data/datasources/issue_remote_datasource.dart'
    as _i407;
import 'package:siren_app/features/issues/data/datasources/issue_remote_datasource_impl.dart'
    as _i372;
import 'package:siren_app/features/issues/data/datasources/work_package_type_local_datasource.dart'
    as _i139;
import 'package:siren_app/features/issues/data/repositories/issue_repository_impl.dart'
    as _i711;
import 'package:siren_app/features/issues/data/repositories/work_package_type_repository_impl.dart'
    as _i34;
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart'
    as _i885;
import 'package:siren_app/features/issues/domain/repositories/work_package_type_repository.dart'
    as _i229;
import 'package:siren_app/features/issues/domain/usecases/create_issue_uc.dart'
    as _i725;
import 'package:siren_app/features/issues/domain/usecases/get_attachments_uc.dart'
    as _i277;
import 'package:siren_app/features/issues/domain/usecases/get_available_types_uc.dart'
    as _i85;
import 'package:siren_app/features/issues/domain/usecases/get_issue_by_id_uc.dart'
    as _i216;
import 'package:siren_app/features/issues/domain/usecases/get_issues_uc.dart'
    as _i695;
import 'package:siren_app/features/issues/domain/usecases/get_statuses_for_type_uc.dart'
    as _i720;
import 'package:siren_app/features/issues/domain/usecases/get_work_package_type_uc.dart'
    as _i589;
import 'package:siren_app/features/issues/domain/usecases/refresh_statuses_uc.dart'
    as _i198;
import 'package:siren_app/features/issues/domain/usecases/set_work_package_type_uc.dart'
    as _i714;
import 'package:siren_app/features/issues/domain/usecases/update_issue_uc.dart'
    as _i812;
import 'package:siren_app/features/issues/presentation/bloc/create_issue_cubit.dart'
    as _i279;
import 'package:siren_app/features/issues/presentation/cubit/edit_issue_cubit.dart'
    as _i719;
import 'package:siren_app/features/issues/presentation/cubit/issue_detail_cubit.dart'
    as _i435;
import 'package:siren_app/features/issues/presentation/cubit/issues_list_cubit.dart'
    as _i849;
import 'package:siren_app/features/issues/presentation/cubit/work_package_type_cubit.dart'
    as _i904;

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
  gh.lazySingleton<_i139.WorkPackageTypeLocalDataSource>(
    () => _i139.WorkPackageTypeLocalDataSource(
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
  gh.lazySingleton<_i93.IssueLocalDataSource>(
    () => _i93.IssueLocalDataSource(
      secureStorage: gh<_i558.FlutterSecureStorage>(),
      logger: gh<_i831.Logger>(),
      dioClient: gh<_i657.DioClient>(),
      serverConfigService: gh<_i1000.ServerConfigService>(),
    ),
  );
  gh.lazySingleton<_i229.WorkPackageTypeRepository>(
    () => _i34.WorkPackageTypeRepositoryImpl(
      remoteDataSource: gh<_i407.IssueRemoteDataSource>(),
      localDataSource: gh<_i139.WorkPackageTypeLocalDataSource>(),
      logger: gh<_i831.Logger>(),
    ),
  );
  gh.lazySingleton<_i885.IssueRepository>(
    () => _i711.IssueRepositoryImpl(
      remoteDataSource: gh<_i407.IssueRemoteDataSource>(),
      localDataSource: gh<_i93.IssueLocalDataSource>(),
      serverConfigService: gh<_i1000.ServerConfigService>(),
      logger: gh<_i831.Logger>(),
    ),
  );
  gh.lazySingleton<_i725.CreateIssueUseCase>(
    () => _i725.CreateIssueUseCase(gh<_i885.IssueRepository>()),
  );
  gh.lazySingleton<_i277.GetAttachmentsUseCase>(
    () => _i277.GetAttachmentsUseCase(gh<_i885.IssueRepository>()),
  );
  gh.lazySingleton<_i216.GetIssueByIdUseCase>(
    () => _i216.GetIssueByIdUseCase(gh<_i885.IssueRepository>()),
  );
  gh.lazySingleton<_i812.UpdateIssueUseCase>(
    () => _i812.UpdateIssueUseCase(gh<_i885.IssueRepository>()),
  );
  gh.lazySingleton<_i85.GetAvailableTypesUseCase>(
    () => _i85.GetAvailableTypesUseCase(gh<_i229.WorkPackageTypeRepository>()),
  );
  gh.lazySingleton<_i720.GetStatusesForTypeUseCase>(
    () =>
        _i720.GetStatusesForTypeUseCase(gh<_i229.WorkPackageTypeRepository>()),
  );
  gh.lazySingleton<_i589.GetWorkPackageTypeUseCase>(
    () =>
        _i589.GetWorkPackageTypeUseCase(gh<_i229.WorkPackageTypeRepository>()),
  );
  gh.lazySingleton<_i198.RefreshStatusesUseCase>(
    () => _i198.RefreshStatusesUseCase(gh<_i229.WorkPackageTypeRepository>()),
  );
  gh.lazySingleton<_i714.SetWorkPackageTypeUseCase>(
    () =>
        _i714.SetWorkPackageTypeUseCase(gh<_i229.WorkPackageTypeRepository>()),
  );
  gh.factory<_i435.IssueDetailCubit>(
    () => _i435.IssueDetailCubit(
      getIssueByIdUseCase: gh<_i216.GetIssueByIdUseCase>(),
      getAttachmentsUseCase: gh<_i277.GetAttachmentsUseCase>(),
      logger: gh<_i831.Logger>(),
    ),
  );
  gh.lazySingleton<_i695.GetIssuesUseCase>(
    () => _i695.GetIssuesUseCase(
      gh<_i885.IssueRepository>(),
      gh<_i589.GetWorkPackageTypeUseCase>(),
    ),
  );
  gh.factory<_i849.IssuesListCubit>(
    () => _i849.IssuesListCubit(
      gh<_i695.GetIssuesUseCase>(),
      gh<_i198.RefreshStatusesUseCase>(),
    ),
  );
  gh.factory<_i279.CreateIssueCubit>(
    () => _i279.CreateIssueCubit(
      gh<_i725.CreateIssueUseCase>(),
      gh<_i407.IssueRemoteDataSource>(),
    ),
  );
  gh.lazySingleton<_i904.WorkPackageTypeCubit>(
    () => _i904.WorkPackageTypeCubit(
      gh<_i85.GetAvailableTypesUseCase>(),
      gh<_i589.GetWorkPackageTypeUseCase>(),
      gh<_i714.SetWorkPackageTypeUseCase>(),
      gh<_i720.GetStatusesForTypeUseCase>(),
    ),
  );
  gh.factory<_i719.EditIssueCubit>(
    () => _i719.EditIssueCubit(
      gh<_i216.GetIssueByIdUseCase>(),
      gh<_i812.UpdateIssueUseCase>(),
    ),
  );
  return getIt;
}

class _$ConfigModule extends _i956.ConfigModule {}

class _$CoreModule extends _i1008.CoreModule {}
