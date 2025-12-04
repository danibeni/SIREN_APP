import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';

/// Use case for creating a new issue
///
/// This use case validates all mandatory fields before calling the repository.
/// Mandatory fields: Subject, Priority Level, Group, Equipment
///
/// Returns [ValidationFailure] if any mandatory field is missing or invalid.
/// Returns the repository result (success or failure) if validation passes.
@lazySingleton
class CreateIssueUseCase {
  final IssueRepository repository;

  CreateIssueUseCase(this.repository);

  /// Execute the use case with the given parameters
  ///
  /// Validates mandatory fields in order:
  /// 1. Subject (required, non-empty after trimming)
  /// 2. Priority Level (required)
  /// 3. Group (required, must be > 0)
  /// 4. Equipment (required, must be > 0)
  Future<Either<Failure, IssueEntity>> call(CreateIssueParams params) async {
    // Validate Subject
    final trimmedSubject = params.subject.trim();
    if (trimmedSubject.isEmpty) {
      return const Left(ValidationFailure('Subject is required'));
    }

    // Validate Priority Level
    if (params.priorityLevel == null) {
      return const Left(ValidationFailure('Priority Level is required'));
    }

    // Validate Group
    if (params.group == null || params.group == 0) {
      return const Left(ValidationFailure('Group is required'));
    }

    // Validate Equipment
    if (params.equipment == null || params.equipment == 0) {
      return const Left(ValidationFailure('Equipment is required'));
    }

    // All validations passed, call repository
    return await repository.createIssue(
      subject: trimmedSubject,
      description: params.description?.trim(),
      equipment: params.equipment!,
      group: params.group!,
      priorityLevel: params.priorityLevel!,
    );
  }
}

/// Parameters for creating an issue
///
/// Contains all fields needed to create a new issue.
/// Nullable fields allow for validation to report specific missing fields.
class CreateIssueParams extends Equatable {
  /// Issue title/subject (required)
  final String subject;

  /// Issue description (optional)
  final String? description;

  /// Priority level (required)
  final PriorityLevel? priorityLevel;

  /// Group ID (required)
  final int? group;

  /// Equipment/Project ID (required)
  final int? equipment;

  const CreateIssueParams({
    required this.subject,
    this.description,
    this.priorityLevel,
    this.group,
    this.equipment,
  });

  @override
  List<Object?> get props => [
    subject,
    description,
    priorityLevel,
    group,
    equipment,
  ];
}
