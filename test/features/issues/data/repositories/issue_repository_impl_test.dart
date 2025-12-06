import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/data/datasources/issue_remote_datasource.dart';
import 'package:siren_app/features/issues/data/repositories/issue_repository_impl.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

import '../../../../core/fixtures/issue_fixtures.dart';

class MockIssueRemoteDataSource extends Mock implements IssueRemoteDataSource {}

void main() {
  late IssueRepositoryImpl repository;
  late MockIssueRemoteDataSource mockDataSource;

  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(PriorityLevel.normal);
    registerFallbackValue(IssueStatus.newStatus);
  });

  setUp(() {
    mockDataSource = MockIssueRemoteDataSource();
    repository = IssueRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('IssueRepositoryImpl', () {
    group('createIssue', () {
      test(
        'should return IssueEntity when data source returns success',
        () async {
          // Given
          const subject = 'Test Issue';
          const description = 'Test Description';
          const equipment = 100;
          const group = 10;
          const priorityLevel = PriorityLevel.high;

          final responseMap = IssueFixtures.createWorkPackageMap(
            id: 123,
            subject: subject,
            description: description,
            projectId: equipment,
            priorityId: 9,
            priorityTitle: 'High',
            statusId: 1,
            statusTitle: 'New',
            lockVersion: 0,
          );

          when(
            () => mockDataSource.createIssue(
              subject: any(named: 'subject'),
              description: any(named: 'description'),
              equipment: any(named: 'equipment'),
              group: any(named: 'group'),
              priorityLevel: any(named: 'priorityLevel'),
            ),
          ).thenAnswer((_) async => responseMap);

          // When
          final result = await repository.createIssue(
            subject: subject,
            description: description,
            equipment: equipment,
            group: group,
            priorityLevel: priorityLevel,
          );

          // Then
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Expected success but got failure: $failure'),
            (entity) {
              expect(entity, isA<IssueEntity>());
              expect(entity.id, 123);
              expect(entity.subject, subject);
              expect(entity.equipment, equipment);
              expect(entity.priorityLevel, PriorityLevel.high);
            },
          );

          verify(
            () => mockDataSource.createIssue(
              subject: subject,
              description: description,
              equipment: equipment,
              group: group,
              priorityLevel: priorityLevel,
            ),
          ).called(1);
        },
      );

      test('should return IssueEntity with group set from parameter', () async {
        // Given
        const group = 42;
        final responseMap = IssueFixtures.createWorkPackageMap();

        when(
          () => mockDataSource.createIssue(
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            equipment: any(named: 'equipment'),
            group: any(named: 'group'),
            priorityLevel: any(named: 'priorityLevel'),
          ),
        ).thenAnswer((_) async => responseMap);

        // When
        final result = await repository.createIssue(
          subject: 'Test',
          equipment: 100,
          group: group,
          priorityLevel: PriorityLevel.normal,
        );

        // Then
        expect(result.isRight(), true);
        result.fold((failure) => fail('Expected success'), (entity) {
          // Group should be set from parameter since API doesn't return it
          expect(entity.group, group);
        });
      });

      test(
        'should return ServerFailure when data source throws ServerFailure',
        () async {
          // Given
          when(
            () => mockDataSource.createIssue(
              subject: any(named: 'subject'),
              description: any(named: 'description'),
              equipment: any(named: 'equipment'),
              group: any(named: 'group'),
              priorityLevel: any(named: 'priorityLevel'),
            ),
          ).thenThrow(const ServerFailure('Server error'));

          // When
          final result = await repository.createIssue(
            subject: 'Test',
            equipment: 100,
            group: 10,
            priorityLevel: PriorityLevel.normal,
          );

          // Then
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('Server error'));
          }, (_) => fail('Expected failure but got success'));
        },
      );

      test('should return UnexpectedFailure when data source throws generic'
          ' exception', () async {
        // Given
        when(
          () => mockDataSource.createIssue(
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            equipment: any(named: 'equipment'),
            group: any(named: 'group'),
            priorityLevel: any(named: 'priorityLevel'),
          ),
        ).thenThrow(Exception('Unexpected error'));

        // When
        final result = await repository.createIssue(
          subject: 'Test',
          equipment: 100,
          group: 10,
          priorityLevel: PriorityLevel.normal,
        );

        // Then
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<UnexpectedFailure>());
        }, (_) => fail('Expected failure but got success'));
      });

      test(
        'should pass null description to data source when not provided',
        () async {
          // Given
          final responseMap = IssueFixtures.createWorkPackageMap();

          when(
            () => mockDataSource.createIssue(
              subject: any(named: 'subject'),
              description: any(named: 'description'),
              equipment: any(named: 'equipment'),
              group: any(named: 'group'),
              priorityLevel: any(named: 'priorityLevel'),
            ),
          ).thenAnswer((_) async => responseMap);

          // When
          await repository.createIssue(
            subject: 'Test',
            equipment: 100,
            group: 10,
            priorityLevel: PriorityLevel.normal,
          );

          // Then
          verify(
            () => mockDataSource.createIssue(
              subject: 'Test',
              description: null,
              equipment: 100,
              group: 10,
              priorityLevel: PriorityLevel.normal,
            ),
          ).called(1);
        },
      );
    });

    group('getIssueById', () {
      test(
        'should return IssueEntity when data source returns success',
        () async {
          // Given
          const issueId = 123;
          final responseMap = IssueFixtures.createWorkPackageMap(
            id: issueId,
            subject: 'Fetched Issue',
            lockVersion: 5,
          );

          when(
            () => mockDataSource.getIssueById(any()),
          ).thenAnswer((_) async => responseMap);

          // When
          final result = await repository.getIssueById(issueId);

          // Then
          expect(result.isRight(), true);
          result.fold((failure) => fail('Expected success'), (entity) {
            expect(entity.id, issueId);
            expect(entity.subject, 'Fetched Issue');
            expect(entity.lockVersion, 5);
          });

          verify(() => mockDataSource.getIssueById(issueId)).called(1);
        },
      );

      test('should return ServerFailure when data source throws', () async {
        // Given
        when(
          () => mockDataSource.getIssueById(any()),
        ).thenThrow(const ServerFailure('Not found'));

        // When
        final result = await repository.getIssueById(999);

        // Then
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected failure'),
        );
      });
    });

    group('getIssues', () {
      test(
        'should return list of IssueEntities when data source succeeds',
        () async {
          // Given
          final responseList = IssueFixtures.createWorkPackageMapList(count: 3);

          when(
            () => mockDataSource.getIssues(
              status: any(named: 'status'),
              equipmentId: any(named: 'equipmentId'),
              priorityLevel: any(named: 'priorityLevel'),
              groupId: any(named: 'groupId'),
              offset: any(named: 'offset'),
              pageSize: any(named: 'pageSize'),
            ),
          ).thenAnswer((_) async => responseList);

          // When
          final result = await repository.getIssues();

          // Then
          expect(result.isRight(), true);
          result.fold((failure) => fail('Expected success'), (entities) {
            expect(entities.length, 3);
            expect(entities, isA<List<IssueEntity>>());
            expect(entities.first.equipmentName, isNotEmpty);
          });
        },
      );

      test('should return empty list when data source returns empty', () async {
        // Given
        when(
          () => mockDataSource.getIssues(
            status: any(named: 'status'),
            equipmentId: any(named: 'equipmentId'),
            priorityLevel: any(named: 'priorityLevel'),
            groupId: any(named: 'groupId'),
            offset: any(named: 'offset'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((_) async => []);

        // When
        final result = await repository.getIssues();

        // Then
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected success'),
          (entities) => expect(entities, isEmpty),
        );
      });

      test('should return ServerFailure when data source throws', () async {
        // Given
        when(
          () => mockDataSource.getIssues(
            status: any(named: 'status'),
            equipmentId: any(named: 'equipmentId'),
            priorityLevel: any(named: 'priorityLevel'),
            groupId: any(named: 'groupId'),
            offset: any(named: 'offset'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenThrow(const ServerFailure('Failed to fetch'));

        // When
        final result = await repository.getIssues();

        // Then
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected failure'),
        );
      });
    });
  });
}
