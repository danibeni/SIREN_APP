import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import 'package:siren_app/features/issues/domain/usecases/sync_issue_uc.dart';

class MockIssueRepository extends Mock implements IssueRepository {}

void main() {
  late SyncIssueUseCase useCase;
  late MockIssueRepository mockRepository;

  setUp(() {
    mockRepository = MockIssueRepository();
    useCase = SyncIssueUseCase(mockRepository);
  });

  group('SyncIssueUseCase', () {
    const tIssueId = 1;

    final tSyncedIssue = IssueEntity(
      id: tIssueId,
      subject: 'Synced Issue',
      description: 'Description',
      equipment: 1,
      group: 1,
      priorityLevel: PriorityLevel.normal,
      status: IssueStatus.inProgress,
      lockVersion: 6,
      hasPendingSync: false, // After sync, no pending changes
    );

    test('should return updated IssueEntity when sync succeeds', () async {
      // Given
      when(
        () => mockRepository.syncIssue(any()),
      ).thenAnswer((_) async => Right(tSyncedIssue));

      // When
      final result = await useCase(tIssueId);

      // Then
      expect(result, Right(tSyncedIssue));
      verify(() => mockRepository.syncIssue(tIssueId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test(
      'should return NetworkFailure when network error occurs during sync',
      () async {
        // Given
        when(() => mockRepository.syncIssue(any())).thenAnswer(
          (_) async => const Left(NetworkFailure('No internet connection')),
        );

        // When
        final result = await useCase(tIssueId);

        // Then
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Should return failure'),
        );
        verify(() => mockRepository.syncIssue(tIssueId)).called(1);
      },
    );

    test(
      'should return ServerFailure when server error occurs during sync',
      () async {
        // Given
        when(
          () => mockRepository.syncIssue(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Server error')));

        // When
        final result = await useCase(tIssueId);

        // Then
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
        verify(() => mockRepository.syncIssue(tIssueId)).called(1);
      },
    );

    test(
      'should return ConflictFailure when lockVersion mismatch during sync',
      () async {
        // Given
        when(() => mockRepository.syncIssue(any())).thenAnswer(
          (_) async => const Left(
            ConflictFailure('Issue has been modified by another user'),
          ),
        );

        // When
        final result = await useCase(tIssueId);

        // Then
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConflictFailure>()),
          (_) => fail('Should return failure'),
        );
        verify(() => mockRepository.syncIssue(tIssueId)).called(1);
      },
    );

    test('should call repository sync method with correct issue ID', () async {
      // Given
      when(
        () => mockRepository.syncIssue(any()),
      ).thenAnswer((_) async => Right(tSyncedIssue));

      // When
      await useCase(tIssueId);

      // Then
      verify(() => mockRepository.syncIssue(tIssueId)).called(1);
    });
  });
}
