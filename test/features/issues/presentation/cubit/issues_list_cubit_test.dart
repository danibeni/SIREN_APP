import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/usecases/get_issues_uc.dart';
import 'package:siren_app/features/issues/presentation/cubit/issues_list_cubit.dart';
import 'package:siren_app/features/issues/presentation/cubit/issues_list_state.dart';

import '../../../../core/fixtures/issue_fixtures.dart';

class _MockGetIssuesUseCase extends Mock implements GetIssuesUseCase {}

void main() {
  late IssuesListCubit cubit;
  late _MockGetIssuesUseCase getIssuesUseCase;

  setUp(() {
    getIssuesUseCase = _MockGetIssuesUseCase();
    cubit = IssuesListCubit(getIssuesUseCase);
  });

  tearDown(() {
    cubit.close();
  });

  group('IssuesListCubit', () {
    test('emits loading then loaded on success', () async {
      // Given
      final issues = IssueFixtures.createIssueEntityList(count: 1);
      when(() => getIssuesUseCase()).thenAnswer((_) async => Right(issues));

      // Expect
      expectLater(
        cubit.stream,
        emitsInOrder([isA<IssuesListLoading>(), isA<IssuesListLoaded>()]),
      );

      // When
      await cubit.loadIssues();
    });

    test('emits loading then error on failure', () async {
      // Given
      when(
        () => getIssuesUseCase(),
      ).thenAnswer((_) async => const Left(ServerFailure('fail')));

      // Expect
      expectLater(
        cubit.stream,
        emitsInOrder([isA<IssuesListLoading>(), isA<IssuesListError>()]),
      );

      // When
      await cubit.loadIssues();
    });

    test('refresh emits refreshing then loaded', () async {
      // Given
      final issues = IssueFixtures.createIssueEntityList(count: 2);
      when(() => getIssuesUseCase()).thenAnswer((_) async => Right(issues));
      await cubit.loadIssues();
      final newIssues = IssueFixtures.createIssueEntityList(count: 1);
      when(() => getIssuesUseCase()).thenAnswer((_) async => Right(newIssues));

      // Expect
      expectLater(
        cubit.stream,
        emitsInOrder([isA<IssuesListRefreshing>(), isA<IssuesListLoaded>()]),
      );

      // When
      await cubit.refresh();
    });
  });
}
