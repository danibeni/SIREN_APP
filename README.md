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
- **Secure Authentication**: Secure OAuth2 authentication with PKCE and token storage
- **Configurable Server**: Flexible server URL configuration for different environments

### Key Capabilities

- **Group-based Access Control**: Users only see issues from their authorized groups
- **Status Transitions**: Controlled workflow with business rule enforcement
- **Optimistic Locking**: Prevents concurrent modification conflicts
- **Input Validation**: Prevents saving incomplete issues while preserving user input
- **Audit Trail**: All modifications generate permanent audit records

## Backend Server: OpenProject OAuth2 Configuration

The SIREN mobile application requires an OpenProject server instance to function. Authentication is handled via **OAuth2 with PKCE**, not a static API key.

For a complete technical specification of the authentication flow, refer to the `context/OAUTH2_OPENPROJECT_SIREN.md` document.

### What is OAuth2 with PKCE?

**Authorization Code + PKCE** (Proof Key for Code Exchange) is a secure authorization flow designed for public clients like mobile applications, which cannot securely store a `client_secret`. It ensures that the client application that starts the login process is the same one that receives the `access_token`, preventing authorization code interception attacks.

### How to Configure OpenProject

An administrator must create an OAuth2 application within your OpenProject instance. Follow these steps:

1.  **Log in to OpenProject** with an administrator account.
2.  Navigate to **Administration** → **API and webhooks** → **OAuth applications**.
3.  Click on the **+ New application** button.
4.  Fill in the application details:
    *   **Name**: `SIREN Mobile App` (or another descriptive name).
    *   **Redirect URI**: This is the most critical step. You must enter the following custom URI exactly:
        ```
        siren://oauth/callback
        ```
        This is a "deep link" that redirects the user back to the SIREN application after they authorize the login on the OpenProject web page.
    *   **Confidential**: **No**. This must be set to "No" because a mobile app is a public client.
    *   **Scopes**: Set the scope to `api_v3`. This grants the application the necessary permissions to manage work packages (issues) via the REST API.
5.  Click **Save**.
6.  The next screen will display the **Client ID** and **Client Secret**. The SIREN application only needs the **Client ID**. Make a note of it for the app configuration.

After completing these steps, your OpenProject server is ready to handle authentication requests from the SIREN mobile application.

## Client Application Requirements

- **Flutter SDK**: Latest stable version
- **Dart**: 3.0 or higher

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

The only initial configuration required is to set the OpenProject server URL.

1.  **Launch the application**: On first launch, you will be prompted to enter the server URL.
2.  **Enter Server URL**: Input the base URL for your OpenProject instance (e.g., `https://openproject.example.com`).
3.  **Enter Client ID**: Input the Client ID obtained from your OpenProject OAuth2 application configuration. This ID is used by the app to identify itself to OpenProject.
4.  **Authenticate**: After setting the URL and Client ID, the app will initiate the OAuth2 authentication flow. Follow the on-screen instructions to log in and authorize the application.

This process is detailed in the **Backend Server: OpenProject OAuth2 Configuration** section above.

### Logout Behavior

The application includes a **Logout** feature accessible from the Settings page. Understanding its behavior is important:

#### What Logout Does

- **Clears local authentication tokens**: Removes the `access_token` and `refresh_token` stored on the device
- **Invalidates the app session**: You will need to authenticate again to use the app
- **Allows switching users**: Enables logging in with a different OpenProject account

#### Important Limitations

**Browser Credential Caching**: The OAuth2 authentication flow uses an in-app browser (Chrome Custom Tabs on Android, Safari View Controller on iOS) that may cache credentials. This means:

- If your browser has saved your OpenProject username and password, the next time you authenticate, you may be **automatically logged in** without re-entering credentials
- This is **expected OAuth2 behavior** and not a security issue with the SIREN application
- The logout function correctly clears all app-stored tokens from the device's secure storage

#### How to Fully Clear Browser Credentials

If you want to completely clear cached credentials and force manual login:

**Android:**
1. Go to your device's **Settings** → **Apps** → **Chrome**
2. Select **Storage** → **Clear Data** or **Clear Cache**

**iOS:**
1. Go to **Settings** → **Safari**
2. Tap **Clear History and Website Data**


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
- **Authentication**: OAuth2 Bearer Token (obtained via the OAuth2 + PKCE flow)
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
