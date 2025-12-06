import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/status_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/work_package_type_repository.dart';

/// Use case for retrieving statuses for the configured Work Package Type.
@lazySingleton
class GetStatusesForTypeUseCase {
  final WorkPackageTypeRepository _repository;

  GetStatusesForTypeUseCase(this._repository);

  Future<Either<Failure, List<StatusEntity>>> call() {
    return _repository.getStatusesForSelectedType();
  }
}
