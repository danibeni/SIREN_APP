import 'package:equatable/equatable.dart';
import 'package:siren_app/features/issues/domain/entities/attachment_entity.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/entities/priority_entity.dart';
import 'package:siren_app/features/issues/domain/entities/status_entity.dart';

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

class IssueDetailEditing extends IssueDetailState {
  final IssueEntity issue;
  final List<AttachmentEntity> attachments;
  final String editedSubject;
  final String? editedDescription;
  final PriorityLevel editedPriority;
  final IssueStatus editedStatus;
  final StatusEntity? editedStatusEntity;
  final List<StatusEntity> availableStatuses;
  final List<PriorityEntity> availablePriorities;
  final bool isLoadingStatuses;
  final bool isLoadingPriorities;

  const IssueDetailEditing({
    required this.issue,
    this.attachments = const [],
    required this.editedSubject,
    this.editedDescription,
    required this.editedPriority,
    required this.editedStatus,
    this.editedStatusEntity,
    this.availableStatuses = const [],
    this.availablePriorities = const [],
    this.isLoadingStatuses = false,
    this.isLoadingPriorities = false,
  });

  @override
  List<Object?> get props => [
    issue,
    attachments,
    editedSubject,
    editedDescription,
    editedPriority,
    editedStatus,
    editedStatusEntity,
    availableStatuses,
    availablePriorities,
    isLoadingStatuses,
    isLoadingPriorities,
  ];

  IssueDetailEditing copyWith({
    IssueEntity? issue,
    List<AttachmentEntity>? attachments,
    String? editedSubject,
    String? editedDescription,
    PriorityLevel? editedPriority,
    IssueStatus? editedStatus,
    StatusEntity? editedStatusEntity,
    List<StatusEntity>? availableStatuses,
    List<PriorityEntity>? availablePriorities,
    bool? isLoadingStatuses,
    bool? isLoadingPriorities,
  }) {
    return IssueDetailEditing(
      issue: issue ?? this.issue,
      attachments: attachments ?? this.attachments,
      editedSubject: editedSubject ?? this.editedSubject,
      editedDescription: editedDescription ?? this.editedDescription,
      editedPriority: editedPriority ?? this.editedPriority,
      editedStatus: editedStatus ?? this.editedStatus,
      editedStatusEntity: editedStatusEntity ?? this.editedStatusEntity,
      availableStatuses: availableStatuses ?? this.availableStatuses,
      availablePriorities: availablePriorities ?? this.availablePriorities,
      isLoadingStatuses: isLoadingStatuses ?? this.isLoadingStatuses,
      isLoadingPriorities: isLoadingPriorities ?? this.isLoadingPriorities,
    );
  }
}

class IssueDetailSaving extends IssueDetailState {
  final IssueEntity issue;
  final List<AttachmentEntity> attachments;
  final String editedSubject;
  final String? editedDescription;
  final PriorityLevel editedPriority;
  final IssueStatus editedStatus;
  final StatusEntity? editedStatusEntity;
  final List<StatusEntity> availableStatuses;
  final List<PriorityEntity> availablePriorities;

  const IssueDetailSaving({
    required this.issue,
    this.attachments = const [],
    required this.editedSubject,
    this.editedDescription,
    required this.editedPriority,
    required this.editedStatus,
    this.editedStatusEntity,
    this.availableStatuses = const [],
    this.availablePriorities = const [],
  });

  @override
  List<Object?> get props => [
    issue,
    attachments,
    editedSubject,
    editedDescription,
    editedPriority,
    editedStatus,
    editedStatusEntity,
    availableStatuses,
    availablePriorities,
  ];
}

class IssueDetailSaveSuccess extends IssueDetailState {
  final IssueEntity issue;
  final List<AttachmentEntity> attachments;
  final bool wasOffline;

  const IssueDetailSaveSuccess({
    required this.issue,
    this.attachments = const [],
    this.wasOffline = false,
  });

  @override
  List<Object?> get props => [issue, attachments, wasOffline];
}
