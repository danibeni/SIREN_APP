import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/work_package_type_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/work_package_type_repository.dart';

/// Use case for retrieving available Work Package Types.
@lazySingleton
class GetAvailableTypesUseCase {
  final WorkPackageTypeRepository _repository;

  GetAvailableTypesUseCase(this._repository);

  Future<Either<Failure, List<WorkPackageTypeEntity>>> call() {
    return _repository.getAvailableTypes();
  }
}
