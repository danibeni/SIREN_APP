import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/usecases/discard_local_changes_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/get_issues_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/refresh_statuses_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/sync_issue_uc.dart';
import 'issues_list_state.dart';

@injectable
class IssuesListCubit extends Cubit<IssuesListState> {
  IssuesListCubit(
    this._getIssuesUseCase,
    this._refreshStatusesUseCase,
    this._syncIssueUseCase,
    this._discardLocalChangesUseCase,
    this._logger,
  ) : super(const IssuesListInitial());

  final GetIssuesUseCase _getIssuesUseCase;
  final RefreshStatusesUseCase _refreshStatusesUseCase;
  final SyncIssueUseCase _syncIssueUseCase;
  final DiscardLocalChangesUseCase _discardLocalChangesUseCase;
  final Logger _logger;

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

  /// Synchronize an issue with pending offline modifications
  Future<void> syncIssue(int issueId) async {
    _logger.info('Synchronizing issue $issueId');
    final result = await _syncIssueUseCase(issueId);

    result.fold(
      (failure) {
        _logger.warning('Failed to sync issue $issueId: ${failure.message}');
        // Reload issues to show updated state (even on failure)
        loadIssues();
      },
      (updatedIssue) {
        _logger.info('Issue $issueId synchronized successfully');
        // Reload issues to refresh the list with synced data
        loadIssues();
      },
    );
  }

  /// Discard local changes for an issue
  Future<void> discardLocalChanges(int issueId) async {
    _logger.info('Discarding local changes for issue $issueId');
    final result = await _discardLocalChangesUseCase(issueId);

    result.fold(
      (failure) {
        _logger.warning(
          'Failed to discard changes for issue $issueId: ${failure.message}',
        );
        // Reload issues anyway to show current state
        loadIssues();
      },
      (restoredIssue) {
        _logger.info('Local changes discarded for issue $issueId');
        // Reload issues to refresh the list
        loadIssues();
      },
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
