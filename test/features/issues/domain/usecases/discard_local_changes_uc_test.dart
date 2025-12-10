import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import 'package:siren_app/features/issues/domain/usecases/discard_local_changes_uc.dart';

class MockIssueRepository extends Mock implements IssueRepository {}

void main() {
  late DiscardLocalChangesUseCase useCase;
  late MockIssueRepository mockRepository;

  setUp(() {
    mockRepository = MockIssueRepository();
    useCase = DiscardLocalChangesUseCase(mockRepository);
  });

  group('DiscardLocalChangesUseCase', () {
    const tIssueId = 1;

    final tRestoredIssue = IssueEntity(
      id: tIssueId,
      subject: 'Original Subject',
      description: 'Original Description',
      equipment: 1,
      group: 1,
      priorityLevel: PriorityLevel.normal,
      status: IssueStatus.newStatus,
      lockVersion: 5,
      hasPendingSync: false, // After discard, no pending changes
    );

    test(
      'should return IssueEntity from server cache when discard succeeds',
      () async {
        // Given
        when(
          () => mockRepository.discardLocalChanges(any()),
        ).thenAnswer((_) async => Right(tRestoredIssue));

        // When
        final result = await useCase(tIssueId);

        // Then
        expect(result, Right(tRestoredIssue));
        expect(result.getOrElse(() => tRestoredIssue).hasPendingSync, false);
        verify(() => mockRepository.discardLocalChanges(tIssueId)).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test('should clear pending sync status', () async {
      // Given
      when(
        () => mockRepository.discardLocalChanges(any()),
      ).thenAnswer((_) async => Right(tRestoredIssue));

      // When
      final result = await useCase(tIssueId);

      // Then
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return issue'),
        (issue) => expect(issue.hasPendingSync, false),
      );
    });

    test('should remove local modifications', () async {
      // Given
      when(
        () => mockRepository.discardLocalChanges(any()),
      ).thenAnswer((_) async => Right(tRestoredIssue));

      // When
      final result = await useCase(tIssueId);

      // Then
      expect(result, Right(tRestoredIssue));
      verify(() => mockRepository.discardLocalChanges(tIssueId)).called(1);
    });

    test(
      'should call repository discard method with correct issue ID',
      () async {
        // Given
        when(
          () => mockRepository.discardLocalChanges(any()),
        ).thenAnswer((_) async => Right(tRestoredIssue));

        // When
        await useCase(tIssueId);

        // Then
        verify(() => mockRepository.discardLocalChanges(tIssueId)).called(1);
      },
    );

    test(
      'should return NotFoundFailure when issue not found in cache',
      () async {
        // Given
        when(() => mockRepository.discardLocalChanges(any())).thenAnswer(
          (_) async => const Left(NotFoundFailure('Issue not found in cache')),
        );

        // When
        final result = await useCase(tIssueId);

        // Then
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Should return failure'),
        );
      },
    );

    test('should return CacheFailure when cache error occurs', () async {
      // Given
      when(
        () => mockRepository.discardLocalChanges(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('Cache error')));

      // When
      final result = await useCase(tIssueId);

      // Then
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });
}
