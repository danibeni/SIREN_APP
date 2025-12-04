import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

/// Helper class for generating test data (fixtures) for IssueEntity
class IssueFixtures {
  /// Create a sample IssueEntity with default test values
  static IssueEntity createIssueEntity({
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
      id: id ?? 1,
      subject: subject ?? 'Test Issue Subject',
      description: description ?? 'Test Issue Description',
      equipment: equipment ?? 100,
      group: group ?? 10,
      priorityLevel: priorityLevel ?? PriorityLevel.normal,
      status: status ?? IssueStatus.newStatus,
      creatorId: creatorId ?? 1,
      creatorName: creatorName ?? 'Test User',
      lockVersion: lockVersion ?? 0,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 1),
    );
  }

  /// Create a list of sample IssueEntity objects
  static List<IssueEntity> createIssueEntityList({
    int count = 3,
  }) {
    return List.generate(
      count,
      (index) => createIssueEntity(
        id: index + 1,
        subject: 'Test Issue ${index + 1}',
        description: 'Description for issue ${index + 1}',
        equipment: 100 + index,
        group: 10,
        priorityLevel: PriorityLevel.values[index % PriorityLevel.values.length],
        status: IssueStatus.values[index % IssueStatus.values.length],
        lockVersion: index,
      ),
    );
  }

  /// Create a sample OpenProject API response map for a work package.
  /// IMPORTANT: priorityTitle and statusTitle are used for mapping (not IDs).
  static Map<String, dynamic> createWorkPackageMap({
    int? id,
    String? subject,
    String? description,
    int? projectId,
    int? groupId,
    int? priorityId,
    String? priorityTitle,
    int? statusId,
    String? statusTitle,
    int? creatorId,
    String? creatorName,
    int? lockVersion,
    String? createdAt,
    String? updatedAt,
  }) {
    return {
      'id': id ?? 1,
      'subject': subject ?? 'Test Issue Subject',
      'description': description != null
          ? {
              'format': 'markdown',
              'raw': description,
              'html': '<p>$description</p>',
            }
          : null,
      '_links': {
        'project': {
          'href': '/api/v3/projects/${projectId ?? 100}',
          'title': 'Test Project',
        },
        'type': {
          'href': '/api/v3/types/1',
          'title': 'Task',
        },
        'priority': {
          'href': '/api/v3/priorities/${priorityId ?? 8}',
          'title': priorityTitle ?? 'Normal',
        },
        'status': {
          'href': '/api/v3/statuses/${statusId ?? 1}',
          'title': statusTitle ?? 'New',
        },
        'author': creatorId != null
            ? {
                'href': '/api/v3/users/$creatorId',
                'title': creatorName ?? 'Test User',
              }
            : null,
      },
      'lockVersion': lockVersion ?? 0,
      'createdAt': createdAt ?? '2024-01-01T00:00:00Z',
      'updatedAt': updatedAt ?? '2024-01-01T00:00:00Z',
    };
  }

  /// Create a list of sample OpenProject API response maps
  static List<Map<String, dynamic>> createWorkPackageMapList({
    int count = 3,
  }) {
    final priorityTitles = ['Low', 'Normal', 'High', 'Immediate'];
    final statusTitles = ['New', 'In progress', 'On hold', 'Closed', 'Rejected'];
    return List.generate(
      count,
      (index) => createWorkPackageMap(
        id: index + 1,
        subject: 'Test Issue ${index + 1}',
        description: 'Description for issue ${index + 1}',
        projectId: 100 + index,
        priorityId: 7 + index,
        priorityTitle: priorityTitles[index % priorityTitles.length],
        statusId: 1 + index,
        statusTitle: statusTitles[index % statusTitles.length],
        lockVersion: index,
      ),
    );
  }

  /// Create a sample group map for OpenProject API response
  static Map<String, dynamic> createGroupMap({
    int? id,
    String? name,
  }) {
    return {
      'id': id ?? 10,
      'name': name ?? 'Test Group',
      '_links': {
        'self': {
          'href': '/api/v3/groups/${id ?? 10}',
          'title': name ?? 'Test Group',
        },
      },
    };
  }

  /// Create a list of sample group maps
  static List<Map<String, dynamic>> createGroupMapList({
    int count = 3,
  }) {
    return List.generate(
      count,
      (index) => createGroupMap(
        id: 10 + index,
        name: 'Test Group ${index + 1}',
      ),
    );
  }

  /// Create a sample project (equipment) map for OpenProject API response
  static Map<String, dynamic> createProjectMap({
    int? id,
    String? name,
    String? identifier,
  }) {
    return {
      'id': id ?? 100,
      'name': name ?? 'Test Project',
      'identifier': identifier ?? 'test-project',
      '_links': {
        'self': {
          'href': '/api/v3/projects/${id ?? 100}',
          'title': name ?? 'Test Project',
        },
      },
    };
  }

  /// Create a list of sample project maps
  static List<Map<String, dynamic>> createProjectMapList({
    int count = 3,
  }) {
    return List.generate(
      count,
      (index) => createProjectMap(
        id: 100 + index,
        name: 'Test Project ${index + 1}',
        identifier: 'test-project-${index + 1}',
      ),
    );
  }

  /// Create a sample status map for OpenProject API response
  static Map<String, dynamic> createStatusMap({
    int? id,
    String? name,
    bool? isDefault,
    bool? isClosed,
  }) {
    return {
      'id': id ?? 1,
      'name': name ?? 'New',
      'isDefault': isDefault ?? false,
      'isClosed': isClosed ?? false,
      '_links': {
        'self': {
          'href': '/api/v3/statuses/${id ?? 1}',
          'title': name ?? 'New',
        },
      },
    };
  }

  /// Create a list of sample status maps
  static List<Map<String, dynamic>> createStatusMapList() {
    return [
      createStatusMap(id: 1, name: 'New', isDefault: true, isClosed: false),
      createStatusMap(id: 7, name: 'In progress', isDefault: false, isClosed: false),
      createStatusMap(id: 9, name: 'On hold', isDefault: false, isClosed: false),
      createStatusMap(id: 12, name: 'Closed', isDefault: false, isClosed: true),
      createStatusMap(id: 13, name: 'Rejected', isDefault: false, isClosed: true),
    ];
  }

  /// Create a sample type map for OpenProject API response
  static Map<String, dynamic> createTypeMap({
    int? id,
    String? name,
  }) {
    return {
      'id': id ?? 1,
      'name': name ?? 'Task',
      '_links': {
        'self': {
          'href': '/api/v3/types/${id ?? 1}',
          'title': name ?? 'Task',
        },
      },
    };
  }

  /// Create a list of sample type maps
  static List<Map<String, dynamic>> createTypeMapList({
    int count = 3,
  }) {
    return List.generate(
      count,
      (index) => createTypeMap(
        id: index + 1,
        name: ['Task', 'Bug', 'Feature'][index % 3],
      ),
    );
  }
}

