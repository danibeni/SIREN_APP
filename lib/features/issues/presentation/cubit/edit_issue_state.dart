import 'package:equatable/equatable.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

abstract class EditIssueState extends Equatable {
  const EditIssueState();

  @override
  List<Object?> get props => [];
}

class EditIssueInitial extends EditIssueState {
  const EditIssueInitial();
}

class EditIssueLoading extends EditIssueState {
  const EditIssueLoading();
}

class EditIssueLoaded extends EditIssueState {
  final IssueEntity issue;
  final String subject;
  final String? description;
  final PriorityLevel priority;
  final IssueStatus status;
  final Map<String, String> validationErrors;

  const EditIssueLoaded({
    required this.issue,
    required this.subject,
    this.description,
    required this.priority,
    required this.status,
    this.validationErrors = const {},
  });

  EditIssueLoaded copyWith({
    IssueEntity? issue,
    String? subject,
    String? description,
    PriorityLevel? priority,
    IssueStatus? status,
    Map<String, String>? validationErrors,
  }) {
    return EditIssueLoaded(
      issue: issue ?? this.issue,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  @override
  List<Object?> get props => [
    issue,
    subject,
    description,
    priority,
    status,
    validationErrors,
  ];
}

class EditIssueSaving extends EditIssueState {
  final EditIssueLoaded form;

  const EditIssueSaving(this.form);

  @override
  List<Object?> get props => [form];
}

class EditIssueSuccess extends EditIssueState {
  final IssueEntity issue;

  const EditIssueSuccess(this.issue);

  @override
  List<Object?> get props => [issue];
}

class EditIssueError extends EditIssueState {
  final String message;
  final EditIssueLoaded? previousForm;

  const EditIssueError(this.message, {this.previousForm});

  @override
  List<Object?> get props => [message, previousForm];
}
