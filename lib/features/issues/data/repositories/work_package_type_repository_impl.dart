import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/data/datasources/issue_remote_datasource.dart';
import 'package:siren_app/features/issues/data/datasources/work_package_type_local_datasource.dart';
import 'package:siren_app/features/issues/data/models/status_model.dart';
import 'package:siren_app/features/issues/data/models/work_package_type_model.dart';
import 'package:siren_app/features/issues/domain/entities/status_entity.dart';
import 'package:siren_app/features/issues/domain/entities/work_package_type_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/work_package_type_repository.dart';

/// Repository implementation for Work Package Type configuration.
@LazySingleton(as: WorkPackageTypeRepository)
class WorkPackageTypeRepositoryImpl implements WorkPackageTypeRepository {
  WorkPackageTypeRepositoryImpl({
    required IssueRemoteDataSource remoteDataSource,
    required WorkPackageTypeLocalDataSource localDataSource,
    required Logger logger,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _logger = logger;

  final IssueRemoteDataSource _remoteDataSource;
  final WorkPackageTypeLocalDataSource _localDataSource;
  final Logger _logger;

  @override
  Future<Either<Failure, List<WorkPackageTypeEntity>>>
  getAvailableTypes() async {
    try {
      final response = await _remoteDataSource.getTypes();
      final models = response
          .map((map) => WorkPackageTypeModel.fromJson(map))
          .toList();
      return Right(models.map((model) => model.toEntity()).toList());
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkFailure catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Failed to load types: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getSelectedType() async {
    try {
      final typeName = await _localDataSource.getSelectedType();
      return Right(typeName);
    } catch (e) {
      _logger.severe('Failed to read selected type: $e');
      return Left(CacheFailure('Failed to read selected type: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setSelectedType(String typeName) async {
    final trimmed = typeName.trim();
    if (trimmed.isEmpty) {
      return const Left(
        ValidationFailure('Work Package Type name cannot be empty'),
      );
    }

    try {
      await _localDataSource.setSelectedType(trimmed);
      await _localDataSource.clearStatusesCache(trimmed);
      return const Right(null);
    } catch (e) {
      _logger.severe('Failed to store selected type: $e');
      return Left(CacheFailure('Failed to store selected type: $e'));
    }
  }

  @override
  Future<Either<Failure, List<StatusEntity>>>
  getStatusesForSelectedType() async {
    try {
      final typeName = await _localDataSource.getSelectedType();

      final cached = await _localDataSource.getCachedStatuses(typeName);
      if (cached != null) {
        final cachedModels = cached
            .map((map) => StatusModel.fromJson(map))
            .toList();
        return Right(cachedModels.map((model) => model.toEntity()).toList());
      }

      final remote = await _remoteDataSource.getStatuses();
      final remoteModels = remote
          .map((map) => StatusModel.fromJson(map))
          .toList();

      await _localDataSource.cacheStatuses(
        typeName,
        remoteModels.map((model) => model.toJson()).toList(),
      );

      return Right(remoteModels.map((model) => model.toEntity()).toList());
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkFailure catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      _logger.severe('Failed to load statuses: $e');
      return Left(UnexpectedFailure('Failed to load statuses: $e'));
    }
  }
}
