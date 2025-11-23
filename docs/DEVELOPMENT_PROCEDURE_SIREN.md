# SIREN Development Procedure

**Author:** Senior Mobile Software Engineer  
**Date:** November 2025  
**Based on:** PROJECT_CONTEXT.md

## Overview

This document provides a step-by-step procedure for developing the SIREN mobile application following Clean Architecture principles and Flutter best practices. Each step builds upon the previous one, ensuring a solid foundation before moving to the next layer.

---

## Phase 0: Project Initialization and Setup

### Step 0.1: Create Flutter Project

```bash
# Create new Flutter project
flutter create siren_app --org com.observatory.siren

# Navigate to project directory
cd siren_app

# Verify Flutter installation
flutter doctor
```

### Step 0.2: Configure Project Structure

Create the foundational folder structure based on Clean Architecture:

```bash
# Create core directories
mkdir -p lib/core/di
mkdir -p lib/core/error
mkdir -p lib/core/i18n

# Create feature structure
mkdir -p lib/features/issues/data/datasources
mkdir -p lib/features/issues/data/models
mkdir -p lib/features/issues/data/repositories
mkdir -p lib/features/issues/domain/entities
mkdir -p lib/features/issues/domain/repositories
mkdir -p lib/features/issues/domain/usecases
mkdir -p lib/features/issues/presentation/bloc
mkdir -p lib/features/issues/presentation/pages
mkdir -p lib/features/issues/presentation/widgets

# Create test structure (mirror source structure)
mkdir -p test/core/error
mkdir -p test/features/issues/data/datasources
mkdir -p test/features/issues/data/repositories
mkdir -p test/features/issues/domain/usecases
mkdir -p test/features/issues/presentation/bloc
mkdir -p test/features/issues/presentation/widgets
```

### Step 0.3: Add Dependencies

Update `pubspec.yaml` with required dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Dependency Injection
  get_it: ^7.6.4
  
  # HTTP Client
  dio: ^5.4.0
  
  # Error Handling
  dartz: ^0.10.1  # For Either pattern
  
  # Secure Storage
  flutter_secure_storage: ^9.0.0
  
  # Logging
  logger: ^2.0.2
  
  # Connectivity (Post-MVP)
  connectivity_plus: ^5.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  
  # Testing
  mockito: ^5.4.4
  bloc_test: ^9.1.5
  
  # Linting
  flutter_lints: ^3.0.1
```

Run:
```bash
flutter pub get
```

---

## Phase 1: Core Infrastructure Setup

### Step 1.1: Implement Base Error Handling

**File:** `lib/core/error/failures.dart`

```dart
import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Network connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message);
}

/// Cache/local storage failures
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
```

**Why:** Establishes a consistent error handling pattern across all layers. Domain layer defines failures, Data layer maps exceptions to failures, Presentation layer handles failures.

### Step 1.2: Configure Dependency Injection

**File:** `lib/core/di/di_container.dart`

```dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final getIt = GetIt.instance;

