import 'package:equatable/equatable.dart';
import 'package:siren_app/features/issues/domain/entities/status_entity.dart';
import 'package:siren_app/features/issues/domain/entities/work_package_type_entity.dart';

abstract class WorkPackageTypeState extends Equatable {
  const WorkPackageTypeState();

  @override
  List<Object?> get props => [];
}

class WorkPackageTypeInitial extends WorkPackageTypeState {
  const WorkPackageTypeInitial();
}

class WorkPackageTypeLoading extends WorkPackageTypeState {
  const WorkPackageTypeLoading();
}

class WorkPackageTypeLoaded extends WorkPackageTypeState {
  final String selectedType;
  final List<WorkPackageTypeEntity> availableTypes;
  final List<StatusEntity> statuses;

  const WorkPackageTypeLoaded({
    required this.selectedType,
    required this.availableTypes,
    required this.statuses,
  });

  @override
  List<Object?> get props => [selectedType, availableTypes, statuses];
}

class WorkPackageTypeSaving extends WorkPackageTypeState {
  const WorkPackageTypeSaving();
}

class WorkPackageTypeError extends WorkPackageTypeState {
  final String message;

  const WorkPackageTypeError(this.message);

  @override
  List<Object?> get props => [message];
}
