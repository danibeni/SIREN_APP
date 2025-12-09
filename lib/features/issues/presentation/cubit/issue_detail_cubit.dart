import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/core/network/connectivity_service.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/usecases/add_attachment_params.dart';
import 'package:siren_app/features/issues/domain/usecases/add_attachment_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/get_attachments_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/get_issue_by_id_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/update_issue_params.dart';
import 'package:siren_app/features/issues/domain/usecases/update_issue_uc.dart';
import 'package:siren_app/features/issues/presentation/cubit/issue_detail_state.dart';

@injectable
class IssueDetailCubit extends Cubit<IssueDetailState> {
  final GetIssueByIdUseCase getIssueByIdUseCase;
  final GetAttachmentsUseCase getAttachmentsUseCase;
  final UpdateIssueUseCase updateIssueUseCase;
  final AddAttachmentUseCase addAttachmentUseCase;
  final ConnectivityService connectivityService;
  final Logger logger;

  IssueDetailCubit({
    required this.getIssueByIdUseCase,
    required this.getAttachmentsUseCase,
    required this.updateIssueUseCase,
    required this.addAttachmentUseCase,
    required this.connectivityService,
    required this.logger,
  }) : super(const IssueDetailInitial());

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
        // Load attachments after issue is loaded
        _loadAttachments(id);
      },
    );
  }

  Future<void> _loadAttachments(int issueId) async {
    final currentState = state;
    if (currentState is! IssueDetailLoaded) return;

    logger.info('Starting to load attachments for issue $issueId');

    // Set loading state for attachments
    emit(currentState.copyWith(isLoadingAttachments: true));

    final result = await getAttachmentsUseCase(issueId);

    result.fold(
      (failure) {
        logger.warning('Failed to load attachments: ${failure.message}');
        // On failure, just clear loading state but keep issue displayed
        emit(currentState.copyWith(isLoadingAttachments: false));
      },
      (attachments) {
        logger.info('Loaded ${attachments.length} attachments');
        for (var attachment in attachments) {
          logger.info(
            'Attachment: ${attachment.fileName} (${attachment.contentType})',
          );
        }
        emit(
          currentState.copyWith(
            attachments: attachments,
            isLoadingAttachments: false,
          ),
        );
      },
    );
  }

  /// Enter edit mode
  void enterEditMode() {
    final currentState = state;
    if (currentState is IssueDetailLoaded) {
      emit(
        IssueDetailEditing(
          issue: currentState.issue,
          attachments: currentState.attachments,
          editedSubject: currentState.issue.subject,
          editedDescription: currentState.issue.description,
          editedPriority: currentState.issue.priorityLevel,
          editedStatus: currentState.issue.status,
        ),
      );
    }
  }

  /// Update edited subject
  void updateSubject(String subject) {
    final currentState = state;
    if (currentState is IssueDetailEditing) {
      emit(currentState.copyWith(editedSubject: subject));
    }
  }

  /// Update edited description
  void updateDescription(String? description) {
    final currentState = state;
    if (currentState is IssueDetailEditing) {
      emit(currentState.copyWith(editedDescription: description));
    }
  }

  /// Update edited priority
  void updatePriority(PriorityLevel priority) {
    final currentState = state;
    if (currentState is IssueDetailEditing) {
      emit(currentState.copyWith(editedPriority: priority));
    }
  }

  /// Update edited status
  void updateStatus(IssueStatus status) {
    final currentState = state;
    if (currentState is IssueDetailEditing) {
      emit(currentState.copyWith(editedStatus: status));
    }
  }

  /// Save issue changes
  Future<void> saveChanges() async {
    final currentState = state;
    if (currentState is! IssueDetailEditing) return;

    emit(
      IssueDetailSaving(
        issue: currentState.issue,
        attachments: currentState.attachments,
        editedSubject: currentState.editedSubject,
        editedDescription: currentState.editedDescription,
        editedPriority: currentState.editedPriority,
        editedStatus: currentState.editedStatus,
      ),
    );

    // Check connectivity
    final isOnline = await connectivityService.isConnected();

    final params = UpdateIssueParams(
      id: currentState.issue.id!,
      lockVersion: currentState.issue.lockVersion,
      subject: currentState.editedSubject,
      description: currentState.editedDescription,
      priorityLevel: currentState.editedPriority,
      status: currentState.editedStatus,
    );

    final result = await updateIssueUseCase(params);

    result.fold(
      (failure) {
        String message = 'Failed to update issue';
        if (failure is ValidationFailure) {
          message = failure.message;
        } else if (failure is ConflictFailure) {
          message =
              'Issue has been modified by another user. Please refresh and try again.';
        } else if (failure is NetworkFailure) {
          message = 'Network error: ${failure.message}';
        } else if (failure is ServerFailure) {
          message = 'Server error: ${failure.message}';
        }
        emit(IssueDetailError(message));
      },
      (updatedIssue) {
        emit(
          IssueDetailSaveSuccess(
            issue: updatedIssue,
            attachments: currentState.attachments,
            wasOffline: !isOnline,
          ),
        );
        // After successful save, return to loaded mode
        Future.delayed(const Duration(milliseconds: 500), () {
          emit(
            IssueDetailLoaded(
              updatedIssue,
              attachments: currentState.attachments,
            ),
          );
        });
      },
    );
  }

  /// Cancel edit mode
  void cancelEdit() {
    final currentState = state;
    if (currentState is IssueDetailEditing ||
        currentState is IssueDetailSaving) {
      // Return to read-only mode with original issue
      final originalIssue = currentState is IssueDetailEditing
          ? currentState.issue
          : (currentState as IssueDetailSaving).issue;
      final attachments = currentState is IssueDetailEditing
          ? currentState.attachments
          : (currentState as IssueDetailSaving).attachments;
      emit(IssueDetailLoaded(originalIssue, attachments: attachments));
    }
  }

  /// Add attachment
  Future<void> addAttachment({
    required String filePath,
    required String fileName,
    String? description,
  }) async {
    final currentState = state;
    if (currentState is! IssueDetailEditing) return;

    final params = AddAttachmentParams(
      issueId: currentState.issue.id!,
      filePath: filePath,
      fileName: fileName,
      description: description,
    );

    final result = await addAttachmentUseCase(params);

    result.fold(
      (failure) {
        // Handle error (show snackbar, etc.)
        logger.warning('Failed to add attachment: ${failure.message}');
      },
      (attachment) {
        // Add attachment to current state
        final updatedAttachments = [...currentState.attachments, attachment];
        emit(currentState.copyWith(attachments: updatedAttachments));
      },
    );
  }
}