/// Initialize dependency injection container
Future<void> setupDependencyInjection() async {
  // External dependencies
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  
  // TODO: Register data sources, repositories, use cases, and blocs
  // This will be completed as we implement each layer
}
```

**Why:** Centralizes dependency management. Makes testing easier by allowing mock injection. Follows Dependency Inversion Principle.

### Step 1.3: Create API Configuration

**File:** `lib/core/config/api_config.dart`

```dart
class ApiConfig {
  // TODO: Move to environment variables
  static const String baseUrl = 'http://your-openproject-server/api/v3';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

---

## Phase 2: Domain Layer Implementation

**Critical Rule:** Domain layer must be pure Dart - NO Flutter dependencies.

### Step 2.1: Define Issue Entity

**File:** `lib/features/issues/domain/entities/issue_entity.dart`

```dart
import 'package:equatable/equatable.dart';

enum IssueStatus { new, inProgress, closed }
enum SeverityLevel { low, medium, high, critical }

class IssueEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final String group;
  final SeverityLevel severity;
  final IssueStatus status;
  final String creatorId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const IssueEntity({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.group,
    required this.severity,
    required this.status,
    required this.creatorId,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        location,
        group,
        severity,
        status,
        creatorId,
        createdAt,
        updatedAt,
      ];
}
```

**Why:** Pure business object representing the core concept. No framework dependencies, making it testable and reusable.

### Step 2.2: Define Repository Interface

**File:** `lib/features/issues/domain/repositories/issue_repository.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

abstract class IssueRepository {
  /// Get list of issues, optionally filtered
  Future<Either<Failure, List<IssueEntity>>> getIssues({
    List<IssueStatus>? statusFilter,
    String? locationFilter,
    SeverityLevel? severityFilter,
  });

  /// Create a new issue
  Future<Either<Failure, IssueEntity>> createIssue({
    required String title,
    String? description,
    String? location,
    required String group,
    required SeverityLevel severity,
  });

  /// Update an existing issue
  Future<Either<Failure, IssueEntity>> updateIssue({
    required String id,
    String? title,
    String? description,
    String? location,
    String? group,
    SeverityLevel? severity,
    IssueStatus? status,
  });
}
```

**Why:** Defines the contract that Data layer must implement. Domain depends on abstraction, not implementation (Dependency Inversion Principle).

### Step 2.3: Implement Use Cases

**File:** `lib/features/issues/domain/usecases/create_issue_uc.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';

class CreateIssueUseCase {
  final IssueRepository repository;

  CreateIssueUseCase(this.repository);

  Future<Either<Failure, IssueEntity>> call({
    required String title,
    String? description,
    String? location,
    required String group,
    required SeverityLevel severity,
  }) async {
    // Validate mandatory fields
    if (title.trim().isEmpty) {
      return const Left(ValidationFailure('Title is required'));
    }
    
    if (group.isEmpty) {
      return const Left(ValidationFailure('Group/Department is required'));
    }
    
    // Call repository
    return await repository.createIssue(
      title: title.trim(),
      description: description?.trim(),
      location: location?.trim(),
      group: group,
      severity: severity,
    );
  }
}
```

**File:** `lib/features/issues/domain/usecases/get_issues_uc.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';

class GetIssuesUseCase {
  final IssueRepository repository;

  GetIssuesUseCase(this.repository);

  Future<Either<Failure, List<IssueEntity>>> call({
    List<IssueStatus>? statusFilter,
    String? locationFilter,
    SeverityLevel? severityFilter,
  }) async {
    return await repository.getIssues(
      statusFilter: statusFilter,
      locationFilter: locationFilter,
      severityFilter: severityFilter,
    );
  }
}
```

**File:** `lib/features/issues/domain/usecases/update_issue_uc.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';

class UpdateIssueUseCase {
  final IssueRepository repository;

  UpdateIssueUseCase(this.repository);

  Future<Either<Failure, IssueEntity>> call({
    required String id,
    String? title,
    String? description,
    String? location,
    String? group,
    SeverityLevel? severity,
    IssueStatus? status,
  }) async {
    // Validate state transitions (prevent New ← In Progress/Closed)
    // This validation should be done here or in repository
    
    return await repository.updateIssue(
      id: id,
      title: title,
      description: description,
      location: location,
      group: group,
      severity: severity,
      status: status,
    );
  }
}
```

**Why:** Use cases encapsulate business logic. They validate inputs, enforce business rules, and coordinate with repositories. One use case per business operation.

---

## Phase 3: Data Layer Implementation

### Step 3.1: Create Data Model (DTO)

**File:** `lib/features/issues/data/models/issue_model.dart`

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

part 'issue_model.g.dart';

@JsonSerializable()
class IssueModel {
  final String id;
  final String subject; // OpenProject uses 'subject' for title
  final String? description;
  final Map<String, dynamic>? customFields;
  final String? location;
  final String status;
  final String priority;
  final String? assignedTo;
  final String author;
  final DateTime createdAt;
  final DateTime? updatedAt;

