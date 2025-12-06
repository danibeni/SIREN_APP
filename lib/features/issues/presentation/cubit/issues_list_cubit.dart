import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/usecases/get_issues_uc.dart';
import 'issues_list_state.dart';

@injectable
class IssuesListCubit extends Cubit<IssuesListState> {
  IssuesListCubit(this._getIssuesUseCase) : super(const IssuesListInitial());

  final GetIssuesUseCase _getIssuesUseCase;

  Future<void> loadIssues() async {
    emit(const IssuesListLoading());
    final result = await _getIssuesUseCase();
    result.fold(
      (failure) => emit(IssuesListError(_mapFailure(failure))),
      (issues) => emit(IssuesListLoaded(issues)),
    );
  }

  Future<void> refresh() async {
    final current = state;
    if (current is IssuesListLoaded) {
      emit(IssuesListRefreshing(current.issues));
    }
    final result = await _getIssuesUseCase();
    result.fold(
      (failure) => emit(IssuesListError(_mapFailure(failure))),
      (issues) => emit(IssuesListLoaded(issues)),
    );
  }

  String _mapFailure(Failure failure) {
    if (failure is NetworkFailure) {
      return failure.message.isNotEmpty
          ? failure.message
          : 'Network error while loading issues';
    }
    if (failure is ServerFailure) {
      return failure.message.isNotEmpty
          ? failure.message
          : 'Server error while loading issues';
    }
    return 'Unexpected error while loading issues';
  }
}
