import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import 'package:siren_app/features/issues/domain/usecases/create_issue_uc.dart';

import '../../../../core/fixtures/issue_fixtures.dart';

class MockIssueRepository extends Mock implements IssueRepository {}

void main() {
  late CreateIssueUseCase useCase;
  late MockIssueRepository mockRepository;

  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(PriorityLevel.normal);
  });

  setUp(() {
    mockRepository = MockIssueRepository();
    useCase = CreateIssueUseCase(mockRepository);
  });

  group('CreateIssueUseCase', () {
    group('Successful creation', () {
      test(
        'should return IssueEntity when repository call is successful',
        () async {
          // Given
          final params = CreateIssueParams(
            subject: 'Test Issue',
            priorityLevel: PriorityLevel.normal,
            group: 10,
            equipment: 100,
          );
          final expectedEntity = IssueFixtures.createIssueEntity(
            subject: 'Test Issue',
            priorityLevel: PriorityLevel.normal,
            group: 10,
            equipment: 100,
          );

          when(
            () => mockRepository.createIssue(
              subject: any(named: 'subject'),
              description: any(named: 'description'),
              equipment: any(named: 'equipment'),
              group: any(named: 'group'),
              priorityLevel: any(named: 'priorityLevel'),
            ),
          ).thenAnswer((_) async => Right(expectedEntity));

          // When
          final result = await useCase(params);

          // Then
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Expected success but got failure: $failure'),
            (entity) {
              expect(entity.subject, 'Test Issue');
              expect(entity.priorityLevel, PriorityLevel.normal);
              expect(entity.group, 10);
              expect(entity.equipment, 100);
            },
          );

          verify(
            () => mockRepository.createIssue(
              subject: 'Test Issue',
              description: null,
              equipment: 100,
              group: 10,
              priorityLevel: PriorityLevel.normal,
            ),
          ).called(1);
        },
      );

      test('should preserve description when provided', () async {
        // Given
        final params = CreateIssueParams(
          subject: 'Issue with Description',
          description: 'This is a detailed description',
          priorityLevel: PriorityLevel.high,
          group: 10,
          equipment: 100,
        );
        final expectedEntity = IssueFixtures.createIssueEntity(
          subject: 'Issue with Description',
          description: 'This is a detailed description',
          priorityLevel: PriorityLevel.high,
          group: 10,
          equipment: 100,
        );

        when(
          () => mockRepository.createIssue(
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            equipment: any(named: 'equipment'),
            group: any(named: 'group'),
            priorityLevel: any(named: 'priorityLevel'),
          ),
        ).thenAnswer((_) async => Right(expectedEntity));

        // When
        final result = await useCase(params);

        // Then
        expect(result.isRight(), true);
        result.fold((failure) => fail('Expected success but got failure'), (
          entity,
        ) {
          expect(entity.description, 'This is a detailed description');
        });

        verify(
          () => mockRepository.createIssue(
            subject: 'Issue with Description',
            description: 'This is a detailed description',
            equipment: 100,
            group: 10,
            priorityLevel: PriorityLevel.high,
          ),
        ).called(1);
      });

      test('should trim subject and description whitespace', () async {
        // Given
        final params = CreateIssueParams(
          subject: '  Test Issue  ',
          description: '  Description with spaces  ',
          priorityLevel: PriorityLevel.normal,
          group: 10,
          equipment: 100,
        );
        final expectedEntity = IssueFixtures.createIssueEntity(
          subject: 'Test Issue',
          description: 'Description with spaces',
        );

        when(
          () => mockRepository.createIssue(
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            equipment: any(named: 'equipment'),
            group: any(named: 'group'),
            priorityLevel: any(named: 'priorityLevel'),
          ),
        ).thenAnswer((_) async => Right(expectedEntity));

        // When
        final result = await useCase(params);

        // Then
        expect(result.isRight(), true);

        verify(
          () => mockRepository.createIssue(
            subject: 'Test Issue',
            description: 'Description with spaces',
            equipment: 100,
            group: 10,
            priorityLevel: PriorityLevel.normal,
          ),
        ).called(1);
      });
    });

    group('Subject validation', () {
      test('should return ValidationFailure when subject is empty', () async {
        // Given
        final params = CreateIssueParams(
          subject: '',
          priorityLevel: PriorityLevel.normal,
          group: 10,
          equipment: 100,
        );

        // When
        final result = await useCase(params);

        // Then
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message.toLowerCase(), contains('subject'));
        }, (_) => fail('Expected failure but got success'));

        verifyNever(
          () => mockRepository.createIssue(
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            equipment: any(named: 'equipment'),
            group: any(named: 'group'),
            priorityLevel: any(named: 'priorityLevel'),
          ),
        );
      });

      test(
        'should return ValidationFailure when subject is whitespace only',
        () async {
          // Given
          final params = CreateIssueParams(
            subject: '   ',
            priorityLevel: PriorityLevel.normal,
            group: 10,
            equipment: 100,
          );

          // When
          final result = await useCase(params);

          // Then
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message.toLowerCase(), contains('subject'));
          }, (_) => fail('Expected failure but got success'));

          verifyNever(
            () => mockRepository.createIssue(
              subject: any(named: 'subject'),
              description: any(named: 'description'),
              equipment: any(named: 'equipment'),
              group: any(named: 'group'),
              priorityLevel: any(named: 'priorityLevel'),
            ),
          );
        },
      );
    });

    group('Priority Level validation', () {
      test(
        'should return ValidationFailure when priorityLevel is null',
        () async {
          // Given
          final params = CreateIssueParams(
            subject: 'Test Issue',
            priorityLevel: null,
            group: 10,
            equipment: 100,
          );

          // When
          final result = await useCase(params);

          // Then
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message.toLowerCase(), contains('priority'));
          }, (_) => fail('Expected failure but got success'));

          verifyNever(
            () => mockRepository.createIssue(
              subject: any(named: 'subject'),
              description: any(named: 'description'),
              equipment: any(named: 'equipment'),
              group: any(named: 'group'),
              priorityLevel: any(named: 'priorityLevel'),
            ),
          );
        },
      );
    });

    group('Group validation', () {
      test('should return ValidationFailure when group is null', () async {
        // Given
        final params = CreateIssueParams(
          subject: 'Test Issue',
          priorityLevel: PriorityLevel.normal,
          group: null,
          equipment: 100,
        );

        // When
        final result = await useCase(params);

        // Then
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message.toLowerCase(), contains('group'));
        }, (_) => fail('Expected failure but got success'));

        verifyNever(
          () => mockRepository.createIssue(
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            equipment: any(named: 'equipment'),
            group: any(named: 'group'),
            priorityLevel: any(named: 'priorityLevel'),
          ),
        );
      });

      test('should return ValidationFailure when group is zero', () async {
        // Given
        final params = CreateIssueParams(
          subject: 'Test Issue',
          priorityLevel: PriorityLevel.normal,
          group: 0,
          equipment: 100,
        );

        // When
        final result = await useCase(params);

        // Then
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message.toLowerCase(), contains('group'));
        }, (_) => fail('Expected failure but got success'));

        verifyNever(
          () => mockRepository.createIssue(
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            equipment: any(named: 'equipment'),
            group: any(named: 'group'),
            priorityLevel: any(named: 'priorityLevel'),
          ),
        );
      });
    });

    group('Equipment validation', () {
      test('should return ValidationFailure when equipment is null', () async {
        // Given
        final params = CreateIssueParams(
          subject: 'Test Issue',
          priorityLevel: PriorityLevel.normal,
          group: 10,
          equipment: null,
        );

        // When
        final result = await useCase(params);

        // Then
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message.toLowerCase(), contains('equipment'));
        }, (_) => fail('Expected failure but got success'));

        verifyNever(
          () => mockRepository.createIssue(
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            equipment: any(named: 'equipment'),
            group: any(named: 'group'),
            priorityLevel: any(named: 'priorityLevel'),
          ),
        );
      });

      test('should return ValidationFailure when equipment is zero', () async {
        // Given
        final params = CreateIssueParams(
          subject: 'Test Issue',
          priorityLevel: PriorityLevel.normal,
          group: 10,
          equipment: 0,
        );

        // When
        final result = await useCase(params);

        // Then
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message.toLowerCase(), contains('equipment'));
        }, (_) => fail('Expected failure but got success'));

        verifyNever(
          () => mockRepository.createIssue(
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            equipment: any(named: 'equipment'),
            group: any(named: 'group'),
            priorityLevel: any(named: 'priorityLevel'),
          ),
        );
      });
    });

    group('Multiple validation failures', () {
      test('should return ValidationFailure when multiple mandatory fields are'
          ' missing (reports first failure)', () async {
        // Given
        final params = CreateIssueParams(
          subject: '',
          priorityLevel: null,
          group: null,
          equipment: null,
        );

        // When
        final result = await useCase(params);

        // Then
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          // Should report the first validation error (subject)
          expect(failure.message.toLowerCase(), contains('subject'));
        }, (_) => fail('Expected failure but got success'));

        verifyNever(
          () => mockRepository.createIssue(
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            equipment: any(named: 'equipment'),
            group: any(named: 'group'),
            priorityLevel: any(named: 'priorityLevel'),
          ),
        );
      });
    });

    group('Repository errors', () {
      test(
        'should return ServerFailure when repository returns failure',
        () async {
          // Given
          final params = CreateIssueParams(
            subject: 'Test Issue',
            priorityLevel: PriorityLevel.normal,
            group: 10,
            equipment: 100,
          );

          when(
            () => mockRepository.createIssue(
              subject: any(named: 'subject'),
              description: any(named: 'description'),
              equipment: any(named: 'equipment'),
              group: any(named: 'group'),
              priorityLevel: any(named: 'priorityLevel'),
            ),
          ).thenAnswer((_) async => const Left(ServerFailure('Server error')));

          // When
          final result = await useCase(params);

          // Then
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, 'Server error');
          }, (_) => fail('Expected failure but got success'));
        },
      );

      test(
        'should return NetworkFailure when repository returns network error',
        () async {
          // Given
          final params = CreateIssueParams(
            subject: 'Test Issue',
            priorityLevel: PriorityLevel.normal,
            group: 10,
            equipment: 100,
          );

          when(
            () => mockRepository.createIssue(
              subject: any(named: 'subject'),
              description: any(named: 'description'),
              equipment: any(named: 'equipment'),
              group: any(named: 'group'),
              priorityLevel: any(named: 'priorityLevel'),
            ),
          ).thenAnswer(
            (_) async => const Left(NetworkFailure('No internet connection')),
          );

          // When
          final result = await useCase(params);

          // Then
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, 'No internet connection');
          }, (_) => fail('Expected failure but got success'));
        },
      );
    });
  });
}
