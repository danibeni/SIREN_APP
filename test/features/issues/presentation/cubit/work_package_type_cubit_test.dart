import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/status_entity.dart';
import 'package:siren_app/features/issues/domain/entities/work_package_type_entity.dart';
import 'package:siren_app/features/issues/domain/usecases/get_available_types_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/get_statuses_for_type_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/get_work_package_type_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/set_work_package_type_uc.dart';
import 'package:siren_app/features/issues/presentation/cubit/work_package_type_cubit.dart';
import 'package:siren_app/features/issues/presentation/cubit/work_package_type_state.dart';

class _MockGetAvailableTypes extends Mock implements GetAvailableTypesUseCase {}

class _MockGetWorkPackageType extends Mock
    implements GetWorkPackageTypeUseCase {}

class _MockSetWorkPackageType extends Mock
    implements SetWorkPackageTypeUseCase {}

class _MockGetStatusesForType extends Mock
    implements GetStatusesForTypeUseCase {}

void main() {
  late WorkPackageTypeCubit cubit;
  late _MockGetAvailableTypes getAvailableTypes;
  late _MockGetWorkPackageType getWorkPackageType;
  late _MockSetWorkPackageType setWorkPackageType;
  late _MockGetStatusesForType getStatusesForType;

  setUp(() {
    getAvailableTypes = _MockGetAvailableTypes();
    getWorkPackageType = _MockGetWorkPackageType();
    setWorkPackageType = _MockSetWorkPackageType();
    getStatusesForType = _MockGetStatusesForType();

    cubit = WorkPackageTypeCubit(
      getAvailableTypes,
      getWorkPackageType,
      setWorkPackageType,
      getStatusesForType,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('load', () {
    test('emits loaded when data is available', () async {
      // Given
      when(
        () => getWorkPackageType(),
      ).thenAnswer((_) async => const Right('Issue'));
      when(() => getAvailableTypes()).thenAnswer(
        (_) async => Right([
          const WorkPackageTypeEntity(id: 1, name: 'Issue'),
          const WorkPackageTypeEntity(id: 2, name: 'Task'),
        ]),
      );
      when(() => getStatusesForType()).thenAnswer(
        (_) async => Right([
          const StatusEntity(
            id: 1,
            name: 'New',
            isDefault: true,
            isClosed: false,
            colorHex: '#123456',
          ),
        ]),
      );

      // Expect
      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<WorkPackageTypeLoading>(),
          isA<WorkPackageTypeLoaded>(),
        ]),
      );

      // When
      await cubit.load();
    });

    test('emits error when type cannot be read', () async {
      // Given
      when(
        () => getWorkPackageType(),
      ).thenAnswer((_) async => const Left(CacheFailure('fail')));
      when(() => getAvailableTypes()).thenAnswer((_) async => const Right([]));
      when(() => getStatusesForType()).thenAnswer(
        (_) async => Right([
          const StatusEntity(
            id: 1,
            name: 'New',
            isDefault: true,
            isClosed: false,
            colorHex: '#123456',
          ),
        ]),
      );

      // Expect
      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<WorkPackageTypeLoading>(),
          isA<WorkPackageTypeError>(),
        ]),
      );

      // When
      await cubit.load();
    });
  });

  group('selectType', () {
    test('stores type and refreshes statuses', () async {
      // Given
      when(
        () => setWorkPackageType(any()),
      ).thenAnswer((_) async => const Right(null));
      when(() => getStatusesForType()).thenAnswer(
        (_) async => Right([
          const StatusEntity(
            id: 1,
            name: 'New',
            isDefault: true,
            isClosed: false,
          ),
        ]),
      );
      when(
        () => getWorkPackageType(),
      ).thenAnswer((_) async => const Right('Issue'));
      when(() => getAvailableTypes()).thenAnswer((_) async => const Right([]));

      // Expect
      expectLater(cubit.stream, emitsThrough(isA<WorkPackageTypeLoaded>()));

      // When
      await cubit.selectType('Issue');

      // Then
      verify(() => setWorkPackageType('Issue')).called(1);
      verify(() => getStatusesForType()).called(2);
    });

    test('emits error when store fails', () async {
      // Given
      when(
        () => setWorkPackageType(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('fail')));
      when(
        () => getStatusesForType(),
      ).thenAnswer((_) async => Right<Failure, List<StatusEntity>>([]));

      // Expect
      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<WorkPackageTypeSaving>(),
          isA<WorkPackageTypeError>(),
        ]),
      );

      // When
      await cubit.selectType('Issue');
    });
  });
}
