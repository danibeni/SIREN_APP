import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/repositories/work_package_type_repository.dart';

/// Use case for retrieving current Work Package Type.
@lazySingleton
class GetWorkPackageTypeUseCase {
  final WorkPackageTypeRepository _repository;

  GetWorkPackageTypeUseCase(this._repository);

  Future<Either<Failure, String>> call() {
    return _repository.getSelectedType();
  }
}
