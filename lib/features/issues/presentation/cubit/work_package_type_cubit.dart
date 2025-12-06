import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/features/issues/domain/entities/status_entity.dart';
import 'package:siren_app/features/issues/domain/entities/work_package_type_entity.dart';
import 'package:siren_app/features/issues/domain/usecases/get_available_types_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/get_statuses_for_type_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/get_work_package_type_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/set_work_package_type_uc.dart';
import 'work_package_type_state.dart';

@lazySingleton
class WorkPackageTypeCubit extends Cubit<WorkPackageTypeState> {
  WorkPackageTypeCubit(
    this._getAvailableTypes,
    this._getWorkPackageType,
    this._setWorkPackageType,
    this._getStatusesForType,
  ) : super(const WorkPackageTypeInitial());

  final GetAvailableTypesUseCase _getAvailableTypes;
  final GetWorkPackageTypeUseCase _getWorkPackageType;
  final SetWorkPackageTypeUseCase _setWorkPackageType;
  final GetStatusesForTypeUseCase _getStatusesForType;

  Future<void> load() async {
    emit(const WorkPackageTypeLoading());

    final typeResult = await _getWorkPackageType();
    final availableResult = await _getAvailableTypes();
    final statusesResult = await _getStatusesForType();

    final type = typeResult.fold<String?>((_) => null, (value) => value);
    final types = availableResult.fold(
      (_) => <WorkPackageTypeEntity>[],
      (value) => value,
    );
    final statuses = statusesResult.fold(
      (_) => <StatusEntity>[],
      (value) => value,
    );

    if (type == null) {
      emit(const WorkPackageTypeError('Unable to load type selection'));
      return;
    }

    emit(
      WorkPackageTypeLoaded(
        selectedType: type,
        availableTypes: types,
        statuses: statuses,
      ),
    );
  }

  Future<void> selectType(String typeName) async {
    emit(const WorkPackageTypeSaving());

    final saveResult = await _setWorkPackageType(typeName);
    final statusResult = await _getStatusesForType();

    if (saveResult.isLeft()) {
      final message = saveResult.fold(
        (failure) => failure.message,
        (_) => 'Unknown error',
      );
      emit(WorkPackageTypeError(message));
      return;
    }

    if (statusResult.isLeft()) {
      final message = statusResult.fold(
        (failure) => failure.message,
        (_) => 'Unknown error',
      );
      emit(WorkPackageTypeError(message));
      return;
    }

    await load();
  }
}
