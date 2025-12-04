import '../../domain/entities/issue_entity.dart';

/// Data Transfer Object for Issue/Work Package
///
/// Maps OpenProject API v3 JSON responses to internal domain entities.
/// Handles HATEOAS `_links` structure for resource references.
class IssueModel {
  final int? id;
  final String subject;
  final String? description;
  final int equipment; // OpenProject project ID
  final int group; // OpenProject group ID
  final PriorityLevel priorityLevel;
  final IssueStatus status;
  final int? creatorId;
  final String? creatorName;
  final int lockVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const IssueModel({
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

  /// Create IssueModel from OpenProject API JSON response
  ///
  /// Parses HATEOAS _links structure to extract related resource IDs
  factory IssueModel.fromJson(Map<String, dynamic> json) {
    // Extract description from nested structure
    final descriptionObj = json['description'] as Map<String, dynamic>?;
    final description = descriptionObj?['raw'] as String?;

    // Extract project (equipment) ID from _links
    final links = json['_links'] as Map<String, dynamic>?;
    final projectLink = links?['project'] as Map<String, dynamic>?;
    final projectHref = projectLink?['href'] as String?;
    final equipment = _extractIdFromHref(projectHref) ?? 0;

    // Extract priority from _links and map to enum
    final priorityLink = links?['priority'] as Map<String, dynamic>?;
    final priorityHref = priorityLink?['href'] as String?;
    final priorityId = _extractIdFromHref(priorityHref);
    final priorityLevel = _mapIdToPriority(priorityId);

    // Extract status from _links and map to enum
    final statusLink = links?['status'] as Map<String, dynamic>?;
    final statusHref = statusLink?['href'] as String?;
    final statusId = _extractIdFromHref(statusHref);
    final status = _mapIdToStatus(statusId);

    // Extract creator/author from _links
    final authorLink = links?['author'] as Map<String, dynamic>?;
    final authorHref = authorLink?['href'] as String?;
    final creatorId = _extractIdFromHref(authorHref);
    final creatorName = authorLink?['title'] as String?;

    // Parse dates
    final createdAt = _parseDateTime(json['createdAt'] as String?);
    final updatedAt = _parseDateTime(json['updatedAt'] as String?);

    return IssueModel(
      id: json['id'] as int?,
      subject: json['subject'] as String,
      description: description,
      equipment: equipment,
      group: 0, // Group is determined from project membership
      priorityLevel: priorityLevel,
      status: status,
      creatorId: creatorId,
      creatorName: creatorName,
      lockVersion: json['lockVersion'] as int? ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert to JSON for API requests (create/update)
  ///
  /// Builds HATEOAS _links structure for OpenProject API
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'subject': subject,
      '_links': {
        'project': {'href': '/api/v3/projects/$equipment'},
        'priority': {
          'href': '/api/v3/priorities/${_mapPriorityToId(priorityLevel)}',
        },
        'status': {'href': '/api/v3/statuses/${_mapStatusToId(status)}'},
      },
    };

    if (description != null && description!.isNotEmpty) {
      json['description'] = {'format': 'markdown', 'raw': description};
    }

    if (lockVersion > 0) {
      json['lockVersion'] = lockVersion;
    }

    return json;
  }

  /// Convert to domain entity
  IssueEntity toEntity() {
    return IssueEntity(
      id: id,
      subject: subject,
      description: description,
      equipment: equipment,
      group: group,
      priorityLevel: priorityLevel,
      status: status,
      creatorId: creatorId,
      creatorName: creatorName,
      lockVersion: lockVersion,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create copy with updated fields
  IssueModel copyWith({
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
    return IssueModel(
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

  // --- Static helper methods ---

  /// Extract numeric ID from HATEOAS href (e.g., '/api/v3/projects/42' -> 42)
  static int? _extractIdFromHref(String? href) {
    if (href == null || href.isEmpty) return null;
    final segments = href.split('/');
    if (segments.isEmpty) return null;
    return int.tryParse(segments.last);
  }

  /// Parse ISO 8601 datetime string
  static DateTime? _parseDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Map OpenProject priority ID to PriorityLevel enum
  static PriorityLevel _mapIdToPriority(int? id) {
    switch (id) {
      case 1:
        return PriorityLevel.low;
      case 2:
        return PriorityLevel.normal;
      case 3:
        return PriorityLevel.high;
      case 4:
        return PriorityLevel.immediate;
      default:
        return PriorityLevel.normal;
    }
  }

  /// Map PriorityLevel enum to OpenProject priority ID
  static int _mapPriorityToId(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.low:
        return 1;
      case PriorityLevel.normal:
        return 2;
      case PriorityLevel.high:
        return 3;
      case PriorityLevel.immediate:
        return 4;
    }
  }

  /// Map OpenProject status ID to IssueStatus enum
  static IssueStatus _mapIdToStatus(int? id) {
    switch (id) {
      case 1:
        return IssueStatus.newStatus;
      case 2:
        return IssueStatus.inProgress;
      case 3:
        return IssueStatus.closed;
      default:
        return IssueStatus.newStatus;
    }
  }

  /// Map IssueStatus enum to OpenProject status ID
  static int _mapStatusToId(IssueStatus status) {
    switch (status) {
      case IssueStatus.newStatus:
        return 1;
      case IssueStatus.inProgress:
        return 2;
      case IssueStatus.closed:
        return 3;
    }
  }
}
