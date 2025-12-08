import 'package:equatable/equatable.dart';
import 'package:siren_app/features/issues/domain/entities/attachment_entity.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

abstract class IssueDetailState extends Equatable {
  const IssueDetailState();

  @override
  List<Object?> get props => [];
}

class IssueDetailInitial extends IssueDetailState {
  const IssueDetailInitial();
}

class IssueDetailLoading extends IssueDetailState {
  const IssueDetailLoading();
}

class IssueDetailLoaded extends IssueDetailState {
  final IssueEntity issue;
  final List<AttachmentEntity> attachments;
  final bool isLoadingAttachments;

  const IssueDetailLoaded(
    this.issue, {
    this.attachments = const [],
    this.isLoadingAttachments = false,
  });

  @override
  List<Object?> get props => [issue, attachments, isLoadingAttachments];

  IssueDetailLoaded copyWith({
    IssueEntity? issue,
    List<AttachmentEntity>? attachments,
    bool? isLoadingAttachments,
  }) {
    return IssueDetailLoaded(
      issue ?? this.issue,
      attachments: attachments ?? this.attachments,
      isLoadingAttachments: isLoadingAttachments ?? this.isLoadingAttachments,
    );
  }
}

class IssueDetailError extends IssueDetailState {
  final String message;

  const IssueDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
