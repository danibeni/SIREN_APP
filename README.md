# SIREN

**System for Issue Reporting and Engineering Notification**

A Flutter mobile application for unified, formal management of technical issues affecting critical infrastructure and systems at an astronomical observatory.

## Overview

SIREN enables field technicians to quickly register, manage, and track technical issues directly from their mobile devices. The application integrates with OpenProject REST API to provide centralized issue management with group-based access control.

### Primary Goals

- **Reduce Mean Time to Resolution (MTTR)** by accelerating triage and response
- **Enable immediate in-situ issue reporting** by field technicians
- **Centralize fault communication** and documentation
- **Ensure operational security** through group-based access control

## Features

### Core Functionality (MVP)

- **Quick Issue Registration**: Register new technical issues with mandatory fields (Subject, Priority Level, Group, Equipment)
- **Issue Lifecycle Management**: View, update, and manage issues from authorized groups/departments
- **Smart Filtering**: Filter issues by Status, Equipment, Priority Level, and Group
- **Attachment Support**: Add photos and documents to issues
- **Secure Authentication**: OpenProject API key authentication with secure token storage
- **Configurable Server**: Flexible server URL configuration for different environments

### Key Capabilities

- **Group-based Access Control**: Users only see issues from their authorized groups
- **Status Transitions**: Controlled workflow with business rule enforcement
- **Optimistic Locking**: Prevents concurrent modification conflicts
- **Input Validation**: Prevents saving incomplete issues while preserving user input
- **Audit Trail**: All modifications generate permanent audit records

## Requirements

- **Flutter SDK**: Latest stable version
- **Dart**: 3.0 or higher
- **OpenProject Server**: Access to an OpenProject instance with REST API v3
- **API Key**: OpenProject API key for authentication

## Installation

### Prerequisites

1. Install Flutter following the [official guide](https://docs.flutter.dev/get-started/install)
2. Verify installation:
   ```bash
   flutter doctor
   ```

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/danibeni/SIREN_APP.git
   cd SIREN_APP
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run code generation (if needed):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. Run the application:
   ```bash
   flutter run
   ```

## Configuration

### Initial Setup

1. **Configure OpenProject Server URL**:
   - Open the app settings
   - Enter your OpenProject server URL (e.g., `https://openproject.example.com`)
   - The app automatically appends `/api/v3` to the base URL

2. **Add API Key**:
   - Generate an API key from your OpenProject account
   - Enter the API key in the app settings
   - The key is stored securely using `flutter_secure_storage`

### API Key Entry Features

- Full clipboard paste support
- Show/hide toggle for visibility verification
- Real-time format validation
- Mobile-optimized input fields

## Architecture

SIREN follows **Clean Architecture** principles with strict layer separation:

```
Presentation Layer (UI/State Management)
    ↓
Domain Layer (Business Logic/Entities/Use Cases)
    ↓
Data Layer (Repositories/Data Sources/Models)
```

### Key Principles

- **Domain Layer**: Pure Dart, framework-agnostic business logic
- **Dependency Injection**: Modular DI using `get_it` with feature-based modules
- **State Management**: Bloc/Cubit pattern with `flutter_bloc`
- **Separation of Concerns**: Clear boundaries between features and core services

### Project Structure

```
/lib
├── /core              # Core infrastructure (DI, errors, auth, network, config)
├── /features          # Feature modules (issues, future features)
│   └── /issues
│       ├── /data      # Data sources, models, repository implementations
│       ├── /domain    # Entities, repository interfaces, use cases
│       └── /presentation  # UI, Bloc/Cubit, pages, widgets
└── main.dart          # Application entry point
```

## Technical Stack

- **Framework**: Flutter / Dart
- **State Management**: Bloc/Cubit (`flutter_bloc`)
- **Dependency Injection**: `get_it` with modular injection modules
- **HTTP Client**: `dio` for API communication
- **Secure Storage**: `flutter_secure_storage` for credentials
- **Testing**: `flutter_test`, `mockito`/`mocktail` for mocking

## API Integration

### OpenProject REST API v3

- **Base URL**: Configurable server URL + `/api/v3`
- **Authentication**: OpenProject API Key (Basic Auth)
- **Content Format**: `application/hal+json` (HATEOAS)
- **Content-Type**: `application/json` for request bodies

### Key Endpoints

- `GET /api/v3/work_packages` - List issues with filters and pagination
- `GET /api/v3/work_packages/{id}` - Get single issue
- `POST /api/v3/work_packages` - Create new issue
- `PATCH /api/v3/work_packages/{id}` - Update issue
- `POST /api/v3/work_packages/{id}/attachments` - Add attachments

### HATEOAS Discovery

OpenProject API uses HATEOAS. The app discovers available actions and resources dynamically via `_links` in API responses.

## Issue Fields

| Field             | Required | Description                                    |
|-------------------|----------|------------------------------------------------|
| Subject           | Yes      | Free text issue title                          |
| Description       | No       | Optional detailed description                  |
| Equipment         | Yes      | OpenProject project (filtered by selected Group) |
| Group/Department  | Yes      | Single group selection (auto-selected if user belongs to one group) |
| Priority Level    | Yes      | Low, Normal, High, Immediate                   |
| Status            | No       | New, In Progress, Closed (auto-set to "New" on creation) |

## Development

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/features/issues/domain/usecases/create_issue_uc_test.dart
```

### Code Quality

```bash
# Analyze code
flutter analyze

# Format code
flutter format .
```

### Feature Development Workflow

1. **Domain Layer**: Define entity → Repository interface → Use cases
2. **Data Layer**: Create model (DTO) → Implement data source → Implement repository
3. **Presentation Layer**: Create Bloc/Cubit → Build UI widgets → Connect to use cases
4. **DI Registration**: Create feature module and register dependencies

## Future Roadmap

- **Offline Capability**: Local database integration for offline issue creation
- **Multi-language Support**: Spanish/English localization
- **AI Integration**: Automated categorization and predictive features
- **Voice Commands**: Hands-free issue registration for field technicians

## Contributing

1. Follow Clean Architecture principles strictly
2. Write tests for new use cases and critical business logic
3. Run `flutter analyze` before committing
4. Use GitHub CLI (`gh`) for repository operations

## Documentation

- **API Integration**: OpenProject REST API v3 documentation

## Success Criteria

- **Usability**: Users can register a new issue in less than one minute
- **Adoption**: 90% of new technical issues reported via SIREN in first month
- **Business Impact**: Reduced MTTR in critical systems

## License

[Add license information here]

## Author

**Daniel Benitez** - danibeni.dev@gmail.com
