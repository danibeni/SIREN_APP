import 'package:equatable/equatable.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

/// Base state for CreateIssueCubit
abstract class CreateIssueState extends Equatable {
  const CreateIssueState();

  @override
  List<Object?> get props => [];
}

/// Initial state before form is loaded
class CreateIssueInitial extends CreateIssueState {
  const CreateIssueInitial();
}

/// Loading state while fetching form data (groups, projects, etc.)
class CreateIssueLoading extends CreateIssueState {
  const CreateIssueLoading();
}

/// Form is ready with loaded data
class CreateIssueFormReady extends CreateIssueState {
  /// Available groups for selection
  final List<GroupItem> groups;

  /// Available projects (equipment) for selected group
  final List<ProjectItem> projects;

  /// Currently selected group ID
  final int? selectedGroupId;

  /// Currently selected project (equipment) ID
  final int? selectedProjectId;

  /// Currently selected priority level
  final PriorityLevel? selectedPriority;

  /// Current subject value
  final String subject;

  /// Current description value
  final String? description;

  /// Validation error messages (field name -> error message)
  final Map<String, String> validationErrors;

  const CreateIssueFormReady({
    required this.groups,
    this.projects = const [],
    this.selectedGroupId,
    this.selectedProjectId,
    this.selectedPriority,
    this.subject = '',
    this.description,
    this.validationErrors = const {},
  });

  /// Check if form has all required fields filled
  bool get isFormValid =>
      subject.trim().isNotEmpty &&
      selectedGroupId != null &&
      selectedProjectId != null &&
      selectedPriority != null;

  /// Create copy with updated fields
  CreateIssueFormReady copyWith({
    List<GroupItem>? groups,
    List<ProjectItem>? projects,
    int? selectedGroupId,
    int? selectedProjectId,
    PriorityLevel? selectedPriority,
    String? subject,
    String? description,
    Map<String, String>? validationErrors,
    bool clearSelectedProject = false,
  }) {
    return CreateIssueFormReady(
      groups: groups ?? this.groups,
      projects: projects ?? this.projects,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
      selectedProjectId: clearSelectedProject
          ? null
          : (selectedProjectId ?? this.selectedProjectId),
      selectedPriority: selectedPriority ?? this.selectedPriority,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  @override
  List<Object?> get props => [
    groups,
    projects,
    selectedGroupId,
    selectedProjectId,
    selectedPriority,
    subject,
    description,
    validationErrors,
  ];
}

/// Form is being submitted
class CreateIssueSubmitting extends CreateIssueState {
  const CreateIssueSubmitting();
}

/// Issue created successfully
class CreateIssueSuccess extends CreateIssueState {
  /// The created issue
  final IssueEntity issue;

  const CreateIssueSuccess(this.issue);

  @override
  List<Object?> get props => [issue];
}

/// Error state
class CreateIssueError extends CreateIssueState {
  /// Error message to display
  final String message;

  /// Previous form state to preserve user input
  final CreateIssueFormReady? previousFormState;

  const CreateIssueError(this.message, {this.previousFormState});

  @override
  List<Object?> get props => [message, previousFormState];
}

/// Loading projects for selected group
class CreateIssueLoadingProjects extends CreateIssueState {
  /// Current form state while loading projects
  final CreateIssueFormReady formState;

  const CreateIssueLoadingProjects(this.formState);

  @override
  List<Object?> get props => [formState];
}

// --- Helper models for UI display ---

/// Represents a group item for dropdown display
class GroupItem extends Equatable {
  final int id;
  final String name;

  const GroupItem({required this.id, required this.name});

  @override
  List<Object> get props => [id, name];
}

/// Represents a project/equipment item for dropdown display
class ProjectItem extends Equatable {
  final int id;
  final String name;

  const ProjectItem({required this.id, required this.name});

  @override
  List<Object> get props => [id, name];
}
