import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:siren_app/core/i18n/localization_service.dart';
import 'package:siren_app/core/i18n/usecases/get_language_usecase.dart';
import 'package:siren_app/core/i18n/usecases/set_language_usecase.dart';
import 'package:siren_app/features/config/presentation/cubit/localization_state.dart';

@lazySingleton
class LocalizationCubit extends Cubit<LocalizationState> {
  LocalizationCubit(
    this._getLanguage,
    this._setLanguage,
    this._service,
  ) : super(
          LocalizationState(
            locale: _service.fallbackLocale,
            status: LocalizationStatus.loading,
          ),
        );

  final GetLanguageUseCase _getLanguage;
  final SetLanguageUseCase _setLanguage;
  final LocalizationService _service;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: LocalizationStatus.loading,
        errorMessage: null,
      ),
    );

    final result = await _getLanguage();

    result.fold(
      (failure) => emit(
        state.copyWith(
          locale: _service.currentLocale,
          status: LocalizationStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (locale) => emit(
        state.copyWith(
          locale: locale,
          status: LocalizationStatus.ready,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> changeLanguage(String languageCode) async {
    emit(
      state.copyWith(
        status: LocalizationStatus.loading,
        errorMessage: null,
      ),
    );

    final result = await _setLanguage(
      _service.supportedLocales.firstWhere(
        (locale) => locale.languageCode == languageCode,
        orElse: () => _service.fallbackLocale,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: LocalizationStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (locale) => emit(
        state.copyWith(
          locale: locale,
          status: LocalizationStatus.ready,
          errorMessage: null,
        ),
      ),
    );
  }
}

