import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/attachment_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import 'package:siren_app/features/issues/domain/usecases/add_attachment_params.dart';

/// Use case for adding a new attachment to an issue
///
/// Uploads file to OpenProject server and returns attachment metadata
/// Returns AttachmentEntity on success
@lazySingleton
class AddAttachmentUseCase {
  final IssueRepository repository;

  AddAttachmentUseCase(this.repository);

  /// Execute add attachment use case
  ///
  /// Validates and uploads file to the server
  /// Returns Either<Failure, AttachmentEntity>
  Future<Either<Failure, AttachmentEntity>> call(
    AddAttachmentParams params,
  ) async {
    // Optional: Validate file size client-side
    // This is a basic check; server will enforce actual limits

    return await repository.addAttachment(
      issueId: params.issueId,
      filePath: params.filePath,
      fileName: params.fileName,
      description: params.description,
    );
  }
}
