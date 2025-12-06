import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart'
    as issue_entities;
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import 'package:siren_app/features/issues/domain/usecases/get_work_package_type_uc.dart';

/// Use case for retrieving issues list.
///
/// Automatically applies the Work Package Type filter configured in Settings.
/// This ensures that only issues of the configured type are retrieved.
@lazySingleton
class GetIssuesUseCase {
  final IssueRepository _repository;
  final GetWorkPackageTypeUseCase _getWorkPackageTypeUseCase;

  GetIssuesUseCase(this._repository, this._getWorkPackageTypeUseCase);

  Future<Either<Failure, List<issue_entities.IssueEntity>>> call({
    issue_entities.IssueStatus? status,
    int? equipmentId,
    issue_entities.PriorityLevel? priorityLevel,
    int? groupId,
  }) async {
    // Get configured Work Package Type from Settings
    final typeResult = await _getWorkPackageTypeUseCase();

    // If type retrieval fails, return failure
    return typeResult.fold((failure) => Left(failure), (typeName) async {
      // Call repository with Type filter
      return _repository.getIssues(
        status: status,
        equipmentId: equipmentId,
        priorityLevel: priorityLevel,
        groupId: groupId,
        workPackageType: typeName,
      );
    });
  }
}
