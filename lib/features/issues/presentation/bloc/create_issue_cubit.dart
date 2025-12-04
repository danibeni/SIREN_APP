import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/issue_remote_datasource.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/usecases/create_issue_uc.dart';
import 'create_issue_state.dart';

/// Cubit for managing Create Issue form state
///
/// Handles:
/// - Loading groups and projects
/// - Auto-selecting group if user belongs to only one
/// - Loading projects when group is selected
/// - Form field updates
/// - Form validation and submission
@injectable
class CreateIssueCubit extends Cubit<CreateIssueState> {
  final CreateIssueUseCase _createIssueUseCase;
  final IssueRemoteDataSource _remoteDataSource;

  CreateIssueCubit(this._createIssueUseCase, this._remoteDataSource)
    : super(const CreateIssueInitial());

  /// Initialize form by loading groups
  Future<void> initializeForm() async {
    emit(const CreateIssueLoading());

    try {
      // Load groups
      final groupsResponse = await _remoteDataSource.getGroups();
      final groups = groupsResponse
          .map((g) => GroupItem(id: g['id'] as int, name: g['name'] as String))
          .toList();

      if (groups.isEmpty) {
        emit(const CreateIssueError('No groups available'));
        return;
      }

      // Auto-select group if user belongs to only one
      int? selectedGroupId;
      List<ProjectItem> projects = [];

      if (groups.length == 1) {
        selectedGroupId = groups.first.id;
        projects = await _loadProjectsForGroup(selectedGroupId);
      }

      emit(
        CreateIssueFormReady(
          groups: groups,
          projects: projects,
          selectedGroupId: selectedGroupId,
          selectedPriority: PriorityLevel.normal, // Default priority
        ),
      );
    } catch (e) {
      emit(CreateIssueError('Failed to load form data: ${e.toString()}'));
    }
  }

  /// Select a group and load its projects
  Future<void> selectGroup(int groupId) async {
    final currentState = state;
    if (currentState is! CreateIssueFormReady) return;

    // Emit loading state while preserving form data
    emit(
      CreateIssueLoadingProjects(
        currentState.copyWith(
          selectedGroupId: groupId,
          clearSelectedProject: true,
        ),
      ),
    );

    try {
      final projects = await _loadProjectsForGroup(groupId);

      emit(
        currentState.copyWith(
          selectedGroupId: groupId,
          projects: projects,
          clearSelectedProject: true,
        ),
      );
    } catch (e) {
      emit(
        CreateIssueError(
          'Failed to load equipment: ${e.toString()}',
          previousFormState: currentState,
        ),
      );
    }
  }

  /// Select a project (equipment)
  void selectProject(int projectId) {
    final currentState = state;
    if (currentState is! CreateIssueFormReady) return;

    emit(currentState.copyWith(selectedProjectId: projectId));
  }

  /// Select priority level
  void selectPriority(PriorityLevel priority) {
    final currentState = state;
    if (currentState is! CreateIssueFormReady) return;

    emit(currentState.copyWith(selectedPriority: priority));
  }

  /// Update subject field
  void updateSubject(String subject) {
    final currentState = state;
    if (currentState is! CreateIssueFormReady) return;

    // Clear subject validation error if user is typing
    final errors = Map<String, String>.from(currentState.validationErrors);
    errors.remove('subject');

    emit(currentState.copyWith(subject: subject, validationErrors: errors));
  }

  /// Update description field
  void updateDescription(String? description) {
    final currentState = state;
    if (currentState is! CreateIssueFormReady) return;

    emit(currentState.copyWith(description: description));
  }

  /// Submit the form
  Future<void> submitForm() async {
    final currentState = state;
    if (currentState is! CreateIssueFormReady) return;

    // CRITICAL: Validate form BEFORE any server call
    // This prevents unnecessary API calls and provides immediate feedback
    final errors = _validateForm(currentState);
    if (errors.isNotEmpty) {
      // Emit state with validation errors to show them in the UI
      emit(currentState.copyWith(validationErrors: errors));
      return; // Stop here - do not proceed to server call
    }

    // Double-check: Ensure subject is not empty after trim
    final trimmedSubject = currentState.subject.trim();
    if (trimmedSubject.isEmpty) {
      emit(
        currentState.copyWith(
          validationErrors: {'subject': 'Subject is required'},
        ),
      );
      return; // Stop here - do not proceed to server call
    }

    // All validations passed - proceed with submission
    emit(const CreateIssueSubmitting());

    final params = CreateIssueParams(
      subject: trimmedSubject,
      description: currentState.description,
      priorityLevel: currentState.selectedPriority,
      group: currentState.selectedGroupId,
      equipment: currentState.selectedProjectId,
    );

    final result = await _createIssueUseCase(params);

    result.fold(
      (failure) {
        String message = 'Failed to create issue';
        if (failure is ValidationFailure) {
          message = failure.message;
        } else if (failure is ServerFailure) {
          message = failure.message;
        } else if (failure is NetworkFailure) {
          message = 'Network error: ${failure.message}';
        }
        emit(CreateIssueError(message, previousFormState: currentState));
      },
      (issue) {
        emit(CreateIssueSuccess(issue));
      },
    );
  }

  /// Reset to form state after error (preserves user input)
  void resetToForm() {
    final currentState = state;
    if (currentState is CreateIssueError &&
        currentState.previousFormState != null) {
      emit(currentState.previousFormState!);
    }
  }

  // --- Private methods ---

  /// Load projects for a specific group
  Future<List<ProjectItem>> _loadProjectsForGroup(int groupId) async {
    final projectsResponse = await _remoteDataSource.getProjectsByGroup(
      groupId,
    );
    return projectsResponse
        .map((p) => ProjectItem(id: p['id'] as int, name: p['name'] as String))
        .toList();
  }

  /// Validate form fields
  ///
  /// This method performs client-side validation BEFORE submitting to the server.
  /// All mandatory fields are checked and errors are returned as a map.
  /// Returns empty map if all validations pass.
  Map<String, String> _validateForm(CreateIssueFormReady state) {
    final errors = <String, String>{};

    // Validate Subject: required, non-empty after trimming whitespace
    final trimmedSubject = state.subject.trim();
    if (trimmedSubject.isEmpty) {
      errors['subject'] = 'Subject is required';
    }

    // Validate Group: required
    if (state.selectedGroupId == null) {
      errors['group'] = 'Group is required';
    }

    // Validate Equipment: required
    if (state.selectedProjectId == null) {
      errors['equipment'] = 'Equipment is required';
    }

    // Validate Priority: required
    if (state.selectedPriority == null) {
      errors['priority'] = 'Priority is required';
    }

    return errors;
  }
}
