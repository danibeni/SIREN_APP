import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/attachment_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';

/// Use case for retrieving attachments for an issue
@lazySingleton
class GetAttachmentsUseCase {
  final IssueRepository repository;

  GetAttachmentsUseCase(this.repository);

  /// Get all attachments for the specified issue
  ///
  /// Returns Either of Failure or List of AttachmentEntity
  /// - Right: List of attachments (may be empty)
  /// - Left: Failure (NetworkFailure, ServerFailure, NotFoundFailure)
  Future<Either<Failure, List<AttachmentEntity>>> call(int issueId) async {
    return await repository.getAttachments(issueId);
  }
}
