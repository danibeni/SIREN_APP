import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import '../datasources/issue_local_datasource.dart';
import '../datasources/issue_remote_datasource.dart';
import '../models/issue_model.dart';

/// Implementation of IssueRepository
///
/// Connects the domain layer with the data layer by calling the remote
/// data source and mapping responses to domain entities.
/// For MVP: Implements basic cache (3 screenfuls) with offline read access.
@LazySingleton(as: IssueRepository)
class IssueRepositoryImpl implements IssueRepository {
  final IssueRemoteDataSource remoteDataSource;
  final IssueLocalDataSource localDataSource;
  final Logger logger;

  IssueRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.logger,
  });

  @override
  Future<Either<Failure, IssueEntity>> createIssue({
    required String subject,
    String? description,
    required int equipment,
    required int group,
    required PriorityLevel priorityLevel,
  }) async {
    try {
      final responseMap = await remoteDataSource.createIssue(
        subject: subject,
        description: description,
        equipment: equipment,
        group: group,
        priorityLevel: priorityLevel,
      );

      // Parse response and convert to entity
      final model = IssueModel.fromJson(responseMap);

      // Set group from parameter since API doesn't return it directly
      final entityWithGroup = model.copyWith(group: group).toEntity();

      return Right(entityWithGroup);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkFailure catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, IssueEntity>> getIssueById(int id) async {
    try {
      final responseMap = await remoteDataSource.getIssueById(id);

      final model = IssueModel.fromJson(responseMap);
      return Right(model.toEntity());
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkFailure catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<IssueEntity>>> getIssues({
    IssueStatus? status,
    int? equipmentId,
    PriorityLevel? priorityLevel,
    int? groupId,
    required String workPackageType,
  }) async {
    try {
      // Map IssueStatus to API status ID
      int? statusId;
      if (status != null) {
        statusId = _mapStatusToId(status);
      }

      // Resolve Work Package Type name to ID
      // Get all available types from OpenProject (global types, not project-specific)
      int? typeId;
      try {
        // Use getTypes() to get all global types instead of project-specific types
        final types = await remoteDataSource.getTypes();

        // Find type by name (case-insensitive)
        final matchingType = types.firstWhere(
          (type) =>
              (type['name'] as String?)?.toLowerCase() ==
              workPackageType.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );

        if (matchingType.isNotEmpty) {
          typeId = matchingType['id'] as int?;
        } else {
          throw ServerFailure(
            'Work Package Type "$workPackageType" not found in OpenProject. '
            'Please configure a valid type in Settings.',
          );
        }
      } catch (e) {
        // If type resolution fails, return failure instead of continuing
        // This ensures we only show issues of the configured type
        return Left(
          ServerFailure('Failed to resolve Work Package Type: ${e.toString()}'),
        );
      }

      List<Map<String, dynamic>> responseList;
      try {
        // Try to fetch from server
        responseList = await remoteDataSource.getIssues(
          status: statusId,
          equipmentId: equipmentId,
          priorityLevel: priorityLevel,
          groupId: groupId,
          typeId: typeId,
        );

        // Cache the fetched issues (limited to 3 screenfuls)
        await localDataSource.cacheIssues(responseList);
        logger.info(
          'Successfully fetched and cached ${responseList.length} issues',
        );
      } on NetworkFailure catch (e) {
        // If network fails, try to load from cache
        logger.warning(
          'Network failure, attempting to load from cache: ${e.message}',
        );
        final cached = await localDataSource.getCachedIssues();
        if (cached != null && cached.isNotEmpty) {
          logger.info('Loaded ${cached.length} issues from cache');
          responseList = cached;
        } else {
          return Left(
            NetworkFailure(
              'No internet connection and no cached data available',
            ),
          );
        }
      }

      // Convert each map to entity and sort by updatedAt (most recent first)
      final entities = responseList
          .map((map) => IssueModel.fromJson(map).toEntity())
          .toList();

      // Sort by updatedAt, most recent first
      entities.sort((a, b) {
        if (a.updatedAt == null && b.updatedAt == null) return 0;
        if (a.updatedAt == null) return 1;
        if (b.updatedAt == null) return -1;
        return b.updatedAt!.compareTo(a.updatedAt!);
      });

      return Right(entities);
    } on ServerFailure catch (e) {
      // Try cache as fallback for server errors
      logger.warning(
        'Server failure, attempting to load from cache: ${e.message}',
      );
      try {
        final cached = await localDataSource.getCachedIssues();
        if (cached != null && cached.isNotEmpty) {
          logger.info(
            'Loaded ${cached.length} issues from cache after server failure',
          );
          final entities = cached
              .map((map) => IssueModel.fromJson(map).toEntity())
              .toList();
          entities.sort((a, b) {
            if (a.updatedAt == null && b.updatedAt == null) return 0;
            if (a.updatedAt == null) return 1;
            if (b.updatedAt == null) return -1;
            return b.updatedAt!.compareTo(a.updatedAt!);
          });
          return Right(entities);
        }
      } catch (cacheError) {
        logger.severe('Failed to load from cache: $cacheError');
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, IssueEntity>> updateIssue({
    required int id,
    required int lockVersion,
    String? subject,
    String? description,
    PriorityLevel? priorityLevel,
    IssueStatus? status,
  }) async {
    try {
      final responseMap = await remoteDataSource.updateIssue(
        id: id,
        lockVersion: lockVersion,
        subject: subject,
        description: description,
        priorityLevel: priorityLevel,
        status: status,
      );

      final model = IssueModel.fromJson(responseMap);
      return Right(model.toEntity());
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkFailure catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addAttachment({
    required int issueId,
    required String filePath,
    required String fileName,
    String? description,
  }) async {
    try {
      await remoteDataSource.addAttachment(
        issueId: issueId,
        filePath: filePath,
        fileName: fileName,
        description: description,
      );
      return const Right(null);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkFailure catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> getAttachments(int issueId) async {
    try {
      // For MVP: Just return attachment metadata from remote data source
      // Future: Check local cache first, download and cache attachments ≤ 5 MB
      final attachments = await remoteDataSource.getAttachments(issueId);
      return Right(attachments);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkFailure catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }

  /// Map IssueStatus enum to OpenProject status ID
  int _mapStatusToId(IssueStatus status) {
    switch (status) {
      case IssueStatus.newStatus:
        return 1;
      case IssueStatus.inProgress:
        return 2;
      case IssueStatus.onHold:
        return 3;
      case IssueStatus.closed:
        return 4;
      case IssueStatus.rejected:
        return 5;
    }
  }
}
