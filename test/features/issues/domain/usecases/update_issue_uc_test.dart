import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import 'package:siren_app/features/issues/domain/usecases/update_issue_params.dart';
import 'package:siren_app/features/issues/domain/usecases/update_issue_uc.dart';

class MockIssueRepository extends Mock implements IssueRepository {}

void main() {
  late UpdateIssueUseCase useCase;
  late MockIssueRepository mockRepository;

  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(PriorityLevel.normal);
    registerFallbackValue(IssueStatus.newStatus);
  });

  setUp(() {
    mockRepository = MockIssueRepository();
    useCase = UpdateIssueUseCase(mockRepository);
  });

  group('UpdateIssueUseCase', () {
    const tId = 1;
    const tLockVersion = 5;
    const tSubject = 'Updated Subject';
    const tDescription = 'Updated Description';
    const tPriorityLevel = PriorityLevel.high;
    const tStatus = IssueStatus.inProgress;

    final tUpdatedIssue = IssueEntity(
      id: tId,
      subject: tSubject,
      description: tDescription,
      equipment: 1,
      group: 1,
      priorityLevel: tPriorityLevel,
      status: tStatus,
      lockVersion: tLockVersion + 1,
    );

    test(
      'should return updated IssueEntity when repository call is successful',
      () async {
        // Given
        final params = UpdateIssueParams(
          id: tId,
          lockVersion: tLockVersion,
          subject: tSubject,
          description: tDescription,
          priorityLevel: tPriorityLevel,
          status: tStatus,
        );

        when(
          () => mockRepository.updateIssue(
            id: any(named: 'id'),
            lockVersion: any(named: 'lockVersion'),
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            priorityLevel: any(named: 'priorityLevel'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => Right(tUpdatedIssue));

        // When
        final result = await useCase(params);

        // Then
        expect(result, Right(tUpdatedIssue));
        verify(
          () => mockRepository.updateIssue(
            id: tId,
            lockVersion: tLockVersion,
            subject: tSubject,
            description: tDescription,
            priorityLevel: tPriorityLevel,
            status: tStatus,
          ),
        ).called(1);
        verifyNoMoreInteractions(mockRepository);
      },
    );

    test('should return ValidationFailure when subject is empty', () async {
      // Given
      final params = UpdateIssueParams(
        id: tId,
        lockVersion: tLockVersion,
        subject: '',
        description: tDescription,
      );

      // When
      final result = await useCase(params);

      // Then
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(
          (failure as ValidationFailure).message,
          'Subject cannot be empty',
        );
      }, (_) => fail('Should return failure'));
      verifyNever(
        () => mockRepository.updateIssue(
          id: any(named: 'id'),
          lockVersion: any(named: 'lockVersion'),
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          priorityLevel: any(named: 'priorityLevel'),
          status: any(named: 'status'),
        ),
      );
    });

    test(
      'should return ValidationFailure when subject is only whitespace',
      () async {
        // Given
        final params = UpdateIssueParams(
          id: tId,
          lockVersion: tLockVersion,
          subject: '   ',
          description: tDescription,
        );

        // When
        final result = await useCase(params);

        // Then
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(
            (failure as ValidationFailure).message,
            'Subject cannot be empty',
          );
        }, (_) => fail('Should return failure'));
        verifyNever(
          () => mockRepository.updateIssue(
            id: any(named: 'id'),
            lockVersion: any(named: 'lockVersion'),
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            priorityLevel: any(named: 'priorityLevel'),
            status: any(named: 'status'),
          ),
        );
      },
    );

    test('should return NetworkFailure when network error occurs', () async {
      // Given
      final params = UpdateIssueParams(
        id: tId,
        lockVersion: tLockVersion,
        subject: tSubject,
      );

      when(
        () => mockRepository.updateIssue(
          id: any(named: 'id'),
          lockVersion: any(named: 'lockVersion'),
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          priorityLevel: any(named: 'priorityLevel'),
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async => const Left(NetworkFailure('No internet connection')),
      );

      // When
      final result = await useCase(params);

      // Then
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      // Given
      final params = UpdateIssueParams(
        id: tId,
        lockVersion: tLockVersion,
        subject: tSubject,
      );

      when(
        () => mockRepository.updateIssue(
          id: any(named: 'id'),
          lockVersion: any(named: 'lockVersion'),
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          priorityLevel: any(named: 'priorityLevel'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      // When
      final result = await useCase(params);

      // Then
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test(
      'should return ConflictFailure when lockVersion mismatch (optimistic locking conflict)',
      () async {
        // Given
        final params = UpdateIssueParams(
          id: tId,
          lockVersion: tLockVersion,
          subject: tSubject,
        );

        when(
          () => mockRepository.updateIssue(
            id: any(named: 'id'),
            lockVersion: any(named: 'lockVersion'),
            subject: any(named: 'subject'),
            description: any(named: 'description'),
            priorityLevel: any(named: 'priorityLevel'),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            ConflictFailure('Issue has been modified by another user'),
          ),
        );

        // When
        final result = await useCase(params);

        // Then
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ConflictFailure>()),
          (_) => fail('Should return failure'),
        );
      },
    );

    test('should call repository with correct parameters', () async {
      // Given
      final params = UpdateIssueParams(
        id: tId,
        lockVersion: tLockVersion,
        subject: tSubject,
        description: tDescription,
        priorityLevel: tPriorityLevel,
        status: tStatus,
      );

      when(
        () => mockRepository.updateIssue(
          id: any(named: 'id'),
          lockVersion: any(named: 'lockVersion'),
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          priorityLevel: any(named: 'priorityLevel'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => Right(tUpdatedIssue));

      // When
      await useCase(params);

      // Then
      verify(
        () => mockRepository.updateIssue(
          id: tId,
          lockVersion: tLockVersion,
          subject: tSubject,
          description: tDescription,
          priorityLevel: tPriorityLevel,
          status: tStatus,
        ),
      ).called(1);
    });

    test('should allow updating only subject', () async {
      // Given
      final params = UpdateIssueParams(
        id: tId,
        lockVersion: tLockVersion,
        subject: tSubject,
      );

      when(
        () => mockRepository.updateIssue(
          id: any(named: 'id'),
          lockVersion: any(named: 'lockVersion'),
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          priorityLevel: any(named: 'priorityLevel'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => Right(tUpdatedIssue));

      // When
      final result = await useCase(params);

      // Then
      expect(result, Right(tUpdatedIssue));
      verify(
        () => mockRepository.updateIssue(
          id: tId,
          lockVersion: tLockVersion,
          subject: tSubject,
          description: null,
          priorityLevel: null,
          status: null,
        ),
      ).called(1);
    });

    test('should allow updating only description', () async {
      // Given
      final params = UpdateIssueParams(
        id: tId,
        lockVersion: tLockVersion,
        description: tDescription,
      );

      when(
        () => mockRepository.updateIssue(
          id: any(named: 'id'),
          lockVersion: any(named: 'lockVersion'),
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          priorityLevel: any(named: 'priorityLevel'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => Right(tUpdatedIssue));

      // When
      final result = await useCase(params);

      // Then
      expect(result, Right(tUpdatedIssue));
      verify(
        () => mockRepository.updateIssue(
          id: tId,
          lockVersion: tLockVersion,
          subject: null,
          description: tDescription,
          priorityLevel: null,
          status: null,
        ),
      ).called(1);
    });

    test('should allow updating only priority', () async {
      // Given
      final params = UpdateIssueParams(
        id: tId,
        lockVersion: tLockVersion,
        priorityLevel: tPriorityLevel,
      );

      when(
        () => mockRepository.updateIssue(
          id: any(named: 'id'),
          lockVersion: any(named: 'lockVersion'),
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          priorityLevel: any(named: 'priorityLevel'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => Right(tUpdatedIssue));

      // When
      final result = await useCase(params);

      // Then
      expect(result, Right(tUpdatedIssue));
      verify(
        () => mockRepository.updateIssue(
          id: tId,
          lockVersion: tLockVersion,
          subject: null,
          description: null,
          priorityLevel: tPriorityLevel,
          status: null,
        ),
      ).called(1);
    });

    test('should allow updating only status', () async {
      // Given
      final params = UpdateIssueParams(
        id: tId,
        lockVersion: tLockVersion,
        status: tStatus,
      );

      when(
        () => mockRepository.updateIssue(
          id: any(named: 'id'),
          lockVersion: any(named: 'lockVersion'),
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          priorityLevel: any(named: 'priorityLevel'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => Right(tUpdatedIssue));

      // When
      final result = await useCase(params);

      // Then
      expect(result, Right(tUpdatedIssue));
      verify(
        () => mockRepository.updateIssue(
          id: tId,
          lockVersion: tLockVersion,
          subject: null,
          description: null,
          priorityLevel: null,
          status: tStatus,
        ),
      ).called(1);
    });

    test('should allow updating multiple fields simultaneously', () async {
      // Given
      final params = UpdateIssueParams(
        id: tId,
        lockVersion: tLockVersion,
        subject: tSubject,
        priorityLevel: tPriorityLevel,
        status: tStatus,
      );

      when(
        () => mockRepository.updateIssue(
          id: any(named: 'id'),
          lockVersion: any(named: 'lockVersion'),
          subject: any(named: 'subject'),
          description: any(named: 'description'),
          priorityLevel: any(named: 'priorityLevel'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => Right(tUpdatedIssue));

      // When
      final result = await useCase(params);

      // Then
      expect(result, Right(tUpdatedIssue));
      verify(
        () => mockRepository.updateIssue(
          id: tId,
          lockVersion: tLockVersion,
          subject: tSubject,
          description: null,
          priorityLevel: tPriorityLevel,
          status: tStatus,
        ),
      ).called(1);
    });
  });
}
