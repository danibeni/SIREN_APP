import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';

/// Use case for discarding local changes for an issue
///
/// Removes pending modifications and restores issue from server cache
/// Returns restored IssueEntity on success
@lazySingleton
class DiscardLocalChangesUseCase {
  final IssueRepository repository;

  DiscardLocalChangesUseCase(this.repository);

  /// Execute discard local changes use case
  ///
  /// Restores issue from server cache and clears pending sync status
  /// Returns Either<Failure, IssueEntity>
  Future<Either<Failure, IssueEntity>> call(int issueId) async {
    return await repository.discardLocalChanges(issueId);
  }
}
