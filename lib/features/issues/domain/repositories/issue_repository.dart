import 'package:dartz/dartz.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/attachment_entity.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

/// Repository interface for Issue management
///
/// This interface defines the contract for issue operations following Clean Architecture.
/// The implementation will be provided in the Data layer.
abstract class IssueRepository {
  /// Retrieve all issues accessible to the authenticated user
  ///
  /// Returns issues filtered by user's authorized Groups/Departments
  /// (enforced by OpenProject API group-based access control)
  ///
  /// [workPackageType] - REQUIRED: Work Package Type name from Settings (default: "Issue")
  /// This filter is always applied to ensure only work packages of the configured type are retrieved
  Future<Either<Failure, List<IssueEntity>>> getIssues({
    IssueStatus? status,
    int? equipmentId,
    PriorityLevel? priorityLevel,
    int? groupId,
    required String workPackageType,
  });

  /// Retrieve a single issue by ID
  ///
  /// Must capture lockVersion for subsequent updates
  Future<Either<Failure, IssueEntity>> getIssueById(int id);

  /// Create a new issue
  ///
  /// Validates mandatory fields: Subject, Priority Level, Group, Equipment
  /// Automatically sets status to "New" and associates creator with authenticated user
  Future<Either<Failure, IssueEntity>> createIssue({
    required String subject,
    String? description,
    required int equipment,
    required int group,
    required PriorityLevel priorityLevel,
  });

  /// Update an existing issue
  ///
  /// Updates: Subject, Description, Priority Level, Status
  /// Note: Group and Equipment fields are read-only and must not be included
  /// Requires lockVersion for optimistic locking
  Future<Either<Failure, IssueEntity>> updateIssue({
    required int id,
    required int lockVersion,
    String? subject,
    String? description,
    PriorityLevel? priorityLevel,
    IssueStatus? status,
  });

  /// Add attachment to an issue
  ///
  /// Used for uploading photos/documents for issue resolution
  /// Returns AttachmentEntity on success
  Future<Either<Failure, AttachmentEntity>> addAttachment({
    required int issueId,
    required String filePath,
    required String fileName,
    String? description,
  });

  /// Get all attachments for an issue
  ///
  /// Returns list of attachment metadata (fileName, fileSize, contentType, downloadUrl)
  /// Checks local cache first when offline
  /// Used for displaying attachments in issue detail and edit pages
  Future<Either<Failure, List<AttachmentEntity>>> getAttachments(int issueId);

  /// Synchronize an issue with pending offline modifications
  ///
  /// Uploads local changes and pending attachments to the server
  /// Returns updated IssueEntity on success
  Future<Either<Failure, IssueEntity>> syncIssue(int issueId);

  /// Discard local changes for an issue and restore server version
  ///
  /// Removes pending modifications and restores issue from cache
  /// Returns restored IssueEntity on success
  Future<Either<Failure, IssueEntity>> discardLocalChanges(int issueId);
}
