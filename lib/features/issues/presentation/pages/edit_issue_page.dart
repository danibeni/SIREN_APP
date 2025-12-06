import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siren_app/core/di/injection.dart';
import 'package:siren_app/core/theme/app_colors.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/presentation/cubit/edit_issue_cubit.dart';
import 'package:siren_app/features/issues/presentation/cubit/edit_issue_state.dart';
import 'package:siren_app/features/issues/presentation/cubit/work_package_type_cubit.dart';
import 'package:siren_app/features/issues/presentation/cubit/work_package_type_state.dart';

class EditIssuePage extends StatelessWidget {
  const EditIssuePage({super.key, required this.issue});

  final IssueEntity issue;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          // Use locally provided issue data; avoid remote fetch to work in offline mode
          create: (_) => getIt<EditIssueCubit>()..initializeFromEntity(issue),
        ),
        BlocProvider(create: (_) => getIt<WorkPackageTypeCubit>()..load()),
      ],
      child: const _EditIssueView(),
    );
  }
}

class _EditIssueView extends StatelessWidget {
  const _EditIssueView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Issue'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<EditIssueCubit, EditIssueState>(
        listener: (context, state) {
          if (state is EditIssueSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Issue updated successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is EditIssueError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EditIssueLoading || state is EditIssueInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }
          if (state is EditIssueLoaded) {
            return _EditIssueForm(state: state, isSaving: false);
          }
          if (state is EditIssueSaving) {
            return _EditIssueForm(state: state.form, isSaving: true);
          }
          if (state is EditIssueError && state.previousForm != null) {
            return _EditIssueForm(state: state.previousForm!, isSaving: false);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _EditIssueForm extends StatefulWidget {
  const _EditIssueForm({required this.state, required this.isSaving});

  final EditIssueLoaded state;
  final bool isSaving;

  @override
  State<_EditIssueForm> createState() => _EditIssueFormState();
}

class _EditIssueFormState extends State<_EditIssueForm> {
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.state.subject);
    _descriptionController = TextEditingController(
      text: widget.state.description ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _EditIssueForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.subject != widget.state.subject) {
      _subjectController.text = widget.state.subject;
    }
    if (oldWidget.state.description != widget.state.description) {
      _descriptionController.text = widget.state.description ?? '';
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditIssueCubit>();
    final statuses = _availableStatuses(context);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _subjectController,
                enabled: !widget.isSaving,
                decoration: InputDecoration(
                  labelText: 'Subject *',
                  border: const OutlineInputBorder(),
                  errorText: widget.state.validationErrors['subject'],
                ),
                onChanged: cubit.updateSubject,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !widget.isSaving,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                onChanged: cubit.updateDescription,
              ),
              const SizedBox(height: 16),
              _PriorityDropdown(
                selected: widget.state.priority,
                isDisabled: widget.isSaving,
                onChanged: cubit.updatePriority,
              ),
              const SizedBox(height: 16),
              _StatusDropdown(
                selected: widget.state.status,
                options: statuses,
                isDisabled: widget.isSaving,
                onChanged: cubit.updateStatus,
              ),
              const SizedBox(height: 16),
              TextFormField(
                enabled: false,
                initialValue:
                    widget.state.issue.equipmentName ??
                    'Equipment ${widget.state.issue.equipment}',
                decoration: const InputDecoration(
                  labelText: 'Equipment',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.lock, size: 16),
                  helperText: 'Cannot be changed',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.isSaving
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: widget.isSaving ? null : cubit.submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.isSaving)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black38,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<IssueStatus> _availableStatuses(BuildContext context) {
    final typeState = context.watch<WorkPackageTypeCubit>().state;
    if (typeState is! WorkPackageTypeLoaded) {
      return IssueStatus.values;
    }

    final mapped = <IssueStatus>[];
    for (final status in typeState.statuses) {
      final mappedStatus = _mapStatusName(status.name);
      if (!mapped.contains(mappedStatus)) {
        mapped.add(mappedStatus);
      }
    }
    if (mapped.isEmpty) {
      return IssueStatus.values;
    }
    return mapped;
  }

  IssueStatus _mapStatusName(String? name) {
    if (name == null || name.isEmpty) return IssueStatus.newStatus;
    final lower = name.toLowerCase();
    if (lower.contains('rejected') || lower.contains('rechazad')) {
      return IssueStatus.rejected;
    }
    if (lower.contains('closed') || lower.contains('cerrad')) {
      return IssueStatus.closed;
    }
    if (lower.contains('hold') || lower.contains('esper')) {
      return IssueStatus.onHold;
    }
    if (lower.contains('progress') || lower.contains('curso')) {
      return IssueStatus.inProgress;
    }
    return IssueStatus.newStatus;
  }
}

class _PriorityDropdown extends StatelessWidget {
  const _PriorityDropdown({
    required this.selected,
    required this.isDisabled,
    required this.onChanged,
  });

  final PriorityLevel selected;
  final bool isDisabled;
  final ValueChanged<PriorityLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Priority',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PriorityLevel>(
          value: selected,
          isExpanded: true,
          onChanged: isDisabled ? null : (value) => onChanged(value!),
          items: PriorityLevel.values.map((level) {
            return DropdownMenuItem(value: level, child: Text(_label(level)));
          }).toList(),
        ),
      ),
    );
  }

  String _label(PriorityLevel level) {
    switch (level) {
      case PriorityLevel.low:
        return 'Low';
      case PriorityLevel.normal:
        return 'Normal';
      case PriorityLevel.high:
        return 'High';
      case PriorityLevel.immediate:
        return 'Immediate';
    }
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({
    required this.selected,
    required this.options,
    required this.isDisabled,
    required this.onChanged,
  });

  final IssueStatus selected;
  final List<IssueStatus> options;
  final bool isDisabled;
  final ValueChanged<IssueStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<IssueStatus>(
          value: selected,
          isExpanded: true,
          onChanged: isDisabled ? null : (value) => onChanged(value!),
          items: options.map((status) {
            return DropdownMenuItem(value: status, child: Text(_label(status)));
          }).toList(),
        ),
      ),
    );
  }

  String _label(IssueStatus status) {
    switch (status) {
      case IssueStatus.newStatus:
        return 'New';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.onHold:
        return 'Workaround';
      case IssueStatus.closed:
        return 'Closed';
      case IssueStatus.rejected:
        return 'Rejected';
    }
  }
}
