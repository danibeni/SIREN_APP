# AGENTS.md

Essential information for coding agents working on the SIREN Mobile Application.

## Project Overview

**SIREN** (System for Issue Reporting and Engineering Notification) is a Flutter mobile application for unified management of technical issues affecting critical infrastructure at an astronomical observatory.

**Key Facts:**
- **Platform:** Mobile (iOS and Android)
- **Architecture:** Clean Architecture with SOLID principles
- **State Management:** Bloc/Cubit (flutter_bloc)
- **Backend:** OpenProject REST API v3 (local server)
- **DI:** get_it with modular injection modules

**Project Structure:**
```
/lib
├── /core          # Core infrastructure (DI, errors, auth, network, config)
├── /features      # Feature modules (issues, future features)
└── main.dart      # Application entry point
```

Each feature follows Clean Architecture: `domain/` → `data/` → `presentation/`

## Build and Test Commands

### Setup
```bash
# Install dependencies
flutter pub get

# Run code generation (if using build_runner)
flutter pub run build_runner build --delete-conflicting-outputs

# Verify Flutter installation
flutter doctor
```

### Development
```bash
# Run app with hot reload
flutter run

# Run on specific device
flutter run -d <device_id>

# Build APK (Android)
flutter build apk

# Build iOS (requires macOS)
flutter build ios
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/issues/domain/usecases/create_issue_uc_test.dart

# Watch mode (auto-run on changes)
flutter test --watch
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format .

# Check for unused dependencies
flutter pub outdated
```

## Code Style Guidelines

**All code style conventions are documented in `context/CONVENTIONS.md`**

Key points:
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Maximum line length: 80 characters
- Use `dart format` before committing
- All comments must be in English
- Files: snake_case, Classes: PascalCase, Variables: camelCase

See `context/CONVENTIONS.md` for complete guidelines on naming, patterns, error handling, state management, and testing conventions.

## Testing Instructions

### Test Structure
- Mirror source structure in `/test` directory
- Unit tests for use cases, repositories, and data sources
- Widget tests for presentation components
- Integration tests for complete flows

### Test Naming
- Test files: `*_test.dart`
- Test groups: `group('Description', () { ... })`
- Test cases: `test('should do something when condition', () { ... })`

### Test Structure Convention: Given-When-Then

We adopt the **Given–When–Then** convention to structure tests, instead of Arrange–Act–Assert. This style improves clarity and readability of test scenarios.

- **Given**: Establishes the initial context, configures objects and state necessary for the test
- **When**: Describes the action or event being tested
- **Then**: Verifies the expected results of the action

**Example:**
```dart
test('should return IssueEntity when repository call is successful', () async {
  // Given
  final params = CreateIssueParams(subject: 'Test Issue');
  final expectedEntity = IssueEntity(id: '1', subject: 'Test Issue');
  when(mockRepository.createIssue(params))
      .thenAnswer((_) async => Result.success(expectedEntity));
  
  // When
  final result = await useCase(params);
  
  // Then
  expect(result.isSuccess, true);
  expect(result.value, expectedEntity);
  verify(mockRepository.createIssue(params)).called(1);
});
```

### Mocking
- Use `mockito` or `mocktail` for mocking dependencies
- Mock repository interfaces, not implementations
- Mock data sources for testing repositories

### Running Tests
```bash
flutter test                    # Run all tests
flutter test --coverage         # With coverage
flutter test --watch            # Watch mode
```

## Architecture Guidelines

### Clean Architecture Layers
1. **Domain** - Pure Dart, no Flutter dependencies (entities, use cases, repository interfaces)
2. **Data** - Repository implementations, data sources, DTOs/models
3. **Presentation** - UI widgets, pages, Bloc/Cubit state management

**Dependency Rule:** Inner layers must NOT depend on outer layers.

### Dependency Injection

Dependencies are organized in **modular injection modules** located in `/lib/core/di/modules/`:

- `core_module.dart` - Core services (logging, errors)
- `network_module.dart` - HTTP client, API configuration
- `storage_module.dart` - Secure storage, local database
- `auth_module.dart` - Authentication services
- `config_module.dart` - Configuration services
- `features/issues_module.dart` - Issues feature dependencies

**Registration Order** (in `di_container.dart`):
1. Core Module
2. Storage Module
3. Network Module
4. Config Module
5. Auth Module
6. Feature Modules (Data Sources → Repositories → Use Cases → Blocs)

**Adding a new feature:**
1. Create module in `/lib/core/di/modules/features/{feature}_module.dart`
2. Register in `di_container.dart` following dependency order

### Error Handling

**Centralized error management using `Result<Failure, T>` pattern.**

All business operations return `Result<Failure, T>` with two branches:
- **Success:** Contains the successful value
- **Failure:** Contains a typed failure object

