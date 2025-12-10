import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/entities/status_entity.dart';

/// Parameters for updating an existing issue
///
/// Encapsulates all data needed to update an issue through OpenProject API
/// Only the fields that are provided (non-null) will be updated
class UpdateIssueParams {
  final int id;
  final int lockVersion;
  final String? subject;
  final String? description;
  final PriorityLevel? priorityLevel;
  final IssueStatus? status;
  final StatusEntity? statusEntity;

  const UpdateIssueParams({
    required this.id,
    required this.lockVersion,
    this.subject,
    this.description,
    this.priorityLevel,
    this.status,
    this.statusEntity,
  });
}
