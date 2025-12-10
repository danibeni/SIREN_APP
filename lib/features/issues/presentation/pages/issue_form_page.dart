import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siren_app/core/di/injection.dart' as injection;
import 'package:siren_app/core/i18n/generated/app_localizations.dart';
import 'package:siren_app/core/theme/app_colors.dart';
import 'package:siren_app/core/widgets/gradient_app_bar.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import '../bloc/create_issue_cubit.dart';
import '../bloc/create_issue_state.dart';

/// Page for creating a new issue
///
/// Features:
/// - Material Design 3 components
/// - Soft blue/purple color scheme
/// - Responsive layout for smartphones
/// - Form validation with error messages
/// - Auto-selection of single group
/// - Equipment filtering by group
class IssueFormPage extends StatelessWidget {
  const IssueFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => injection.getIt<CreateIssueCubit>()..initializeForm(),
      child: const _IssueFormView(),
    );
  }
}

class _IssueFormView extends StatelessWidget {
  const _IssueFormView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: AppLocalizations.of(context)!.issueNewIssue,
      ),
      body: BlocConsumer<CreateIssueCubit, CreateIssueState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          if (state is CreateIssueLoading) {
            return const _LoadingView();
          }

          if (state is CreateIssueFormReady) {
            return _FormView(state: state);
          }

          if (state is CreateIssueLoadingProjects) {
            return _FormView(state: state.formState, isLoadingProjects: true);
          }

          if (state is CreateIssueSubmitting) {
            return const _SubmittingView();
          }

          if (state is CreateIssueError) {
            return _ErrorView(
              message: state.message,
              canRetry: state.previousFormState != null,
            );
          }

          if (state is CreateIssueSuccess) {
            return const _SuccessView();
          }

          return const _LoadingView();
        },
      ),
    );
  }

  void _handleStateChanges(BuildContext context, CreateIssueState state) {
    if (state is CreateIssueSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.issueCreatedSuccessfully),
          backgroundColor: AppColors.success,
        ),
      );
      // Navigate back with result
      Navigator.of(context).pop(true);
    } else if (state is CreateIssueError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
          action: state.previousFormState != null
              ? SnackBarAction(
                  label: AppLocalizations.of(context)!.commonRetry,
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<CreateIssueCubit>().resetToForm();
                  },
                )
              : null,
        ),
      );
    }
  }
}

/// Loading indicator view
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryBlue),
          SizedBox(height: 16),
          Text(
            'Loading form...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Submitting indicator view
class _SubmittingView extends StatelessWidget {
  const _SubmittingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primaryPurple),
          SizedBox(height: 16),
          Text(
            'Creating issue...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Success view (shown briefly before navigation)
class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: AppColors.success),
          SizedBox(height: 16),
          Text(
            'Issue created!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error view
class _ErrorView extends StatelessWidget {
  final String message;
  final bool canRetry;

  const _ErrorView({required this.message, required this.canRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message == 'No work package types available for this project'
                  ? AppLocalizations.of(context)!.issueFormNoWorkPackageTypes
                  : message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            if (canRetry)
              ElevatedButton.icon(
                onPressed: () {
                  context.read<CreateIssueCubit>().resetToForm();
                },
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.commonRetry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  context.read<CreateIssueCubit>().initializeForm();
                },
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.commonReload),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Main form view
class _FormView extends StatelessWidget {
  final CreateIssueFormReady state;
  final bool isLoadingProjects;

  const _FormView({required this.state, this.isLoadingProjects = false});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subject field
          _SubjectField(
            initialValue: state.subject,
            errorText: state.validationErrors['subject'],
          ),
          const SizedBox(height: 16),

          // Description field
          _DescriptionField(initialValue: state.description),
          const SizedBox(height: 16),

          // Group selector
          _GroupSelector(
            groups: state.groups,
            selectedGroupId: state.selectedGroupId,
            errorText: state.validationErrors['group'],
          ),
          const SizedBox(height: 16),

          // Equipment selector
          _EquipmentSelector(
            projects: state.projects,
            selectedProjectId: state.selectedProjectId,
            isEnabled: state.selectedGroupId != null,
            isLoading: isLoadingProjects,
            errorText: state.validationErrors['equipment'],
          ),
          const SizedBox(height: 20),

          // Priority selector
          _PrioritySelector(
            selectedPriority: state.selectedPriority,
            errorText: state.validationErrors['priority'],
          ),
          const SizedBox(height: 32),

          // Submit button
          _SubmitButton(isEnabled: state.isFormValid),
        ],
      ),
    );
  }
}

/// Subject text field
class _SubjectField extends StatelessWidget {
  final String initialValue;
  final String? errorText;

