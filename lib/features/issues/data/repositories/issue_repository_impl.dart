import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import '../datasources/issue_remote_datasource.dart';
import '../models/issue_model.dart';

/// Implementation of IssueRepository
///
/// Connects the domain layer with the data layer by calling the remote
/// data source and mapping responses to domain entities.
@LazySingleton(as: IssueRepository)
class IssueRepositoryImpl implements IssueRepository {
  final IssueRemoteDataSource remoteDataSource;

  IssueRepositoryImpl({required this.remoteDataSource});

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
  }) async {
    try {
      // Map IssueStatus to API status ID
      int? statusId;
      if (status != null) {
        statusId = _mapStatusToId(status);
      }

      final responseList = await remoteDataSource.getIssues(
        status: statusId,
        equipmentId: equipmentId,
        priorityLevel: priorityLevel,
        groupId: groupId,
      );

      // Convert each map to entity
      final entities = responseList
          .map((map) => IssueModel.fromJson(map).toEntity())
          .toList();

      return Right(entities);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkFailure catch (e) {
      return Left(NetworkFailure(e.message));
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

  /// Map IssueStatus enum to OpenProject status ID
  int _mapStatusToId(IssueStatus status) {
    switch (status) {
      case IssueStatus.newStatus:
        return 1;
      case IssueStatus.inProgress:
        return 2;
      case IssueStatus.closed:
        return 3;
    }
  }
}
