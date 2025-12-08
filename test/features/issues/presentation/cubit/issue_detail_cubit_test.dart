import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/usecases/get_attachments_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/get_issue_by_id_uc.dart';
import 'package:siren_app/features/issues/presentation/cubit/issue_detail_cubit.dart';
import 'package:siren_app/features/issues/presentation/cubit/issue_detail_state.dart';

class MockGetIssueByIdUseCase extends Mock implements GetIssueByIdUseCase {}

class MockGetAttachmentsUseCase extends Mock implements GetAttachmentsUseCase {}

void main() {
  late IssueDetailCubit cubit;
  late MockGetIssueByIdUseCase mockGetIssueByIdUseCase;
  late MockGetAttachmentsUseCase mockGetAttachmentsUseCase;
  late Logger logger;

  setUp(() {
    mockGetIssueByIdUseCase = MockGetIssueByIdUseCase();
    mockGetAttachmentsUseCase = MockGetAttachmentsUseCase();
    logger = Logger('IssueDetailCubit');
    cubit = IssueDetailCubit(
      getIssueByIdUseCase: mockGetIssueByIdUseCase,
      getAttachmentsUseCase: mockGetAttachmentsUseCase,
      logger: logger,
    );
  });

  tearDown(() {
    cubit.close();
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

  group('IssueDetailCubit', () {
    test('initial state is IssueDetailInitial', () {
      expect(cubit.state, equals(const IssueDetailInitial()));
    });

    blocTest<IssueDetailCubit, IssueDetailState>(
      'should emit [Loading, Loaded] when issue is loaded successfully',
      build: () {
        when(
          () => mockGetIssueByIdUseCase(testIssueId),
        ).thenAnswer((_) async => Right(testIssue));
        when(
          () => mockGetAttachmentsUseCase(testIssueId),
        ).thenAnswer((_) async => const Right([]));
        return cubit;
      },
      act: (cubit) => cubit.loadIssue(testIssueId),
      expect: () => [
        const IssueDetailLoading(),
        IssueDetailLoaded(testIssue),
        IssueDetailLoaded(testIssue, isLoadingAttachments: true),
        IssueDetailLoaded(testIssue, isLoadingAttachments: false),
      ],
      verify: (_) {
        verify(() => mockGetIssueByIdUseCase(testIssueId)).called(1);
        verify(() => mockGetAttachmentsUseCase(testIssueId)).called(1);
      },
    );

    blocTest<IssueDetailCubit, IssueDetailState>(
      'should emit [Loading, Error] when loading fails with NetworkFailure',
      build: () {
        when(() => mockGetIssueByIdUseCase(testIssueId)).thenAnswer(
          (_) async => const Left(NetworkFailure('No internet connection')),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadIssue(testIssueId),
      expect: () => [
        const IssueDetailLoading(),
        const IssueDetailError('Network error: No internet connection'),
      ],
      verify: (_) {
        verify(() => mockGetIssueByIdUseCase(testIssueId)).called(1);
        verifyNever(() => mockGetAttachmentsUseCase(testIssueId));
      },
    );

    blocTest<IssueDetailCubit, IssueDetailState>(
      'should emit [Loading, Error] when loading fails with ServerFailure',
      build: () {
        when(
          () => mockGetIssueByIdUseCase(testIssueId),
        ).thenAnswer((_) async => const Left(ServerFailure('Server error')));
        return cubit;
      },
      act: (cubit) => cubit.loadIssue(testIssueId),
      expect: () => [
        const IssueDetailLoading(),
        const IssueDetailError('Server error: Server error'),
      ],
      verify: (_) {
        verify(() => mockGetIssueByIdUseCase(testIssueId)).called(1);
        verifyNever(() => mockGetAttachmentsUseCase(testIssueId));
      },
    );

    blocTest<IssueDetailCubit, IssueDetailState>(
      'should emit [Loading, Error] when issue not found',
      build: () {
        when(() => mockGetIssueByIdUseCase(testIssueId)).thenAnswer(
          (_) async => const Left(NotFoundFailure('Issue not found')),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadIssue(testIssueId),
      expect: () => [
        const IssueDetailLoading(),
        const IssueDetailError('Issue not found'),
      ],
      verify: (_) {
        verify(() => mockGetIssueByIdUseCase(testIssueId)).called(1);
        verifyNever(() => mockGetAttachmentsUseCase(testIssueId));
      },
    );
  });
}
