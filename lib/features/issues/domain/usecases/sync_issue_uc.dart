import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';

/// Use case for synchronizing an issue with pending offline modifications
///
/// Uploads local changes and pending attachments to the server
/// Returns updated IssueEntity on success
@lazySingleton
class SyncIssueUseCase {
  final IssueRepository repository;

  SyncIssueUseCase(this.repository);

  /// Execute sync issue use case
  ///
  /// Synchronizes local modifications with the server
  /// Returns Either<Failure, IssueEntity>
  Future<Either<Failure, IssueEntity>> call(int issueId) async {
    return await repository.syncIssue(issueId);
  }
}
