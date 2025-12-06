import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';

@lazySingleton
class GetIssueByIdUseCase {
  final IssueRepository repository;

  GetIssueByIdUseCase(this.repository);

  Future<Either<Failure, IssueEntity>> call(int id) async {
    return await repository.getIssueById(id);
  }
}
