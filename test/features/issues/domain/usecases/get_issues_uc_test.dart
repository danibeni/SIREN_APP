import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/usecases/get_issues_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/get_work_package_type_uc.dart';

import '../../../../core/fixtures/issue_fixtures.dart';
import '../../../../core/mocks/mock_issue_repository.dart';

class MockGetWorkPackageTypeUseCase extends Mock
    implements GetWorkPackageTypeUseCase {}

void main() {
  late GetIssuesUseCase useCase;
  late MockIssueRepository repository;
  late MockGetWorkPackageTypeUseCase mockGetWorkPackageTypeUseCase;

  setUp(() {
    repository = MockIssueRepository();
    mockGetWorkPackageTypeUseCase = MockGetWorkPackageTypeUseCase();
    useCase = GetIssuesUseCase(repository, mockGetWorkPackageTypeUseCase);

    // Default: return "Issue" as configured type
    when(
      () => mockGetWorkPackageTypeUseCase(),
    ).thenAnswer((_) async => const Right('Issue'));
  });

  group('GetIssuesUseCase', () {
    test('should return issues when repository succeeds', () async {
      // Given
      final issues = IssueFixtures.createIssueEntityList(count: 2);
      when(
        () => repository.getIssues(
          workPackageType: any(named: 'workPackageType'),
        ),
      ).thenAnswer((_) async => Right(issues));

      // When
      final result = await useCase();

      // Then
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected success'),
        (value) => expect(value.length, 2),
      );
      verify(() => repository.getIssues(workPackageType: 'Issue')).called(1);
    });

    test('should propagate empty list', () async {
      // Given
      when(
        () => repository.getIssues(
          workPackageType: any(named: 'workPackageType'),
        ),
      ).thenAnswer((_) async => const Right([]));

      // When
      final result = await useCase();

      // Then
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected success'),
        (value) => expect(value, isEmpty),
      );
    });

    test('should return NetworkFailure on network error', () async {
      // Given
      when(
        () => repository.getIssues(
          workPackageType: any(named: 'workPackageType'),
        ),
      ).thenAnswer((_) async => const Left(NetworkFailure('offline')));

      // When
      final result = await useCase();

      // Then
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected failure'),
      );
    });

    test('should return ServerFailure on server error', () async {
      // Given
      when(
        () => repository.getIssues(
          workPackageType: any(named: 'workPackageType'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure('server down')));

      // When
      final result = await useCase();

      // Then
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected failure'),
      );
    });

    test('should forward filters to repository', () async {
      // Given
      when(
        () => repository.getIssues(
          status: any(named: 'status'),
          equipmentId: any(named: 'equipmentId'),
          priorityLevel: any(named: 'priorityLevel'),
          groupId: any(named: 'groupId'),
          workPackageType: any(named: 'workPackageType'),
        ),
      ).thenAnswer((_) async => const Right([]));

      // When
      await useCase(
        status: IssueStatus.inProgress,
        equipmentId: 7,
        priorityLevel: PriorityLevel.high,
        groupId: 5,
      );

      // Then
      verify(
        () => repository.getIssues(
          status: IssueStatus.inProgress,
          equipmentId: 7,
          priorityLevel: PriorityLevel.high,
          groupId: 5,
          workPackageType: 'Issue',
        ),
      ).called(1);
    });

    test('should return failure when type retrieval fails', () async {
      // Given
      when(() => mockGetWorkPackageTypeUseCase()).thenAnswer(
        (_) async => const Left(ServerFailure('Failed to get type')),
      );

      // When
      final result = await useCase();

      // Then
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected failure'),
      );
      verifyNever(
        () => repository.getIssues(
          workPackageType: any(named: 'workPackageType'),
        ),
      );
    });
  });
}
