import 'package:equatable/equatable.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

abstract class IssuesListState extends Equatable {
  const IssuesListState();

  @override
  List<Object?> get props => [];
}

class IssuesListInitial extends IssuesListState {
  const IssuesListInitial();
}

class IssuesListLoading extends IssuesListState {
  const IssuesListLoading();
}

class IssuesListLoaded extends IssuesListState {
  final List<IssueEntity> issues;

  const IssuesListLoaded(this.issues);

  @override
  List<Object?> get props => [issues];
}

class IssuesListRefreshing extends IssuesListState {
  final List<IssueEntity> issues;

  const IssuesListRefreshing(this.issues);

  @override
  List<Object?> get props => [issues];
}

class IssuesListError extends IssuesListState {
  final String message;

  const IssuesListError(this.message);

  @override
  List<Object?> get props => [message];
}
