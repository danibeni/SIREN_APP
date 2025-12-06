import 'package:equatable/equatable.dart';
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

  const IssueDetailLoaded(this.issue);

  @override
  List<Object?> get props => [issue];
}

class IssueDetailError extends IssueDetailState {
  final String message;

  const IssueDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
