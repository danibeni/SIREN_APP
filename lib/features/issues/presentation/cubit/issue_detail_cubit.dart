import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/usecases/get_attachments_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/get_issue_by_id_uc.dart';
import 'package:siren_app/features/issues/presentation/cubit/issue_detail_state.dart';

@injectable
class IssueDetailCubit extends Cubit<IssueDetailState> {
  final GetIssueByIdUseCase getIssueByIdUseCase;
  final GetAttachmentsUseCase getAttachmentsUseCase;
  final Logger logger;

  IssueDetailCubit({
    required this.getIssueByIdUseCase,
    required this.getAttachmentsUseCase,
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
}
