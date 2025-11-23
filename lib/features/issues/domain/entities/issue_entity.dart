import 'package:equatable/equatable.dart';

/// Priority levels for issues
enum PriorityLevel {
  low,
  normal,
  high,
  immediate,
}

/// Status values for issues
enum IssueStatus {
  newStatus,
  inProgress,
  closed,
}

/// Pure business entity representing an Issue
/// 
/// This is a domain entity following Clean Architecture principles.
/// It contains no framework dependencies and represents the core business object.
/// 
/// Fields:
/// - Subject: Required, user input (free text)
/// - Description: Optional, user input (free text)
/// - Equipment: Required, OpenProject project ID (equipment)
/// - Group: Required, OpenProject group ID (department)
/// - Priority Level: Required, one of: Low, Normal, High, Immediate
/// - Status: Automatically set to "New" on creation
/// - Creator: Automatically associated by OpenProject with authenticated user
/// - lockVersion: Required for optimistic locking when updating issues
class IssueEntity extends Equatable {
  final int? id;
  final String subject;
  final String? description;
  final int equipment; // OpenProject project ID
  final int group; // OpenProject group ID
  final PriorityLevel priorityLevel;
  final IssueStatus status;
  final int? creatorId; // OpenProject user ID
  final String? creatorName;
  final int lockVersion; // Required for optimistic locking
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const IssueEntity({
    this.id,
    required this.subject,
    this.description,
    required this.equipment,
    required this.group,
    required this.priorityLevel,
    required this.status,
    this.creatorId,
    this.creatorName,
    required this.lockVersion,
    this.createdAt,
    this.updatedAt,
  });

  /// Create a copy of this entity with updated fields
  IssueEntity copyWith({
    int? id,
    String? subject,
    String? description,
    int? equipment,
    int? group,
    PriorityLevel? priorityLevel,
    IssueStatus? status,
    int? creatorId,
    String? creatorName,
    int? lockVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IssueEntity(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      equipment: equipment ?? this.equipment,
      group: group ?? this.group,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      status: status ?? this.status,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      lockVersion: lockVersion ?? this.lockVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        subject,
        description,
        equipment,
        group,
        priorityLevel,
        status,
        creatorId,
        creatorName,
        lockVersion,
        createdAt,
        updatedAt,
      ];
}

