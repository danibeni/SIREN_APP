import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

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
  final String? statusName;
  final String? statusColorHex;
  final int? creatorId;
  final String? creatorName;
  final int? updatedById;
  final String? updatedByName;
  final int lockVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? equipmentName;

  const IssueModel({
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

  /// Create IssueModel from OpenProject API JSON response
  ///
  /// Parses HATEOAS _links structure to extract related resource data.
  /// IMPORTANT: Maps priority and status by NAME (title), not by ID,
  /// because OpenProject IDs vary between installations.
  factory IssueModel.fromJson(Map<String, dynamic> json) {
    // Extract description from nested structure
    final descriptionObj = json['description'] as Map<String, dynamic>?;
    final description = descriptionObj?['raw'] as String?;

    // Extract project (equipment) ID from _links
    final links = json['_links'] as Map<String, dynamic>?;
    final projectLink = links?['project'] as Map<String, dynamic>?;
    final projectHref = projectLink?['href'] as String?;
    final equipment = _extractIdFromHref(projectHref) ?? 0;
    final equipmentName = projectLink?['title'] as String?;

    // Extract priority from _links and map by NAME (title), not ID
    final priorityLink = links?['priority'] as Map<String, dynamic>?;
    final priorityTitle = priorityLink?['title'] as String?;
    final priorityLevel = _mapNameToPriority(priorityTitle);

    // Extract status from _links and map by NAME (title), not ID
    final statusLink = links?['status'] as Map<String, dynamic>?;
    final statusTitle = statusLink?['title'] as String?;
    final status = _mapNameToStatus(statusTitle);

    String? statusColorHex;
    final embedded = json['_embedded'] as Map<String, dynamic>?;
    final embeddedStatus = embedded?['status'] as Map<String, dynamic>?;
    if (embeddedStatus != null) {
      statusColorHex = embeddedStatus['color'] as String?;
    }

    // Extract creator/author from _links
    final authorLink = links?['author'] as Map<String, dynamic>?;
    final authorHref = authorLink?['href'] as String?;
    final creatorId = _extractIdFromHref(authorHref);
    final creatorName = authorLink?['title'] as String?;

    final updatedByLink = links?['updatedBy'] as Map<String, dynamic>?;
    final updatedByHref = updatedByLink?['href'] as String?;
    final updatedById = _extractIdFromHref(updatedByHref);
    final updatedByName = updatedByLink?['title'] as String?;

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
      statusName: statusTitle,
      statusColorHex: statusColorHex,
      creatorId: creatorId,
      creatorName: creatorName,
      updatedById: updatedById,
      updatedByName: updatedByName,
      lockVersion: json['lockVersion'] as int? ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
      equipmentName: equipmentName,
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
      statusName: statusName,
      statusColorHex: statusColorHex,
      creatorId: creatorId,
      creatorName: creatorName,
      updatedById: updatedById,
      updatedByName: updatedByName,
      lockVersion: lockVersion,
      createdAt: createdAt,
      updatedAt: updatedAt,
      equipmentName: equipmentName,
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
    String? statusName,
    String? statusColorHex,
    int? creatorId,
    String? creatorName,
    int? updatedById,
    String? updatedByName,
    int? lockVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? equipmentName,
  }) {
    return IssueModel(
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

  /// Map OpenProject priority name (title) to PriorityLevel enum.
  /// Uses case-insensitive matching as names are consistent across installations.
  static PriorityLevel _mapNameToPriority(String? name) {
    if (name == null || name.isEmpty) return PriorityLevel.normal;

    final lowerName = name.toLowerCase();
    if (lowerName.contains('low')) {
      return PriorityLevel.low;
    } else if (lowerName.contains('immediate')) {
      return PriorityLevel.immediate;
    } else if (lowerName.contains('high')) {
      return PriorityLevel.high;
    } else if (lowerName.contains('normal')) {
      return PriorityLevel.normal;
    }
    return PriorityLevel.normal;
  }

  /// Map OpenProject status name (title) to IssueStatus enum.
  /// Uses case-insensitive matching as names are consistent across installations.
  /// Supports 5 status values: New, In Progress, On Hold, Closed, Rejected.
  static IssueStatus _mapNameToStatus(String? name) {
    if (name == null || name.isEmpty) return IssueStatus.newStatus;

    final lowerName = name.toLowerCase();
    if (lowerName.contains('rejected') || lowerName.contains('rechazad')) {
      return IssueStatus.rejected;
    } else if (lowerName.contains('closed') || lowerName.contains('cerrad')) {
      return IssueStatus.closed;
    } else if (lowerName.contains('hold') || lowerName.contains('esper')) {
      return IssueStatus.onHold;
    } else if (lowerName.contains('progress') || lowerName.contains('curso')) {
      return IssueStatus.inProgress;
    } else if (lowerName.contains('new') || lowerName.contains('nuev')) {
      return IssueStatus.newStatus;
    }
    return IssueStatus.newStatus;
  }

  /// Map PriorityLevel enum to OpenProject priority ID (fallback only).
  /// IMPORTANT: Use _getPriorityHref in data source for dynamic ID resolution.
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

  /// Map IssueStatus enum to OpenProject status ID (fallback only).
  /// IMPORTANT: Status IDs should be fetched dynamically from /api/v3/statuses.
  static int _mapStatusToId(IssueStatus status) {
    switch (status) {
      case IssueStatus.newStatus:
        return 1;
      case IssueStatus.inProgress:
        return 2;
      case IssueStatus.onHold:
        return 3;
      case IssueStatus.closed:
        return 4;
      case IssueStatus.rejected:
        return 5;
    }
  }
}