  IssueModel({
    required this.id,
    required this.subject,
    this.description,
    this.customFields,
    this.location,
    required this.status,
    required this.priority,
    this.assignedTo,
    required this.author,
    required this.createdAt,
    this.updatedAt,
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) =>
      _$IssueModelFromJson(json);

  Map<String, dynamic> toJson() => _$IssueModelToJson(this);

  /// Convert Model to Entity
  IssueEntity toEntity() {
    return IssueEntity(
      id: id,
      title: subject,
      description: description,
      location: location ?? customFields?['location'],
      group: customFields?['group'] ?? 'Unknown',
      severity: _mapPriorityToSeverity(priority),
      status: _mapStatusToEntityStatus(status),
      creatorId: author,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert Entity to Model (for creating/updating)
  factory IssueModel.fromEntity(IssueEntity entity) {
    return IssueModel(
      id: entity.id,
      subject: entity.title,
      description: entity.description,
      location: entity.location,
      customFields: {'group': entity.group},
      status: _mapEntityStatusToStatus(entity.status),
      priority: _mapSeverityToPriority(entity.severity),
      author: entity.creatorId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  // Helper methods for mapping
  static SeverityLevel _mapPriorityToSeverity(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return SeverityLevel.low;
      case 'normal':
        return SeverityLevel.medium;
      case 'high':
        return SeverityLevel.high;
      case 'critical':
        return SeverityLevel.critical;
      default:
        return SeverityLevel.medium;
    }
  }

  static String _mapSeverityToPriority(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.low:
        return 'low';
      case SeverityLevel.medium:
        return 'normal';
      case SeverityLevel.high:
        return 'high';
      case SeverityLevel.critical:
        return 'critical';
    }
  }

  static IssueStatus _mapStatusToEntityStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new':
      case 'new':
        return IssueStatus.new;
      case 'in progress':
      case 'open':
        return IssueStatus.inProgress;
      case 'closed':
      case 'resolved':
        return IssueStatus.closed;
      default:
        return IssueStatus.new;
    }
  }

  static String _mapEntityStatusToStatus(IssueStatus status) {
    switch (status) {
      case IssueStatus.new:
        return 'new';
      case IssueStatus.inProgress:
        return 'in progress';
      case IssueStatus.closed:
        return 'closed';
    }
  }
}
```

Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Why:** Models are DTOs that handle JSON serialization/deserialization. They convert between API format and Domain entities, keeping Domain layer pure.

### Step 3.2: Implement Remote Data Source

**File:** `lib/features/issues/data/datasources/issue_remote_datasource.dart`

```dart
import 'package:dio/dio.dart';
import 'package:siren_app/core/config/api_config.dart';
import 'package:siren_app/features/issues/data/models/issue_model.dart';

abstract class IssueRemoteDataSource {
  Future<List<IssueModel>> getIssues({
    List<String>? statusFilter,
    String? locationFilter,
    String? severityFilter,
  });
  
  Future<IssueModel> createIssue(IssueModel issue);
  Future<IssueModel> updateIssue(String id, IssueModel issue);
}

class IssueRemoteDataSourceImpl implements IssueRemoteDataSource {
  final Dio dio;
  final Future<String?> Function() getAuthToken;

  IssueRemoteDataSourceImpl({
    required this.dio,
    required this.getAuthToken,
  });

