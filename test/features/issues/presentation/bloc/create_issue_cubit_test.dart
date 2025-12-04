import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/data/datasources/issue_remote_datasource.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/usecases/create_issue_uc.dart';
import 'package:siren_app/features/issues/presentation/bloc/create_issue_cubit.dart';
import 'package:siren_app/features/issues/presentation/bloc/create_issue_state.dart';

import '../../../../core/fixtures/issue_fixtures.dart';

class MockCreateIssueUseCase extends Mock implements CreateIssueUseCase {}

class MockIssueRemoteDataSource extends Mock implements IssueRemoteDataSource {}

void main() {
  late CreateIssueCubit cubit;
  late MockCreateIssueUseCase mockUseCase;
  late MockIssueRemoteDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(
      const CreateIssueParams(
        subject: '',
        priorityLevel: PriorityLevel.normal,
        group: 0,
        equipment: 0,
      ),
    );
    registerFallbackValue(PriorityLevel.normal);
  });

  setUp(() {
    mockUseCase = MockCreateIssueUseCase();
    mockDataSource = MockIssueRemoteDataSource();
    cubit = CreateIssueCubit(mockUseCase, mockDataSource);
  });

  tearDown(() {
    cubit.close();
  });

  group('CreateIssueCubit', () {
    group('initializeForm', () {
      blocTest<CreateIssueCubit, CreateIssueState>(
        'emits [Loading, FormReady] with groups when initialization succeeds',
        build: () {
          when(
            () => mockDataSource.getGroups(),
          ).thenAnswer((_) async => IssueFixtures.createGroupMapList(count: 3));
          return cubit;
        },
        act: (cubit) => cubit.initializeForm(),
        expect: () => [
          const CreateIssueLoading(),
          isA<CreateIssueFormReady>()
              .having((s) => s.groups.length, 'groups count', 3)
              .having((s) => s.selectedGroupId, 'selectedGroupId', isNull)
              .having(
                (s) => s.selectedPriority,
                'default priority',
                PriorityLevel.normal,
              ),
        ],
        verify: (_) {
          verify(() => mockDataSource.getGroups()).called(1);
        },
      );

      blocTest<CreateIssueCubit, CreateIssueState>(
        'auto-selects group and loads projects when user belongs to only one'
        ' group',
        build: () {
          when(() => mockDataSource.getGroups()).thenAnswer(
            (_) async => [
              IssueFixtures.createGroupMap(id: 10, name: 'Only Group'),
            ],
          );
          when(() => mockDataSource.getProjectsByGroup(any())).thenAnswer(
            (_) async => IssueFixtures.createProjectMapList(count: 2),
          );
          return cubit;
        },
        act: (cubit) => cubit.initializeForm(),
        expect: () => [
          const CreateIssueLoading(),
          isA<CreateIssueFormReady>()
              .having((s) => s.groups.length, 'groups count', 1)
              .having((s) => s.selectedGroupId, 'auto-selected group', 10)
              .having((s) => s.projects.length, 'projects count', 2),
        ],
        verify: (_) {
          verify(() => mockDataSource.getGroups()).called(1);
          verify(() => mockDataSource.getProjectsByGroup(10)).called(1);
        },
      );

      blocTest<CreateIssueCubit, CreateIssueState>(
        'emits [Loading, Error] when no groups available',
        build: () {
          when(() => mockDataSource.getGroups()).thenAnswer((_) async => []);
          return cubit;
        },
        act: (cubit) => cubit.initializeForm(),
        expect: () => [
          const CreateIssueLoading(),
          isA<CreateIssueError>().having(
            (s) => s.message,
            'error message',
            contains('No groups'),
          ),
        ],
      );

      blocTest<CreateIssueCubit, CreateIssueState>(
        'emits [Loading, Error] when getGroups throws',
        build: () {
          when(
            () => mockDataSource.getGroups(),
          ).thenThrow(const ServerFailure('Network error'));
          return cubit;
        },
        act: (cubit) => cubit.initializeForm(),
        expect: () => [
          const CreateIssueLoading(),
          isA<CreateIssueError>().having(
            (s) => s.message,
            'error message',
            contains('Failed to load'),
          ),
        ],
      );
    });

    group('selectGroup', () {
      blocTest<CreateIssueCubit, CreateIssueState>(
        'loads projects for selected group',
        build: () {
          when(() => mockDataSource.getProjectsByGroup(any())).thenAnswer(
            (_) async => IssueFixtures.createProjectMapList(count: 2),
          );
          return cubit;
        },
        seed: () => CreateIssueFormReady(
          groups: [
            const GroupItem(id: 10, name: 'Group 1'),
            const GroupItem(id: 20, name: 'Group 2'),
          ],
        ),
        act: (cubit) => cubit.selectGroup(20),
        expect: () => [
          isA<CreateIssueLoadingProjects>(),
          isA<CreateIssueFormReady>()
              .having((s) => s.selectedGroupId, 'selected group', 20)
              .having((s) => s.projects.length, 'projects count', 2)
              .having((s) => s.selectedProjectId, 'cleared project', isNull),
        ],
        verify: (_) {
          verify(() => mockDataSource.getProjectsByGroup(20)).called(1);
        },
      );

      blocTest<CreateIssueCubit, CreateIssueState>(
        'clears selected project when group changes',
        build: () {
          when(() => mockDataSource.getProjectsByGroup(any())).thenAnswer(
            (_) async => IssueFixtures.createProjectMapList(count: 1),
          );
          return cubit;
        },
        seed: () => CreateIssueFormReady(
          groups: [const GroupItem(id: 10, name: 'Group 1')],
          projects: [const ProjectItem(id: 100, name: 'Old Project')],
          selectedGroupId: 10,
          selectedProjectId: 100,
        ),
        act: (cubit) => cubit.selectGroup(10),
        expect: () => [
          isA<CreateIssueLoadingProjects>().having(
            (s) => s.formState.selectedProjectId,
            'cleared',
            isNull,
          ),
          isA<CreateIssueFormReady>().having(
            (s) => s.selectedProjectId,
            'cleared project',
            isNull,
          ),
        ],
      );
    });

    group('selectProject', () {
      blocTest<CreateIssueCubit, CreateIssueState>(
        'updates selected project',
        build: () => cubit,
        seed: () => CreateIssueFormReady(
          groups: [const GroupItem(id: 10, name: 'Group')],
          projects: [
            const ProjectItem(id: 100, name: 'Project 1'),
            const ProjectItem(id: 101, name: 'Project 2'),
          ],
          selectedGroupId: 10,
        ),
        act: (cubit) => cubit.selectProject(101),
        expect: () => [
          isA<CreateIssueFormReady>().having(
            (s) => s.selectedProjectId,
            'selected',
            101,
          ),
        ],
      );
    });

    group('selectPriority', () {
      blocTest<CreateIssueCubit, CreateIssueState>(
        'updates selected priority',
        build: () => cubit,
        seed: () => CreateIssueFormReady(
          groups: [const GroupItem(id: 10, name: 'Group')],
          selectedPriority: PriorityLevel.normal,
        ),
        act: (cubit) => cubit.selectPriority(PriorityLevel.high),
        expect: () => [
          isA<CreateIssueFormReady>().having(
            (s) => s.selectedPriority,
            'priority',
            PriorityLevel.high,
          ),
        ],
      );
    });

    group('updateSubject', () {
      blocTest<CreateIssueCubit, CreateIssueState>(
        'updates subject field',
        build: () => cubit,
        seed: () => const CreateIssueFormReady(
          groups: [GroupItem(id: 10, name: 'Group')],
          subject: '',
        ),
        act: (cubit) => cubit.updateSubject('New Subject'),
        expect: () => [
          isA<CreateIssueFormReady>().having(
            (s) => s.subject,
            'subject',
            'New Subject',
          ),
        ],
      );

      blocTest<CreateIssueCubit, CreateIssueState>(
        'clears subject validation error when typing',
        build: () => cubit,
        seed: () => const CreateIssueFormReady(
          groups: [GroupItem(id: 10, name: 'Group')],
          subject: '',
          validationErrors: {'subject': 'Subject is required'},
        ),
        act: (cubit) => cubit.updateSubject('A'),
        expect: () => [
          isA<CreateIssueFormReady>().having(
            (s) => s.validationErrors,
            'errors',
            isEmpty,
          ),
        ],
      );
    });

    group('submitForm', () {
      blocTest<CreateIssueCubit, CreateIssueState>(
        'emits validation errors when form is invalid',
        build: () => cubit,
        seed: () => const CreateIssueFormReady(
          groups: [GroupItem(id: 10, name: 'Group')],
          subject: '',
          selectedGroupId: 10,
        ),
        act: (cubit) => cubit.submitForm(),
        expect: () => [
          isA<CreateIssueFormReady>().having(
            (s) => s.validationErrors.containsKey('subject'),
            'has subject error',
            true,
          ),
        ],
      );

      blocTest<CreateIssueCubit, CreateIssueState>(
        'emits [Submitting, Success] when submission succeeds',
        build: () {
          final entity = IssueFixtures.createIssueEntity(id: 123);
          when(() => mockUseCase(any())).thenAnswer((_) async => Right(entity));
          return cubit;
        },
        seed: () => const CreateIssueFormReady(
          groups: [GroupItem(id: 10, name: 'Group')],
          projects: [ProjectItem(id: 100, name: 'Project')],
          subject: 'Test Issue',
          selectedGroupId: 10,
          selectedProjectId: 100,
          selectedPriority: PriorityLevel.high,
        ),
        act: (cubit) => cubit.submitForm(),
        expect: () => [
          const CreateIssueSubmitting(),
          isA<CreateIssueSuccess>().having((s) => s.issue.id, 'issue id', 123),
        ],
        verify: (_) {
          verify(() => mockUseCase(any())).called(1);
        },
      );

      blocTest<CreateIssueCubit, CreateIssueState>(
        'emits [Submitting, Error] when submission fails',
        build: () {
          when(
            () => mockUseCase(any()),
          ).thenAnswer((_) async => const Left(ServerFailure('Server error')));
          return cubit;
        },
        seed: () => const CreateIssueFormReady(
          groups: [GroupItem(id: 10, name: 'Group')],
          projects: [ProjectItem(id: 100, name: 'Project')],
          subject: 'Test Issue',
          selectedGroupId: 10,
          selectedProjectId: 100,
          selectedPriority: PriorityLevel.normal,
        ),
        act: (cubit) => cubit.submitForm(),
        expect: () => [
          const CreateIssueSubmitting(),
          isA<CreateIssueError>()
              .having((s) => s.message, 'error', 'Server error')
              .having((s) => s.previousFormState, 'preserves state', isNotNull),
        ],
      );

      blocTest<CreateIssueCubit, CreateIssueState>(
        'emits [Submitting, Error] with validation message when use case'
        ' returns ValidationFailure',
        build: () {
          when(() => mockUseCase(any())).thenAnswer(
            (_) async => const Left(ValidationFailure('Subject is required')),
          );
          return cubit;
        },
        seed: () => const CreateIssueFormReady(
          groups: [GroupItem(id: 10, name: 'Group')],
          projects: [ProjectItem(id: 100, name: 'Project')],
          subject: 'Test',
          selectedGroupId: 10,
          selectedProjectId: 100,
          selectedPriority: PriorityLevel.normal,
        ),
        act: (cubit) => cubit.submitForm(),
        expect: () => [
          const CreateIssueSubmitting(),
          isA<CreateIssueError>().having(
            (s) => s.message,
            'message',
            'Subject is required',
          ),
        ],
      );
    });

    group('resetToForm', () {
      blocTest<CreateIssueCubit, CreateIssueState>(
        'restores previous form state after error',
        build: () => cubit,
        seed: () => const CreateIssueError(
          'Some error',
          previousFormState: CreateIssueFormReady(
            groups: [GroupItem(id: 10, name: 'Group')],
            subject: 'Preserved Subject',
          ),
        ),
        act: (cubit) => cubit.resetToForm(),
        expect: () => [
          isA<CreateIssueFormReady>().having(
            (s) => s.subject,
            'preserved',
            'Preserved Subject',
          ),
        ],
      );
    });
  });
}
