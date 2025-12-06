import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/repositories/work_package_type_repository.dart';

/// Use case for storing the selected Work Package Type.
@lazySingleton
class SetWorkPackageTypeUseCase {
  final WorkPackageTypeRepository _repository;

  SetWorkPackageTypeUseCase(this._repository);

  Future<Either<Failure, void>> call(String typeName) {
    return _repository.setSelectedType(typeName);
  }
}