  @override
  Future<List<IssueModel>> getIssues({
    List<String>? statusFilter,
    String? locationFilter,
    String? severityFilter,
  }) async {
    try {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Build query parameters
      final queryParams = <String, dynamic>{};
      if (statusFilter != null && statusFilter.isNotEmpty) {
        queryParams['filters'] = _buildFilters(
          statusFilter: statusFilter,
          locationFilter: locationFilter,
          severityFilter: severityFilter,
        );
      }

      final response = await dio.get(
        '${ApiConfig.baseUrl}/work_packages',
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['_embedded']['elements'] ?? [];
        return data.map((json) => IssueModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load issues: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Network timeout');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('No internet connection');
      }
      throw Exception('Failed to load issues: ${e.message}');
    }
  }

  @override
  Future<IssueModel> createIssue(IssueModel issue) async {
    try {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await dio.post(
        '${ApiConfig.baseUrl}/work_packages',
        data: {
          'subject': issue.subject,
          'description': {'raw': issue.description ?? ''},
          'status': {'href': '/api/v3/statuses/${issue.status}'},
          'priority': {'href': '/api/v3/priorities/${issue.priority}'},
          'customFields': issue.customFields,
          '_links': {
            'type': {'href': '/api/v3/types/1'}, // Adjust type ID as needed
          },
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        return IssueModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create issue: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to create issue: ${e.message}');
    }
  }

  @override
  Future<IssueModel> updateIssue(String id, IssueModel issue) async {
    try {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await dio.patch(
        '${ApiConfig.baseUrl}/work_packages/$id',
        data: {
          'subject': issue.subject,
          'description': {'raw': issue.description ?? ''},
          'status': {'href': '/api/v3/statuses/${issue.status}'},
          'priority': {'href': '/api/v3/priorities/${issue.priority}'},
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return IssueModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update issue: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Failed to update issue: ${e.message}');
    }
  }

  Map<String, dynamic> _buildFilters({
    List<String>? statusFilter,
    String? locationFilter,
    String? severityFilter,
  }) {
    final filters = <String, dynamic>[];
    
    if (statusFilter != null && statusFilter.isNotEmpty) {
      filters.add({
        'status': {
          'operator': '=',
          'values': statusFilter,
        },
      });
    }
    
    // Add other filters as needed
    
    return {'filters': filters};
  }
}
```

**Why:** Data source handles direct API communication. Separates HTTP concerns from business logic. Can be easily mocked for testing.

### Step 3.3: Implement Repository

**File:** `lib/features/issues/data/repositories/issue_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import 'package:siren_app/features/issues/data/datasources/issue_remote_datasource.dart';
import 'package:siren_app/features/issues/data/models/issue_model.dart';

class IssueRepositoryImpl implements IssueRepository {
  final IssueRemoteDataSource remoteDataSource;

  IssueRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<IssueEntity>>> getIssues({
    List<IssueStatus>? statusFilter,
    String? locationFilter,
    SeverityLevel? severityFilter,
  }) async {
    try {
      // Convert domain filters to API format
      final statusFilterStrings = statusFilter
          ?.map((s) => _entityStatusToApiStatus(s))
          .toList();
      
      final severityFilterString = severityFilter != null
          ? _severityToApiPriority(severityFilter)
          : null;

      final models = await remoteDataSource.getIssues(
        statusFilter: statusFilterStrings,
        locationFilter: locationFilter,
        severityFilter: severityFilterString,
      );

      // Convert models to entities
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, IssueEntity>> createIssue({
    required String title,
    String? description,
    String? location,
    required String group,
    required SeverityLevel severity,
  }) async {
    try {
      // Create model from domain data
      final model = IssueModel(
        id: '', // Will be assigned by API
        subject: title,
        description: description,
        location: location,
        customFields: {'group': group},
        status: 'new', // Initial status
        priority: _severityToApiPriority(severity),
        author: '', // Will be set by API based on auth token
        createdAt: DateTime.now(),
      );

      final createdModel = await remoteDataSource.createIssue(model);
      return Right(createdModel.toEntity());
    } catch (e) {
      if (e.toString().contains('timeout') || 
          e.toString().contains('connection')) {
        return Left(NetworkFailure(e.toString()));
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, IssueEntity>> updateIssue({
    required String id,
    String? title,
    String? description,
    String? location,
    String? group,
    SeverityLevel? severity,
    IssueStatus? status,
  }) async {
    try {
      // First, get current issue to merge changes
      final currentIssues = await remoteDataSource.getIssues();
      final currentModel = currentIssues.firstWhere(
        (model) => model.id == id,
        orElse: () => throw Exception('Issue not found'),
      );

      // Create updated model
      final updatedModel = IssueModel(
        id: id,
        subject: title ?? currentModel.subject,
        description: description ?? currentModel.description,
        location: location ?? currentModel.location,
        customFields: group != null 
            ? {'group': group} 
            : currentModel.customFields,
        status: status != null 
            ? _entityStatusToApiStatus(status) 
            : currentModel.status,
        priority: severity != null 
            ? _severityToApiPriority(severity) 
            : currentModel.priority,
        author: currentModel.author,
        createdAt: currentModel.createdAt,
        updatedAt: DateTime.now(),
      );

      final result = await remoteDataSource.updateIssue(id, updatedModel);
      return Right(result.toEntity());
    } catch (e) {
      if (e.toString().contains('timeout') || 
          e.toString().contains('connection')) {
        return Left(NetworkFailure(e.toString()));
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  // Helper methods for status/priority conversion
  String _entityStatusToApiStatus(IssueStatus status) {
    switch (status) {
      case IssueStatus.new:
        return 'new';
      case IssueStatus.inProgress:
        return 'in progress';
      case IssueStatus.closed:
        return 'closed';
    }
  }

  String _severityToApiPriority(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.low:
        return 'low';
      case SeverityLevel.medium:
        return 'normal';
      case SeverityLevel.high:
        return 'high';
      case SeverityLevel.critical:
        return 'critical';
    }
  }
}
```

**Why:** Repository implementation bridges Domain and Data layers. Converts exceptions to failures, maps models to entities. Implements the Domain interface contract.

---

## Phase 4: Presentation Layer Implementation

### Step 4.1: Implement State Management (Bloc)

**File:** `lib/features/issues/presentation/bloc/issue_list_bloc.dart`

```dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/usecases/get_issues_uc.dart';
import 'package:siren_app/core/error/failures.dart';

part 'issue_list_event.dart';
part 'issue_list_state.dart';

class IssueListBloc extends Bloc<IssueListEvent, IssueListState> {
  final GetIssuesUseCase getIssuesUseCase;

  IssueListBloc({required this.getIssuesUseCase})
      : super(IssueListInitial()) {
    on<LoadIssues>(_onLoadIssues);
    on<FilterIssues>(_onFilterIssues);
  }

  Future<void> _onLoadIssues(
    LoadIssues event,
    Emitter<IssueListState> emit,
  ) async {
    emit(IssueListLoading());
    
    final result = await getIssuesUseCase();
    
    result.fold(
      (failure) => emit(IssueListError(_mapFailureToMessage(failure))),
      (issues) => emit(IssueListLoaded(issues)),
    );
  }

  Future<void> _onFilterIssues(
    FilterIssues event,
    Emitter<IssueListState> emit,
  ) async {
    emit(IssueListLoading());
    
    final result = await getIssuesUseCase(
      statusFilter: event.statusFilter,
      locationFilter: event.locationFilter,
      severityFilter: event.severityFilter,
    );
    
    result.fold(
      (failure) => emit(IssueListError(_mapFailureToMessage(failure))),
      (issues) => emit(IssueListLoaded(issues)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error. Please try again later.';
      case NetworkFailure:
        return 'No internet connection. Please check your Wi-Fi.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}
```

**File:** `lib/features/issues/presentation/bloc/issue_list_event.dart`

```dart
import 'package:equatable/equatable.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

abstract class IssueListEvent extends Equatable {
  const IssueListEvent();

  @override
  List<Object> get props => [];
}

class LoadIssues extends IssueListEvent {
  const LoadIssues();
}

class FilterIssues extends IssueListEvent {
  final List<IssueStatus>? statusFilter;
  final String? locationFilter;
  final SeverityLevel? severityFilter;

  const FilterIssues({
    this.statusFilter,
    this.locationFilter,
    this.severityFilter,
  });

  @override
  List<Object?> get props => [statusFilter, locationFilter, severityFilter];
}
```

**File:** `lib/features/issues/presentation/bloc/issue_list_state.dart`

```dart
import 'package:equatable/equatable.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

abstract class IssueListState extends Equatable {
  const IssueListState();

  @override
  List<Object> get props => [];
}

class IssueListInitial extends IssueListState {}

class IssueListLoading extends IssueListState {}

class IssueListLoaded extends IssueListState {
  final List<IssueEntity> issues;

  const IssueListLoaded(this.issues);

  @override
  List<Object> get props => [issues];
}

class IssueListError extends IssueListState {
  final String message;

  const IssueListError(this.message);

  @override
  List<Object> get props => [message];
}
```

**Why:** Bloc pattern separates UI from business logic. States are immutable, events trigger state changes. Easy to test and reason about.

### Step 4.2: Create UI Pages

**File:** `lib/features/issues/presentation/pages/issue_list_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siren_app/features/issues/presentation/bloc/issue_list_bloc.dart';
import 'package:siren_app/features/issues/presentation/widgets/issue_card.dart';

class IssueListPage extends StatelessWidget {
  const IssueListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter dialog
            },
          ),
        ],
      ),
      body: BlocBuilder<IssueListBloc, IssueListState>(
        builder: (context, state) {
          if (state is IssueListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is IssueListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  ElevatedButton(
                    onPressed: () {
                      context.read<IssueListBloc>().add(const LoadIssues());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (state is IssueListLoaded) {
            if (state.issues.isEmpty) {
              return const Center(child: Text('No issues found'));
            }
            
            return ListView.builder(
              itemCount: state.issues.length,
              itemBuilder: (context, index) {
                return IssueCard(issue: state.issues[index]);
              },
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create issue page
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

**File:** `lib/features/issues/presentation/pages/issue_form_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/presentation/bloc/issue_form_bloc.dart';

class IssueFormPage extends StatefulWidget {
  final IssueEntity? issue; // If provided, edit mode

  const IssueFormPage({super.key, this.issue});

  @override
  State<IssueFormPage> createState() => _IssueFormPageState();
}

class _IssueFormPageState extends State<IssueFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  String? _selectedGroup;
  SeverityLevel? _selectedSeverity;

  @override
  void initState() {
    super.initState();
    if (widget.issue != null) {
      _titleController.text = widget.issue!.title;
      _descriptionController.text = widget.issue!.description ?? '';
      _locationController.text = widget.issue!.location ?? '';
      _selectedGroup = widget.issue!.group;
      _selectedSeverity = widget.issue!.severity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.issue == null ? 'Create Issue' : 'Edit Issue'),
      ),
      body: BlocListener<IssueFormBloc, IssueFormState>(
        listener: (context, state) {
          if (state is IssueFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Issue saved successfully')),
            );
            Navigator.of(context).pop(true);
          } else if (state is IssueFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              // Group dropdown
              DropdownButtonFormField<String>(
                value: _selectedGroup,
                decoration: const InputDecoration(
                  labelText: 'Group/Department *',
                  border: OutlineInputBorder(),
                ),
                items: ['IT', 'Engineering', 'Operations'].map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Text(group),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGroup = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Group is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Severity dropdown
              DropdownButtonFormField<SeverityLevel>(
                value: _selectedSeverity,
                decoration: const InputDecoration(
                  labelText: 'Severity Level *',
                  border: OutlineInputBorder(),
                ),
                items: SeverityLevel.values.map((severity) {
                  return DropdownMenuItem(
                    value: severity,
                    child: Text(severity.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSeverity = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Severity is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              BlocBuilder<IssueFormBloc, IssueFormState>(
                builder: (context, state) {
                  final isLoading = state is IssueFormLoading;
                  
                  return ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Save'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedGroup == null || _selectedSeverity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }

      context.read<IssueFormBloc>().add(
            CreateIssueEvent(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              location: _locationController.text.trim(),
              group: _selectedGroup!,
              severity: _selectedSeverity!,
            ),
          );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
```

### Step 4.3: Create Widgets

**File:** `lib/features/issues/presentation/widgets/issue_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

class IssueCard extends StatelessWidget {
  final IssueEntity issue;

  const IssueCard({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(issue.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (issue.description != null)
              Text(
                issue.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(issue.status.name.toUpperCase()),
                  labelStyle: const TextStyle(fontSize: 10),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(issue.severity.name.toUpperCase()),
                  labelStyle: const TextStyle(fontSize: 10),
                  backgroundColor: _getSeverityColor(issue.severity),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Navigate to issue detail page
        },
      ),
    );
  }

  Color _getSeverityColor(SeverityLevel severity) {
    switch (severity) {
      case SeverityLevel.low:
        return Colors.green.shade100;
      case SeverityLevel.medium:
        return Colors.yellow.shade100;
      case SeverityLevel.high:
        return Colors.orange.shade100;
      case SeverityLevel.critical:
        return Colors.red.shade100;
    }
  }
}
```

---

## Phase 5: Dependency Injection Setup

### Step 5.1: Complete DI Container

Update `lib/core/di/di_container.dart`:

```dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:siren_app/core/config/api_config.dart';
import 'package:siren_app/features/issues/data/datasources/issue_remote_datasource.dart';
import 'package:siren_app/features/issues/data/repositories/issue_repository_impl.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import 'package:siren_app/features/issues/domain/usecases/create_issue_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/get_issues_uc.dart';
import 'package:siren_app/features/issues/domain/usecases/update_issue_uc.dart';
import 'package:siren_app/features/issues/presentation/bloc/issue_list_bloc.dart';
import 'package:siren_app/features/issues/presentation/bloc/issue_form_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // External dependencies
  getIt.registerLazySingleton<Dio>(() => Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
        ),
      ));
  
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // Data Sources
  getIt.registerLazySingleton<IssueRemoteDataSource>(
    () => IssueRemoteDataSourceImpl(
      dio: getIt(),
      getAuthToken: () async {
        // TODO: Implement token retrieval from secure storage
        return await getIt<FlutterSecureStorage>().read(key: 'auth_token');
      },
    ),
  );

  // Repositories
  getIt.registerLazySingleton<IssueRepository>(
    () => IssueRepositoryImpl(
      getIt<IssueRemoteDataSource>(),
    ),
  );

  // Use Cases
  getIt.registerLazySingleton(() => GetIssuesUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateIssueUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateIssueUseCase(getIt()));

  // Blocs (Factory because each page needs a new instance)
  getIt.registerFactory(() => IssueListBloc(
        getIssuesUseCase: getIt(),
      ));
  getIt.registerFactory(() => IssueFormBloc(
        createIssueUseCase: getIt(),
      ));
}
```

---

## Phase 6: Main Application Setup

### Step 6.1: Update main.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siren_app/core/di/di_container.dart';
import 'package:siren_app/features/issues/presentation/pages/issue_list_page.dart';
import 'package:siren_app/features/issues/presentation/bloc/issue_list_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await setupDependencyInjection();
  
  runApp(const SirenApp());
}

class SirenApp extends StatelessWidget {
  const SirenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIREN',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => getIt<IssueListBloc>()
          ..add(const LoadIssues()),
        child: const IssueListPage(),
      ),
    );
  }
}
```

---

## Phase 7: Testing

### Step 7.1: Unit Test Example - Use Case

**File:** `test/features/issues/domain/usecases/create_issue_uc_test.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import 'package:siren_app/features/issues/domain/usecases/create_issue_uc.dart';

class MockIssueRepository extends Mock implements IssueRepository {}

void main() {
  late CreateIssueUseCase useCase;
  late MockIssueRepository mockRepository;

  setUp(() {
    mockRepository = MockIssueRepository();
    useCase = CreateIssueUseCase(mockRepository);
  });

  test('should create issue when valid data is provided', () async {
    // Arrange
    final issue = IssueEntity(
      id: '1',
      title: 'Test Issue',
      group: 'IT',
      severity: SeverityLevel.high,
      status: IssueStatus.new,
      creatorId: 'user1',
      createdAt: DateTime.now(),
    );

    when(mockRepository.createIssue(
      title: anyNamed('title'),
      description: anyNamed('description'),
      location: anyNamed('location'),
      group: anyNamed('group'),
      severity: anyNamed('severity'),
    )).thenAnswer((_) async => Right(issue));

    // Act
    final result = await useCase(
      title: 'Test Issue',
      group: 'IT',
      severity: SeverityLevel.high,
    );

    // Assert
    expect(result, Right(issue));
    verify(mockRepository.createIssue(
      title: 'Test Issue',
      description: null,
      location: null,
      group: 'IT',
      severity: SeverityLevel.high,
    )).called(1);
  });

  test('should return ValidationFailure when title is empty', () async {
    // Act
    final result = await useCase(
      title: '',
      group: 'IT',
      severity: SeverityLevel.high,
    );

    // Assert
    expect(result, isA<Left<Failure, IssueEntity>>());
    verifyNever(mockRepository.createIssue(
      title: anyNamed('title'),
      description: anyNamed('description'),
      location: anyNamed('location'),
      group: anyNamed('group'),
      severity: anyNamed('severity'),
    ));
  });
}
```

---

## Development Workflow Summary

1. **Start with Domain Layer** (Pure Dart, no Flutter)
   - Define entities
   - Define repository interfaces
   - Implement use cases

2. **Implement Data Layer**
   - Create models (DTOs)
   - Implement data sources
   - Implement repositories

3. **Build Presentation Layer**
   - Create Blocs/Cubits
   - Build UI widgets
   - Connect to use cases

4. **Wire Everything Together**
   - Configure dependency injection
   - Set up main.dart
   - Test integration

5. **Test Each Layer**
   - Unit tests for use cases
   - Unit tests for repositories
   - Widget tests for UI
   - Integration tests for flows

---

## Key Principles to Follow

1. **Dependency Rule:** Inner layers never depend on outer layers
2. **Single Responsibility:** Each class has one reason to change
3. **Testability:** Every component should be easily testable
4. **Immutability:** Prefer immutable objects (use Equatable)
5. **Error Handling:** Use Either pattern, never throw exceptions from use cases
6. **Code Quality:** Run `flutter analyze` and `flutter format` before committing

---

## Next Steps

1. Implement authentication flow
2. Add filtering UI
3. Implement attachment functionality
4. Add offline support (Post-MVP)
5. Add internationalization (Post-MVP)

---

## References

- Clean Architecture by Robert C. Martin
- Effective Dart: https://dart.dev/guides/language/effective-dart
- Flutter Bloc: https://bloclibrary.dev/
- Get It: https://pub.dev/packages/get_it

