import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum LocalizationStatus { loading, ready, error }

class LocalizationState extends Equatable {
  const LocalizationState({
    required this.locale,
    this.status = LocalizationStatus.loading,
    this.errorMessage,
  });

  final Locale locale;
  final LocalizationStatus status;
  final String? errorMessage;

  LocalizationState copyWith({
    Locale? locale,
    LocalizationStatus? status,
    String? errorMessage,
  }) {
    return LocalizationState(
      locale: locale ?? this.locale,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [locale, status, errorMessage];
}

