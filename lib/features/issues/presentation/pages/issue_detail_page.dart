import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siren_app/core/di/injection.dart' as injection;
import 'package:siren_app/core/theme/app_colors.dart';
import 'package:siren_app/features/issues/domain/entities/attachment_entity.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/presentation/cubit/issue_detail_cubit.dart';
import 'package:siren_app/features/issues/presentation/cubit/issue_detail_state.dart';
import 'package:siren_app/features/issues/presentation/widgets/attachment_list_item.dart';
import 'package:siren_app/features/issues/presentation/widgets/priority_display.dart';
import 'package:siren_app/features/issues/presentation/widgets/status_display.dart';

class IssueDetailPage extends StatelessWidget {
  final int issueId;

  const IssueDetailPage({super.key, required this.issueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          injection.getIt<IssueDetailCubit>()..loadIssue(issueId),
      child: Scaffold(
        appBar: AppBar(title: const Text('Issue Details')),
        body: BlocListener<IssueDetailCubit, IssueDetailState>(
          listener: (context, state) {
            // Show success message when save completes
            if (state is IssueDetailSaveSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.wasOffline
                        ? 'Changes saved locally. Sync when online.'
                        : 'Issue updated successfully!',
                  ),
                  backgroundColor: state.wasOffline
                      ? Colors.orange
                      : Colors.green,
                ),
              );
            }
          },
          child: BlocBuilder<IssueDetailCubit, IssueDetailState>(
            builder: (context, state) {
              if (state is IssueDetailLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is IssueDetailError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          state.message,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.read<IssueDetailCubit>().loadIssue(issueId);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is IssueDetailLoaded ||
                  state is IssueDetailSaveSuccess) {
                final issue = state is IssueDetailLoaded
                    ? state.issue
                    : (state as IssueDetailSaveSuccess).issue;
                final attachments = state is IssueDetailLoaded
                    ? state.attachments
                    : (state as IssueDetailSaveSuccess).attachments;
                final isLoadingAttachments =
                    state is IssueDetailLoaded && state.isLoadingAttachments;

                return _DetailView(
                  issue: issue,
                  attachments: attachments,
                  isLoadingAttachments: isLoadingAttachments,
                );
              }

              if (state is IssueDetailEditing || state is IssueDetailSaving) {
                return _EditView(
                  state: state,
                  isSaving: state is IssueDetailSaving,
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
        floatingActionButton: BlocBuilder<IssueDetailCubit, IssueDetailState>(
          builder: (context, state) {
            // Show Edit FAB in read-only mode
            if (state is IssueDetailLoaded || state is IssueDetailSaveSuccess) {
              return FloatingActionButton.extended(
                onPressed: () {
                  context.read<IssueDetailCubit>().enterEditMode();
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
                backgroundColor: AppColors.primaryBlue,
              );
            }

            // Show Save/Cancel FABs in edit mode
            if (state is IssueDetailEditing || state is IssueDetailSaving) {
              final isSaving = state is IssueDetailSaving;
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel button
                  FloatingActionButton(
                    heroTag: 'cancel',
                    onPressed: isSaving
                        ? null
                        : () {
                            context.read<IssueDetailCubit>().cancelEdit();
                          },
                    backgroundColor: AppColors.error,
                    child: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 16),
                  // Save button
                  FloatingActionButton.extended(
                    heroTag: 'save',
                    onPressed: isSaving
                        ? null
                        : () {
                            context.read<IssueDetailCubit>().saveChanges();
                          },
                    icon: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(isSaving ? 'Saving...' : 'Save'),
                    backgroundColor: AppColors.primaryBlue,
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _DetailView extends StatelessWidget {
  final IssueEntity issue;
  final List<AttachmentEntity> attachments;
  final bool isLoadingAttachments;

  const _DetailView({
    required this.issue,
    this.attachments = const [],
    this.isLoadingAttachments = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    color: AppColors.primaryBlue,
                    margin: const EdgeInsets.only(right: 16),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUBJECT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          issue.subject,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status & Priority Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'STATUS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        StatusDisplay(
                          statusName: issue.statusName ?? 'Unknown',
                          statusColorHex: issue.statusColorHex,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.flag_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PRIORITY',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        PriorityDisplay(
                          priorityName: issue.priorityName ?? 'Unknown',
                          priorityColorHex: issue.priorityColorHex,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 100,
                      maxHeight: 300,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        issue.description ?? 'No description provided',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Attachments Card (always visible)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_file,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ATTACHMENTS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.lightBlue),
                        ),
                        child: Text(
                          '${attachments.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isLoadingAttachments)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (attachments.isNotEmpty)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: attachments.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 8),
                      itemBuilder: (context, index) {
                        final attachment = attachments[index];
                        return AttachmentListItem(
                          fileName: attachment.fileName,
                          mimeType: attachment.contentType,
                          downloadUrl: attachment.downloadUrl,
                          localFilePath: attachment.localFilePath,
                        );
                      },
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No attachments yet.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditView extends StatefulWidget {
  final IssueDetailState state;
  final bool isSaving;

  const _EditView({required this.state, this.isSaving = false});

  @override
  State<_EditView> createState() => _EditViewState();
}

class _EditViewState extends State<_EditView> {
  late TextEditingController _subjectController;
  late TextEditingController _descriptionController;

  // Helper getters to access state properties
  IssueEntity get issue {
    if (widget.state is IssueDetailEditing) {
      return (widget.state as IssueDetailEditing).issue;
    } else {
      return (widget.state as IssueDetailSaving).issue;
    }
  }

  String get editedSubject {
    if (widget.state is IssueDetailEditing) {
      return (widget.state as IssueDetailEditing).editedSubject;
    } else {
      return (widget.state as IssueDetailSaving).editedSubject;
    }
  }

  String? get editedDescription {
    if (widget.state is IssueDetailEditing) {
      return (widget.state as IssueDetailEditing).editedDescription;
    } else {
      return (widget.state as IssueDetailSaving).editedDescription;
    }
  }

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: editedSubject);
    _descriptionController = TextEditingController(
      text: editedDescription ?? '',
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Editing Mode Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryBlue),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Edit Mode - Modify fields below',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.isSaving)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Subject Field
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.title,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'SUBJECT *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subjectController,
                    enabled: !widget.isSaving,
                    decoration: InputDecoration(
                      hintText: 'Enter issue subject',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                    style: const TextStyle(fontSize: 16),
                    onChanged: (value) {
                      context.read<IssueDetailCubit>().updateSubject(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description Field
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'DESCRIPTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    enabled: !widget.isSaving,
                    decoration: InputDecoration(
                      hintText: 'Enter issue description (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                    style: const TextStyle(fontSize: 14, height: 1.5),
                    maxLines: 5,
                    onChanged: (value) {
                      context.read<IssueDetailCubit>().updateDescription(
                        value.isEmpty ? null : value,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Priority & Status Display (Read-only for MVP)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status and Priority',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status:',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            StatusDisplay(
                              statusName: issue.statusName ?? 'Unknown',
                              statusColorHex: issue.statusColorHex,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Priority:',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            PriorityDisplay(
                              priorityName: issue.priorityName ?? 'Unknown',
                              priorityColorHex: issue.priorityColorHex,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Status and Priority editing will be available in a future update',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Equipment Display (Read-only)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.precision_manufacturing,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'EQUIPMENT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.lock,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'READ-ONLY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.build,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            issue.equipmentName ??
                                'Equipment ${issue.equipment}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '⚠️ Equipment cannot be changed from mobile app',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }
}
