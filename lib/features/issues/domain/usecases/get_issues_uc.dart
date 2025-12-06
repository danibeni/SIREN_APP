import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart'
    as issue_entities;
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';

/// Use case for retrieving issues list.
@lazySingleton
class GetIssuesUseCase {
  final IssueRepository _repository;

  GetIssuesUseCase(this._repository);

  Future<Either<Failure, List<issue_entities.IssueEntity>>> call({
    issue_entities.IssueStatus? status,
    int? equipmentId,
    issue_entities.PriorityLevel? priorityLevel,
    int? groupId,
  }) {
    return _repository.getIssues(
      status: status,
      equipmentId: equipmentId,
      priorityLevel: priorityLevel,
      groupId: groupId,
    );
  }
}
