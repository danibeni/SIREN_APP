import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import 'package:siren_app/features/issues/domain/usecases/update_issue_params.dart';

/// Use case for updating an existing issue.
@lazySingleton
class UpdateIssueUseCase {
  final IssueRepository repository;

  UpdateIssueUseCase(this.repository);

  Future<Either<Failure, IssueEntity>> call(UpdateIssueParams params) async {
    // Validate subject when provided
    if (params.subject != null) {
      final trimmed = params.subject!.trim();
      if (trimmed.isEmpty) {
        return const Left(ValidationFailure('Subject cannot be empty'));
      }
    }

    return repository.updateIssue(
      id: params.id,
      lockVersion: params.lockVersion,
      subject: params.subject?.trim(),
      description: params.description,
      priorityLevel: params.priorityLevel,
      status: params.status,
    );
  }
}
