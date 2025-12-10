import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/status_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';

/// Use case for retrieving available statuses for a specific work package.
///
/// Uses the work package form endpoint to get statuses available for the
/// specific type and current state of the work package, filtered by workflow rules.
@lazySingleton
class GetAvailableStatusesForIssueUseCase {
  final IssueRepository _repository;

  GetAvailableStatusesForIssueUseCase(this._repository);

  Future<Either<Failure, List<StatusEntity>>> call({
    required int workPackageId,
    required int lockVersion,
  }) {
    return _repository.getAvailableStatusesForIssue(
      workPackageId: workPackageId,
      lockVersion: lockVersion,
    );
  }
}
