import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/usecases/get_issues_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/refresh_statuses_uc.dart';
import 'issues_list_state.dart';

@injectable
class IssuesListCubit extends Cubit<IssuesListState> {
  IssuesListCubit(this._getIssuesUseCase, this._refreshStatusesUseCase)
    : super(const IssuesListInitial());

  final GetIssuesUseCase _getIssuesUseCase;
  final RefreshStatusesUseCase _refreshStatusesUseCase;

  Future<void> loadIssues() async {
    emit(const IssuesListLoading());
    final result = await _getIssuesUseCase();
    result.fold((failure) {
      // Check if error message indicates cached data (when offline)
      final isOfflineWithCache =
          failure is NetworkFailure &&
          !failure.message.contains('no cached data');
      if (isOfflineWithCache) {
        // Should not happen, repository handles cache fallback
        emit(IssuesListError(_mapFailure(failure)));
      } else {
        emit(IssuesListError(_mapFailure(failure)));
      }
    }, (issues) => emit(IssuesListLoaded(issues)));
  }

  Future<void> refresh() async {
    final current = state;
    if (current is IssuesListLoaded) {
      emit(IssuesListRefreshing(current.issues));
    }

    // Refresh statuses cache from server (will fail silently if offline)
    await _refreshStatusesUseCase();

    // Then fetch issues
    final result = await _getIssuesUseCase();
    result.fold((failure) {
      // If refresh fails but we have cached data, restore previous state
      if (current is IssuesListLoaded) {
        emit(IssuesListLoaded(current.issues, isFromCache: true));
      } else {
        emit(IssuesListError(_mapFailure(failure)));
      }
    }, (issues) => emit(IssuesListLoaded(issues)));
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
