import 'package:dartz/dartz.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/status_entity.dart';
import 'package:siren_app/features/issues/domain/entities/work_package_type_entity.dart';

/// Repository for Work Package Type configuration and statuses.
abstract class WorkPackageTypeRepository {
  Future<Either<Failure, List<WorkPackageTypeEntity>>> getAvailableTypes();

  Future<Either<Failure, String>> getSelectedType();

  Future<Either<Failure, void>> setSelectedType(String typeName);

  Future<Either<Failure, List<StatusEntity>>> getStatusesForSelectedType();
}