**Key Rules:**
- **Never use null/exceptions for expected business errors** - All expected errors must be represented as `Failure` types
- **Never throw exceptions from use cases** - Use cases must return `Result<Failure, T>` instead
- **Exceptions are only for unexpected errors** - Use try-catch to convert unexpected exceptions to `Failure` objects
- **Failure types** are defined in `/lib/core/error/failures.dart` (e.g., `ServerFailure`, `NetworkFailure`, `ValidationFailure`)

**Example:**
```dart
// Use Case returns Result
Future<Result<Failure, IssueEntity>> createIssue(CreateIssueParams params) async {
  // Validation returns Failure if invalid
  if (params.subject.isEmpty) {
    return Result.failure(ValidationFailure('Subject is required'));
  }
  
  // Repository also returns Result
  return await repository.createIssue(params);
}

// Repository converts exceptions to Failures
Future<Result<Failure, IssueEntity>> createIssue(params) async {
  try {
    final model = await remoteDataSource.createIssue(params);
    return Result.success(model.toEntity());
  } on SocketException {
    return Result.failure(NetworkFailure('No internet connection'));
  } catch (e) {
    return Result.failure(ServerFailure('Unexpected error: ${e.toString()}'));
  }
}
```

### Feature Development Workflow

1. **Domain Layer:** Define entity → Define repository interface → Implement use case(s)
2. **Data Layer:** Create model (DTO) → Implement data source → Implement repository
3. **Presentation Layer:** Create Bloc/Cubit → Build UI widgets → Connect to use cases
4. **DI:** Create feature module and register dependencies

## Security Considerations

### Sensitive Data
- **Never** store credentials or tokens in plain text
- Use `flutter_secure_storage` for all sensitive data (API keys, tokens, server URLs)
- **Never** log sensitive information (use logging package, but sanitize output)
- **Never** expose sensitive data in error messages shown to users

### Authentication
- Authentication is modularly separated from core business logic
- API keys stored securely using `flutter_secure_storage`
- Server URL configuration stored securely and validated before storage

### Access Control
- Group-based access control enforced by OpenProject API
- Users only see issues from their authorized Groups/Departments
- All access control logic handled server-side via OpenProject API

### Network Security
- **MVP:** HTTP allowed for local OpenProject server integration
- **Post-MVP:** Implement HTTPS for all API calls
- **Post-MVP:** Validate SSL certificates
- **Post-MVP:** Implement certificate pinning for production

## Extra Instructions

### Commit Messages
- Use clear, descriptive commit messages
- Follow conventional commits format when applicable
- Reference issue numbers when applicable
- Keep commits focused on a single change

### Pull Request Guidelines
- All code must be reviewed before merging
- Run `flutter analyze` before submitting PR
- Ensure all tests pass
- Update documentation when adding new features
- Follow Clean Architecture principles strictly - no shortcuts

### Repository Management
- **GitHub CLI (`gh`) is the standard tool** for repository operations
- **CRITICAL:** Always request explicit user confirmation before executing ANY repository action (commit, push, create branch, create PR, etc.)
- Display proposed action with full details before execution
- Never execute repository actions automatically without user review

### Code Generation
- Use `build_runner` for code generation (freezed, json_serializable, mocks)
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after adding new code generation annotations
- Watch mode: `flutter pub run build_runner watch`

### Important Business Rules
- **Mandatory Fields:** Subject, Priority Level, Group, Equipment (enforced in use cases)
- **Status Transitions:** "Closed" → "In Progress" allowed, but "In Progress"/"Closed" → "New" blocked
- **Read-only Fields:** Group and Equipment are read-only when editing existing issues
- **Optimistic Locking:** Always capture `lockVersion` when reading issues for subsequent updates
- **HATEOAS:** OpenProject API uses HATEOAS - discover actions via `_links` in responses

### Domain Layer Rules
- **Keep domain layer pure:** No Flutter dependencies
- **Entities:** Pure Dart classes, immutable when possible
- **Use Cases:** Contain business logic and validation
- **Repositories:** Define interface in Domain, implement in Data layer

### Common Gotchas
- Always run `flutter analyze` before committing
- Domain layer must be framework-agnostic (pure Dart)
- Use `registerFactory` for Blocs (new instance per page), `registerLazySingleton` for services
- Never throw exceptions from use cases; return `Result<Failure, T>` instead
- Never use null/exceptions for expected business errors; use `Result<Failure, T>` pattern
- Preserve user input when validation fails (don't lose entered data)

## References

- **Code Conventions:** `context/CONVENTIONS.md`
- **OpenProject API:** `context/OPENPROJECT_API_V3_SIREN_INTEGRATION.md`
- **Specification:** `context/SDD/PHASE1_SPEC_SIREN_CON_GEMINI_GEM.md`
- **Technical Plan:** `context/SDD/PHASE2_PLAN_SIREN_CON_GEMINI_GEM.md`
- **Task List:** `context/SDD/PHASE3_TASKS_SIREN_CON_GEMINI_GEM.md`

