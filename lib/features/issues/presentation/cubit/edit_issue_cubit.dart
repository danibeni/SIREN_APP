import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/usecases/get_issue_by_id_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/update_issue_params.dart';
import 'package:siren_app/features/issues/domain/usecases/update_issue_uc.dart';
import 'edit_issue_state.dart';

@injectable
class EditIssueCubit extends Cubit<EditIssueState> {
  EditIssueCubit(this._getIssueById, this._updateIssue)
    : super(const EditIssueInitial());

  final GetIssueByIdUseCase _getIssueById;
  final UpdateIssueUseCase _updateIssue;

  Future<void> load(int issueId) async {
    emit(const EditIssueLoading());
    final result = await _getIssueById(issueId);
    result.fold(
      (failure) => emit(EditIssueError(failure.message)),
      (issue) => emit(
        EditIssueLoaded(
          issue: issue,
          subject: issue.subject,
          description: issue.description,
          priority: issue.priorityLevel,
          status: issue.status,
        ),
      ),
    );
  }

  void initializeFromEntity(IssueEntity issue) {
    emit(
      EditIssueLoaded(
        issue: issue,
        subject: issue.subject,
        description: issue.description,
        priority: issue.priorityLevel,
        status: issue.status,
      ),
    );
  }

  void updateSubject(String value) {
    final current = state;
    if (current is! EditIssueLoaded) return;
    final errors = Map<String, String>.from(current.validationErrors);
    errors.remove('subject');
    emit(current.copyWith(subject: value, validationErrors: errors));
  }

  void updateDescription(String? value) {
    final current = state;
    if (current is! EditIssueLoaded) return;
    emit(current.copyWith(description: value));
  }

  void updatePriority(PriorityLevel priority) {
    final current = state;
    if (current is! EditIssueLoaded) return;
    emit(current.copyWith(priority: priority));
  }

  void updateStatus(IssueStatus status) {
    final current = state;
    if (current is! EditIssueLoaded) return;
    emit(current.copyWith(status: status));
  }

  Future<void> submit() async {
    final current = state;
    if (current is! EditIssueLoaded) return;

    final trimmedSubject = current.subject.trim();
    if (trimmedSubject.isEmpty) {
      emit(
        current.copyWith(validationErrors: {'subject': 'Subject is required'}),
      );
      return;
    }

    emit(EditIssueSaving(current));

    final params = UpdateIssueParams(
      id: current.issue.id!,
      lockVersion: current.issue.lockVersion,
      subject: trimmedSubject,
      description: current.description?.trim().isEmpty ?? true
          ? null
          : current.description,
      priorityLevel: current.priority,
      status: current.status,
    );

    final result = await _updateIssue(params);

    result.fold(
      (failure) {
        String message = 'Failed to update issue';
        if (failure is ValidationFailure) {
          message = failure.message;
        } else if (failure is ServerFailure) {
          message = failure.message;
        } else if (failure is NetworkFailure) {
          message = 'Network error: ${failure.message}';
        }
        emit(EditIssueError(message, previousForm: current));
      },
      (issue) {
        emit(EditIssueSuccess(issue));
      },
    );
  }
}