  const _SubjectField({required this.initialValue, this.errorText});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.issueFormSubjectLabel,
        hintText: AppLocalizations.of(context)!.issueFormSubjectHint,
        errorText: errorText,
        prefixIcon: const Icon(Icons.title, color: AppColors.iconSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.surface,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
      textInputAction: TextInputAction.next,
      onChanged: (value) {
        context.read<CreateIssueCubit>().updateSubject(value);
      },
    );
  }
}

/// Description text field
class _DescriptionField extends StatelessWidget {
  final String? initialValue;

  const _DescriptionField({this.initialValue});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.issueFormDescriptionLabel,
        hintText: AppLocalizations.of(context)!.issueFormDescriptionHint,
        prefixIcon: const Icon(
          Icons.description,
          color: AppColors.iconSecondary,
        ),
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.surface,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
      textInputAction: TextInputAction.newline,
      onChanged: (value) {
        context.read<CreateIssueCubit>().updateDescription(value);
      },
    );
  }
}

/// Group dropdown selector
class _GroupSelector extends StatelessWidget {
  final List<GroupItem> groups;
  final int? selectedGroupId;
  final String? errorText;

  const _GroupSelector({
    required this.groups,
    this.selectedGroupId,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: selectedGroupId,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.issueFormGroupLabel,
        hintText: AppLocalizations.of(context)!.issueFormGroupHint,
        errorText: errorText,
        prefixIcon: const Icon(Icons.group, color: AppColors.iconSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.surface,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
      items: groups.map((group) {
        return DropdownMenuItem<int>(value: group.id, child: Text(group.name));
      }).toList(),
      onChanged: (groupId) {
        if (groupId != null) {
          context.read<CreateIssueCubit>().selectGroup(groupId);
        }
      },
    );
  }
}

/// Equipment/Project dropdown selector
class _EquipmentSelector extends StatelessWidget {
  final List<ProjectItem> projects;
  final int? selectedProjectId;
  final bool isEnabled;
  final bool isLoading;
  final String? errorText;

  const _EquipmentSelector({
    required this.projects,
    this.selectedProjectId,
    required this.isEnabled,
    required this.isLoading,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        DropdownButtonFormField<int>(
          initialValue: selectedProjectId,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.issueFormEquipmentLabel,
            hintText: isEnabled 
                ? AppLocalizations.of(context)!.issueFilterSelectEquipment
                : AppLocalizations.of(context)!.issueFilterSelectGroupFirst,
            errorText: errorText,
            prefixIcon: const Icon(
              Icons.precision_manufacturing,
              color: AppColors.iconSecondary,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isEnabled ? AppColors.surface : Colors.grey[200],
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 2,
              ),
            ),
          ),
          items: projects.map((project) {
            return DropdownMenuItem<int>(
              value: project.id,
              child: Text(project.name),
            );
          }).toList(),
          onChanged: isEnabled && !isLoading
              ? (projectId) {
                  if (projectId != null) {
                    context.read<CreateIssueCubit>().selectProject(projectId);
                  }
                }
              : null,
        ),
        if (isLoading)
          const Positioned(
            right: 48,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
      ],
    );
  }
}

/// Priority selector with colored indicators
class _PrioritySelector extends StatelessWidget {
  final PriorityLevel? selectedPriority;
  final String? errorText;

  const _PrioritySelector({this.selectedPriority, this.errorText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            AppLocalizations.of(context)!.issueFormPriorityLabel,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SegmentedButton<PriorityLevel>(
          segments: [
            ButtonSegment(
              value: PriorityLevel.low,
              label: _PriorityLabel(
                label: 'Low',
                color: const Color(0xFF81D4FA),
              ),
            ),
            ButtonSegment(
              value: PriorityLevel.normal,
              label: _PriorityLabel(
                label: 'Normal',
                color: const Color(0xFF42A5F5),
              ),
            ),
            ButtonSegment(
              value: PriorityLevel.high,
              label: _PriorityLabel(label: 'High', color: AppColors.warning),
            ),
            ButtonSegment(
              value: PriorityLevel.immediate,
              label: _PriorityLabel(
                label: 'Urgent',
                color: const Color(0xFF9C27B0),
              ),
            ),
          ],
          selected: selectedPriority != null ? {selectedPriority!} : {},
          onSelectionChanged: (Set<PriorityLevel> selected) {
            if (selected.isNotEmpty) {
              context.read<CreateIssueCubit>().selectPriority(selected.first);
            }
          },
          showSelectedIcon: false,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.lightPurple.withValues(alpha: 0.3);
              }
              return AppColors.surface;
            }),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              errorText!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

/// Priority label with colored indicator
class _PriorityLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _PriorityLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// Submit button
class _SubmitButton extends StatelessWidget {
  final bool isEnabled;

  const _SubmitButton({required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isEnabled
          ? () => context.read<CreateIssueCubit>().submitForm()
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey[500],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_circle_outline),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.issueFormCreateButton,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
