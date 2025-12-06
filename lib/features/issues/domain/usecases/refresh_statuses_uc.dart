import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/status_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/work_package_type_repository.dart';

/// Use case for refreshing statuses from server (bypassing cache).
///
/// Used when refreshing the issue list to ensure status information is current.
@lazySingleton
class RefreshStatusesUseCase {
  final WorkPackageTypeRepository _repository;

  RefreshStatusesUseCase(this._repository);

  Future<Either<Failure, List<StatusEntity>>> call() {
    return _repository.refreshStatusesForSelectedType();
  }
}
