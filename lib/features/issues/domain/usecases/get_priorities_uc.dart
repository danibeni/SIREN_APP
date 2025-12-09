import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/priority_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';

/// Use case for retrieving all available priorities from OpenProject.
@lazySingleton
class GetPrioritiesUseCase {
  final IssueRepository _repository;

  GetPrioritiesUseCase(this._repository);

  Future<Either<Failure, List<PriorityEntity>>> call() {
    return _repository.getPriorities();
  }
}
