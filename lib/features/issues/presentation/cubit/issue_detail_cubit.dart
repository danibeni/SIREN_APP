import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/usecases/get_issue_by_id_uc.dart';
import 'package:siren_app/features/issues/presentation/cubit/issue_detail_state.dart';

@injectable
class IssueDetailCubit extends Cubit<IssueDetailState> {
  final GetIssueByIdUseCase getIssueByIdUseCase;

  IssueDetailCubit({required this.getIssueByIdUseCase})
    : super(const IssueDetailInitial());

  Future<void> loadIssue(int id) async {
    emit(const IssueDetailLoading());

    final result = await getIssueByIdUseCase(id);

    result.fold(
      (failure) {
        String message = 'Failed to load issue';
        if (failure is NetworkFailure) {
          message = 'Network error: ${failure.message}';
        } else if (failure is ServerFailure) {
          message = 'Server error: ${failure.message}';
        } else if (failure is NotFoundFailure) {
          message = 'Issue not found';
        }
        emit(IssueDetailError(message));
      },
      (issue) {
        emit(IssueDetailLoaded(issue));
      },
    );
  }
}
