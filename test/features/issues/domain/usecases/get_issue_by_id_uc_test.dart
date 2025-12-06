import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import 'package:siren_app/features/issues/domain/usecases/get_issue_by_id_uc.dart';

class MockIssueRepository extends Mock implements IssueRepository {}

void main() {
  late GetIssueByIdUseCase useCase;
  late MockIssueRepository mockRepository;

  setUp(() {
    mockRepository = MockIssueRepository();
    useCase = GetIssueByIdUseCase(mockRepository);
  });

  const testIssueId = 1;
  final testIssue = IssueEntity(
    id: testIssueId,
    subject: 'Test Issue',
    description: 'Test description',
    equipment: 10,
    group: 5,
    priorityLevel: PriorityLevel.high,
    status: IssueStatus.inProgress,
    statusName: 'In Progress',
    statusColorHex: '#FF9800',
    lockVersion: 1,
    equipmentName: 'Test Equipment',
    attachmentCount: 2,
  );

  group('GetIssueByIdUseCase', () {
    test(
      'should return IssueEntity when repository call is successful',
      () async {
        // Given
        when(
          () => mockRepository.getIssueById(testIssueId),
        ).thenAnswer((_) async => Right(testIssue));

        // When
        final result = await useCase(testIssueId);

        // Then
        expect(result, equals(Right(testIssue)));
        verify(() => mockRepository.getIssueById(testIssueId)).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test('should return NetworkFailure when network error occurs', () async {
      // Given
      final failure = NetworkFailure('No internet connection');
      when(
        () => mockRepository.getIssueById(testIssueId),
      ).thenAnswer((_) async => Left(failure));

      // When
      final result = await useCase(testIssueId);

      // Then
      expect(result, equals(Left(failure)));
      verify(() => mockRepository.getIssueById(testIssueId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when server error occurs', () async {
      // Given
      final failure = ServerFailure('Server error');
      when(
        () => mockRepository.getIssueById(testIssueId),
      ).thenAnswer((_) async => Left(failure));

      // When
      final result = await useCase(testIssueId);

      // Then
      expect(result, equals(Left(failure)));
      verify(() => mockRepository.getIssueById(testIssueId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NotFoundFailure when issue does not exist', () async {
      // Given
      final failure = NotFoundFailure('Issue not found');
      when(
        () => mockRepository.getIssueById(testIssueId),
      ).thenAnswer((_) async => Left(failure));

      // When
      final result = await useCase(testIssueId);

      // Then
      expect(result, equals(Left(failure)));
      verify(() => mockRepository.getIssueById(testIssueId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should capture lockVersion from repository response', () async {
      // Given
      final issueWithLockVersion = IssueEntity(
        id: testIssueId,
        subject: 'Test Issue',
        equipment: 10,
        group: 5,
        priorityLevel: PriorityLevel.normal,
        status: IssueStatus.newStatus,
        lockVersion: 5,
      );
      when(
        () => mockRepository.getIssueById(testIssueId),
      ).thenAnswer((_) async => Right(issueWithLockVersion));

      // When
      final result = await useCase(testIssueId);

      // Then
      result.fold((failure) => fail('Expected success but got failure'), (
        issue,
      ) {
        expect(issue.lockVersion, equals(5));
      });
    });
  });
}
