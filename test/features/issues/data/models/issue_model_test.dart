import 'package:flutter_test/flutter_test.dart';
import 'package:siren_app/features/issues/data/models/issue_model.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

import '../../../../core/fixtures/issue_fixtures.dart';

void main() {
  group('IssueModel', () {
    group('fromJson', () {
      test(
        'should correctly parse a complete OpenProject work package response',
        () {
          // Given
          final json = IssueFixtures.createWorkPackageMap(
            id: 123,
            subject: 'Test Issue',
            description: 'Test Description',
            projectId: 100,
            priorityId: 3,
            statusId: 1,
            creatorId: 5,
            creatorName: 'John Doe',
            lockVersion: 2,
            createdAt: '2024-01-15T10:30:00Z',
            updatedAt: '2024-01-16T14:45:00Z',
          );

          // When
          final model = IssueModel.fromJson(json);

          // Then
          expect(model.id, 123);
          expect(model.subject, 'Test Issue');
          expect(model.description, 'Test Description');
          expect(model.equipment, 100);
          expect(model.lockVersion, 2);
          expect(model.creatorId, 5);
          expect(model.creatorName, 'John Doe');
          expect(model.createdAt, DateTime.utc(2024, 1, 15, 10, 30, 0));
          expect(model.updatedAt, DateTime.utc(2024, 1, 16, 14, 45, 0));
        },
      );

      test('should handle work package response with null description', () {
        // Given
        final json = IssueFixtures.createWorkPackageMap(
          id: 1,
          subject: 'Issue without description',
        );
        json['description'] = null;

        // When
        final model = IssueModel.fromJson(json);

        // Then
        expect(model.description, isNull);
      });

      test('should extract project ID from _links.project.href', () {
        // Given
        final json = {
          'id': 1,
          'subject': 'Test',
          'lockVersion': 0,
          '_links': {
            'project': {'href': '/api/v3/projects/42', 'title': 'Project'},
            'type': {'href': '/api/v3/types/1', 'title': 'Task'},
            'priority': {'href': '/api/v3/priorities/5', 'title': 'Normal'},
            'status': {'href': '/api/v3/statuses/1', 'title': 'New'},
          },
        };

        // When
        final model = IssueModel.fromJson(json);

        // Then
        expect(model.equipment, 42);
      });

      test('should extract creator info from _links.author', () {
        // Given
        final json = {
          'id': 1,
          'subject': 'Test',
          'lockVersion': 0,
          '_links': {
            'project': {'href': '/api/v3/projects/1', 'title': 'Project'},
            'type': {'href': '/api/v3/types/1', 'title': 'Task'},
            'priority': {'href': '/api/v3/priorities/5', 'title': 'Normal'},
            'status': {'href': '/api/v3/statuses/1', 'title': 'New'},
            'author': {'href': '/api/v3/users/99', 'title': 'Jane Smith'},
          },
        };

        // When
        final model = IssueModel.fromJson(json);

        // Then
        expect(model.creatorId, 99);
        expect(model.creatorName, 'Jane Smith');
      });

      test('should map priority name (title) to PriorityLevel enum', () {
        // Given - Testing priority by name
        final jsonLow = _createJsonWithPriority(7, 'Low');
        final jsonNormal = _createJsonWithPriority(8, 'Normal');
        final jsonHigh = _createJsonWithPriority(9, 'High');
        final jsonImmediate = _createJsonWithPriority(10, 'Immediate');

        // When & Then
        expect(IssueModel.fromJson(jsonLow).priorityLevel, PriorityLevel.low);
        expect(
          IssueModel.fromJson(jsonNormal).priorityLevel,
          PriorityLevel.normal,
        );
        expect(IssueModel.fromJson(jsonHigh).priorityLevel, PriorityLevel.high);
        expect(
          IssueModel.fromJson(jsonImmediate).priorityLevel,
          PriorityLevel.immediate,
        );
      });

      test('should map status name (title) to IssueStatus enum', () {
        // Given - Testing all 5 status values by name
        final jsonNew = _createJsonWithStatus(1, 'New');
        final jsonInProgress = _createJsonWithStatus(7, 'In progress');
        final jsonOnHold = _createJsonWithStatus(9, 'On hold');
        final jsonClosed = _createJsonWithStatus(12, 'Closed');
        final jsonRejected = _createJsonWithStatus(13, 'Rejected');

        // When & Then
        expect(IssueModel.fromJson(jsonNew).status, IssueStatus.newStatus);
        expect(
          IssueModel.fromJson(jsonInProgress).status,
          IssueStatus.inProgress,
        );
        expect(IssueModel.fromJson(jsonOnHold).status, IssueStatus.onHold);
        expect(IssueModel.fromJson(jsonClosed).status, IssueStatus.closed);
        expect(IssueModel.fromJson(jsonRejected).status, IssueStatus.rejected);
      });

      test('should default to normal priority for unknown priority name', () {
        // Given - Priority with unknown name
        final json = _createJsonWithPriority(999, 'Unknown Priority');

        // When
        final model = IssueModel.fromJson(json);

        // Then
        expect(model.priorityLevel, PriorityLevel.normal);
      });

      test('should default to newStatus for unknown status name', () {
        // Given - Status with unknown name
        final json = _createJsonWithStatus(999, 'Unknown Status');

        // When
        final model = IssueModel.fromJson(json);

        // Then
        expect(model.status, IssueStatus.newStatus);
      });

      test('should handle priority name case-insensitively', () {
        // Given - Various case formats
        final jsonLower = _createJsonWithPriority(1, 'low');
        final jsonUpper = _createJsonWithPriority(2, 'HIGH');
        final jsonMixed = _createJsonWithPriority(3, 'Immediate');

        // When & Then
        expect(IssueModel.fromJson(jsonLower).priorityLevel, PriorityLevel.low);
        expect(IssueModel.fromJson(jsonUpper).priorityLevel, PriorityLevel.high);
        expect(
          IssueModel.fromJson(jsonMixed).priorityLevel,
          PriorityLevel.immediate,
        );
      });

      test('should handle status name case-insensitively', () {
        // Given - Various case formats for all 5 statuses
        final jsonLower = _createJsonWithStatus(1, 'new');
        final jsonUpper = _createJsonWithStatus(2, 'IN PROGRESS');
        final jsonOnHold = _createJsonWithStatus(3, 'ON HOLD');
        final jsonClosed = _createJsonWithStatus(4, 'Closed');
        final jsonRejected = _createJsonWithStatus(5, 'REJECTED');

        // When & Then
        expect(IssueModel.fromJson(jsonLower).status, IssueStatus.newStatus);
        expect(
          IssueModel.fromJson(jsonUpper).status,
          IssueStatus.inProgress,
        );
        expect(IssueModel.fromJson(jsonOnHold).status, IssueStatus.onHold);
        expect(IssueModel.fromJson(jsonClosed).status, IssueStatus.closed);
        expect(IssueModel.fromJson(jsonRejected).status, IssueStatus.rejected);
      });

      test('should handle missing optional fields gracefully', () {
        // Given - minimal JSON with required title fields for mapping
        final json = {
          'id': 1,
          'subject': 'Minimal Issue',
          'lockVersion': 0,
          '_links': {
            'project': {'href': '/api/v3/projects/1'},
            'type': {'href': '/api/v3/types/1'},
            'priority': {'href': '/api/v3/priorities/8', 'title': 'Normal'},
            'status': {'href': '/api/v3/statuses/1', 'title': 'New'},
          },
        };

        // When
        final model = IssueModel.fromJson(json);

        // Then
        expect(model.id, 1);
        expect(model.subject, 'Minimal Issue');
        expect(model.description, isNull);
        expect(model.creatorId, isNull);
        expect(model.creatorName, isNull);
        expect(model.createdAt, isNull);
        expect(model.updatedAt, isNull);
        expect(model.priorityLevel, PriorityLevel.normal);
        expect(model.status, IssueStatus.newStatus);
      });

      test('should default to normal/new when title is missing', () {
        // Given - JSON without title fields (edge case)
        final json = {
          'id': 1,
          'subject': 'Issue without titles',
          'lockVersion': 0,
          '_links': {
            'project': {'href': '/api/v3/projects/1'},
            'type': {'href': '/api/v3/types/1'},
            'priority': {'href': '/api/v3/priorities/8'},
            'status': {'href': '/api/v3/statuses/1'},
          },
        };

        // When
        final model = IssueModel.fromJson(json);

        // Then - should use default values when title is missing
        expect(model.priorityLevel, PriorityLevel.normal);
        expect(model.status, IssueStatus.newStatus);
      });
    });

    group('toEntity', () {
      test('should convert IssueModel to IssueEntity correctly', () {
        // Given
        final model = IssueModel(
          id: 123,
          subject: 'Test Issue',
          description: 'Test Description',
          equipment: 100,
          group: 10,
          priorityLevel: PriorityLevel.high,
          status: IssueStatus.inProgress,
          creatorId: 5,
          creatorName: 'John Doe',
          lockVersion: 2,
          createdAt: DateTime.utc(2024, 1, 15),
          updatedAt: DateTime.utc(2024, 1, 16),
        );

        // When
        final entity = model.toEntity();

        // Then
        expect(entity, isA<IssueEntity>());
        expect(entity.id, 123);
        expect(entity.subject, 'Test Issue');
        expect(entity.description, 'Test Description');
        expect(entity.equipment, 100);
        expect(entity.group, 10);
        expect(entity.priorityLevel, PriorityLevel.high);
        expect(entity.status, IssueStatus.inProgress);
        expect(entity.creatorId, 5);
        expect(entity.creatorName, 'John Doe');
        expect(entity.lockVersion, 2);
        expect(entity.createdAt, DateTime.utc(2024, 1, 15));
        expect(entity.updatedAt, DateTime.utc(2024, 1, 16));
      });

      test('should preserve null values when converting to entity', () {
        // Given
        final model = IssueModel(
          id: 1,
          subject: 'Test',
          equipment: 100,
          group: 10,
          priorityLevel: PriorityLevel.normal,
          status: IssueStatus.newStatus,
          lockVersion: 0,
        );

        // When
        final entity = model.toEntity();

        // Then
        expect(entity.description, isNull);
        expect(entity.creatorId, isNull);
        expect(entity.creatorName, isNull);
        expect(entity.createdAt, isNull);
        expect(entity.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('should create correct JSON payload for issue creation', () {
        // Given
        final model = IssueModel(
          subject: 'New Issue',
          description: 'Issue description',
          equipment: 100,
          group: 10,
          priorityLevel: PriorityLevel.high,
          status: IssueStatus.newStatus,
          lockVersion: 0,
        );

        // When
        final json = model.toJson();

        // Then
        expect(json['subject'], 'New Issue');
        expect(json['description']['format'], 'markdown');
        expect(json['description']['raw'], 'Issue description');
        expect(json['_links']['project']['href'], '/api/v3/projects/100');
        expect(json['_links']['priority']['href'], '/api/v3/priorities/3');
      });

      test('should not include description in JSON when null', () {
        // Given
        final model = IssueModel(
          subject: 'Issue without description',
          equipment: 100,
          group: 10,
          priorityLevel: PriorityLevel.normal,
          status: IssueStatus.newStatus,
          lockVersion: 0,
        );

        // When
        final json = model.toJson();

        // Then
        expect(json.containsKey('description'), isFalse);
      });

      test('should map PriorityLevel to correct priority ID', () {
        // Given & When & Then
        expect(
          _createModelWithPriority(
            PriorityLevel.low,
          ).toJson()['_links']['priority']['href'],
          '/api/v3/priorities/1',
        );
        expect(
          _createModelWithPriority(
            PriorityLevel.normal,
          ).toJson()['_links']['priority']['href'],
          '/api/v3/priorities/2',
        );
        expect(
          _createModelWithPriority(
            PriorityLevel.high,
          ).toJson()['_links']['priority']['href'],
          '/api/v3/priorities/3',
        );
        expect(
          _createModelWithPriority(
            PriorityLevel.immediate,
          ).toJson()['_links']['priority']['href'],
          '/api/v3/priorities/4',
        );
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Given
        final original = IssueModel(
          id: 1,
          subject: 'Original',
          equipment: 100,
          group: 10,
          priorityLevel: PriorityLevel.normal,
          status: IssueStatus.newStatus,
          lockVersion: 0,
        );

        // When
        final copy = original.copyWith(
          subject: 'Updated',
          priorityLevel: PriorityLevel.high,
        );

        // Then
        expect(copy.id, 1);
        expect(copy.subject, 'Updated');
        expect(copy.equipment, 100);
        expect(copy.priorityLevel, PriorityLevel.high);
        expect(copy.status, IssueStatus.newStatus);
      });
    });
  });
}

// Helper functions for test data creation
Map<String, dynamic> _createJsonWithPriority(int priorityId, String title) {
  return {
    'id': 1,
    'subject': 'Test',
    'lockVersion': 0,
    '_links': {
      'project': {'href': '/api/v3/projects/1', 'title': 'Project'},
      'type': {'href': '/api/v3/types/1', 'title': 'Task'},
      'priority': {'href': '/api/v3/priorities/$priorityId', 'title': title},
      'status': {'href': '/api/v3/statuses/1', 'title': 'New'},
    },
  };
}

Map<String, dynamic> _createJsonWithStatus(int statusId, String title) {
  return {
    'id': 1,
    'subject': 'Test',
    'lockVersion': 0,
    '_links': {
      'project': {'href': '/api/v3/projects/1', 'title': 'Project'},
      'type': {'href': '/api/v3/types/1', 'title': 'Task'},
      'priority': {'href': '/api/v3/priorities/8', 'title': 'Normal'},
      'status': {'href': '/api/v3/statuses/$statusId', 'title': title},
    },
  };
}

IssueModel _createModelWithPriority(PriorityLevel priority) {
  return IssueModel(
    subject: 'Test',
    equipment: 100,
    group: 10,
    priorityLevel: priority,
    status: IssueStatus.newStatus,
    lockVersion: 0,
  );
}
