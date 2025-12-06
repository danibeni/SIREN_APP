import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

/// Parameters for updating an issue.
class UpdateIssueParams {
  final int id;
  final int lockVersion;
  final String? subject;
  final String? description;
  final PriorityLevel? priorityLevel;
  final IssueStatus? status;

  const UpdateIssueParams({
    required this.id,
    required this.lockVersion,
    this.subject,
    this.description,
    this.priorityLevel,
    this.status,
  });
}
