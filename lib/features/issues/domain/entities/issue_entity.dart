import 'package:equatable/equatable.dart';

/// Priority levels for issues
enum PriorityLevel { low, normal, high, immediate }

/// Status values for issues
enum IssueStatus { newStatus, inProgress, onHold, closed, rejected }

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
  final String? statusName;
  final String? statusColorHex;
  final int? creatorId; // OpenProject user ID
  final String? creatorName;
  final int? updatedById;
  final String? updatedByName;
  final int lockVersion; // Required for optimistic locking
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? equipmentName;

  const IssueEntity({
    this.id,
    required this.subject,
    this.description,
    required this.equipment,
    required this.group,
    required this.priorityLevel,
    required this.status,
    this.statusName,
    this.statusColorHex,
    this.creatorId,
    this.creatorName,
    this.updatedById,
    this.updatedByName,
    required this.lockVersion,
    this.createdAt,
    this.updatedAt,
    this.equipmentName,
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
    int? updatedById,
    String? updatedByName,
    String? statusName,
    String? statusColorHex,
    int? lockVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? equipmentName,
  }) {
    return IssueEntity(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      equipment: equipment ?? this.equipment,
      group: group ?? this.group,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      status: status ?? this.status,
      statusName: statusName ?? this.statusName,
      statusColorHex: statusColorHex ?? this.statusColorHex,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      updatedById: updatedById ?? this.updatedById,
      updatedByName: updatedByName ?? this.updatedByName,
      lockVersion: lockVersion ?? this.lockVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      equipmentName: equipmentName ?? this.equipmentName,
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
    statusName,
    statusColorHex,
    creatorId,
    creatorName,
    updatedById,
    updatedByName,
    lockVersion,
    createdAt,
    updatedAt,
    equipmentName,
  ];
}
