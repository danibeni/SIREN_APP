import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siren_app/core/di/injection.dart' as injection;
import 'package:siren_app/core/theme/app_colors.dart';
import 'package:siren_app/core/widgets/gradient_app_bar.dart';
import 'package:siren_app/features/issues/domain/entities/attachment_entity.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/entities/priority_entity.dart';
import 'package:siren_app/features/issues/domain/entities/status_entity.dart';
import 'package:siren_app/features/issues/presentation/cubit/issue_detail_cubit.dart';
import 'package:siren_app/features/issues/presentation/cubit/issue_detail_state.dart';
import 'package:siren_app/features/issues/presentation/widgets/attachment_list_item.dart';

class IssueDetailPage extends StatelessWidget {
  final int issueId;

  const IssueDetailPage({super.key, required this.issueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          injection.getIt<IssueDetailCubit>()..loadIssue(issueId),
      child: BlocBuilder<IssueDetailCubit, IssueDetailState>(
        builder: (context, state) {
          // Get issue for AppBar equipment display
          final issue = state is IssueDetailLoaded
              ? state.issue
              : state is IssueDetailSaveSuccess
              ? state.issue
              : state is IssueDetailEditing
              ? state.issue
              : state is IssueDetailSaving
              ? state.issue
              : null;

          return Scaffold(
            appBar: GradientAppBar(
              title: 'Issue Details',
              actions: issue != null
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.precision_manufacturing,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              issue.equipmentName ??
                                  'Equipment ${issue.equipment}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  : null,
            ),
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
                              context.read<IssueDetailCubit>().loadIssue(
                                issueId,
                              );
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
                        state is IssueDetailLoaded &&
                        state.isLoadingAttachments;

                    return _DetailView(
                      issue: issue,
                      attachments: attachments,
                      isLoadingAttachments: isLoadingAttachments,
                    );
                  }

                  if (state is IssueDetailEditing ||
                      state is IssueDetailSaving) {
                    return _EditView(
                      state: state,
                      isSaving: state is IssueDetailSaving,
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
            floatingActionButton:
                BlocBuilder<IssueDetailCubit, IssueDetailState>(
                  builder: (context, state) {
                    // Show Edit FAB in read-only mode
                    if (state is IssueDetailLoaded ||
                        state is IssueDetailSaveSuccess) {
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
                    if (state is IssueDetailEditing ||
                        state is IssueDetailSaving) {
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
                                    context
                                        .read<IssueDetailCubit>()
                                        .cancelEdit();
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
                                    context
                                        .read<IssueDetailCubit>()
                                        .saveChanges();
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
          );
        },
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

  /// Parse color from hex string
  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return AppColors.textSecondary;
    }
    try {
      // Remove # if present
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppColors.textSecondary;
    }
  }

  /// Build status display with circle + text (same format as edit mode)
  Widget _buildStatusDisplay({
    required String statusName,
    String? statusColorHex,
  }) {
    final color = _parseColor(statusColorHex);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.background,
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              statusName,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build priority display with circle + text (same format as edit mode)
  Widget _buildPriorityDisplay({
    required String priorityName,
    String? priorityColorHex,
  }) {
    final color = _parseColor(priorityColorHex);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.background,
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              priorityName,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

          // Status & Priority Card (same format as edit mode)
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
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'STATUS & PRIORITY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildStatusDisplay(
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
                            const Text(
                              'Priority',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPriorityDisplay(
                              priorityName: issue.priorityName ?? 'Unknown',
                              priorityColorHex: issue.priorityColorHex,
                            ),
                          ],
                        ),
                      ),
                    ],
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

  PriorityLevel get editedPriority {
    if (widget.state is IssueDetailEditing) {
      return (widget.state as IssueDetailEditing).editedPriority;
    } else {
      return (widget.state as IssueDetailSaving).editedPriority;
    }
  }

  IssueStatus get editedStatus {
    if (widget.state is IssueDetailEditing) {
      return (widget.state as IssueDetailEditing).editedStatus;
    } else {
      return (widget.state as IssueDetailSaving).editedStatus;
    }
  }

  String? get editedDescription {
    if (widget.state is IssueDetailEditing) {
      return (widget.state as IssueDetailEditing).editedDescription;
    } else {
      return (widget.state as IssueDetailSaving).editedDescription;
    }
  }

  List<StatusEntity> get availableStatuses {
    if (widget.state is IssueDetailEditing) {
      return (widget.state as IssueDetailEditing).availableStatuses;
    } else if (widget.state is IssueDetailSaving) {
      return (widget.state as IssueDetailSaving).availableStatuses;
    }
    return const [];
  }

  List<PriorityEntity> get availablePriorities {
    if (widget.state is IssueDetailEditing) {
      return (widget.state as IssueDetailEditing).availablePriorities;
    } else if (widget.state is IssueDetailSaving) {
      return (widget.state as IssueDetailSaving).availablePriorities;
    }
    return const [];
  }

  bool get isLoadingStatuses {
    if (widget.state is IssueDetailEditing) {
      return (widget.state as IssueDetailEditing).isLoadingStatuses;
    }
    return false;
  }

  bool get isLoadingPriorities {
    if (widget.state is IssueDetailEditing) {
      return (widget.state as IssueDetailEditing).isLoadingPriorities;
    }
    return false;
  }

  List<AttachmentEntity> get attachments {
    if (widget.state is IssueDetailEditing) {
      return (widget.state as IssueDetailEditing).attachments;
    } else if (widget.state is IssueDetailSaving) {
      return (widget.state as IssueDetailSaving).attachments;
    }
    return const [];
  }

  /// Map StatusEntity name to IssueStatus enum
  /// Uses same logic as IssueModel._mapNameToStatus
  IssueStatus? _mapStatusNameToEnum(String name) {
    if (name.isEmpty) return null;
    final lowerName = name.toLowerCase().trim();

    // Match common status names
    if (lowerName == 'new' || lowerName.contains('new')) {
      return IssueStatus.newStatus;
    } else if (lowerName == 'in progress' ||
        lowerName == 'in-progress' ||
        lowerName.contains('progress') ||
        lowerName == 'open' ||
        lowerName.contains('open')) {
      return IssueStatus.inProgress;
    } else if (lowerName == 'on hold' ||
        lowerName == 'on-hold' ||
        lowerName.contains('hold') ||
        lowerName == 'waiting' ||
        lowerName.contains('waiting')) {
      return IssueStatus.onHold;
    } else if (lowerName == 'closed' ||
        lowerName.contains('closed') ||
        lowerName == 'resolved' ||
        lowerName.contains('resolved')) {
      return IssueStatus.closed;
    } else if (lowerName == 'rejected' || lowerName.contains('reject')) {
      return IssueStatus.rejected;
    }

    // Default fallback
    return IssueStatus.newStatus;
  }

  /// Find StatusEntity by matching the current issue's status ID or name
  ///
  /// Priority order:
  /// 1. Match by statusId (most precise)
  /// 2. Match by statusName (handles statuses like "Workaround" not in enum)
  /// 3. Fallback to enum-based matching
  StatusEntity? _findStatusEntity(IssueStatus status) {
    if (availableStatuses.isEmpty) {
      return null;
    }

    // First priority: Match by status ID (most accurate)
    if (issue.statusId != null) {
      try {
        final matched = availableStatuses.firstWhere(
          (s) => s.id == issue.statusId,
        );
        return matched;
      } catch (e) {
        // ID not found in available statuses, continue to name matching
      }
    }

    // Second priority: Match by actual statusName from the issue
    // This handles statuses like "Workaround" that may not map to the enum
    if (issue.statusName != null && issue.statusName!.isNotEmpty) {
      final currentStatusName = issue.statusName!.toLowerCase().trim();
      try {
        // Try exact match first
        var matched = availableStatuses.where(
          (s) => s.name.toLowerCase().trim() == currentStatusName,
        );
        if (matched.isNotEmpty) {
          return matched.first;
        }

        // Try partial match (contains)
        matched = availableStatuses.where(
          (s) =>
              s.name.toLowerCase().contains(currentStatusName) ||
              currentStatusName.contains(s.name.toLowerCase()),
        );
        if (matched.isNotEmpty) {
          return matched.first;
        }
      } catch (e) {
        // Continue to enum-based fallback
      }
    }

    // Fallback: Try to match using enum mapping
    final statusName = switch (status) {
      IssueStatus.newStatus => 'new',
      IssueStatus.inProgress => 'in progress',
      IssueStatus.onHold => 'on hold',
      IssueStatus.closed => 'closed',
      IssueStatus.rejected => 'rejected',
    };

    try {
      return availableStatuses.firstWhere(
        (s) => s.name.toLowerCase().contains(statusName),
        orElse: () => availableStatuses.first,
      );
    } catch (e) {
      // If still no match found, return first available or null
      return availableStatuses.isNotEmpty ? availableStatuses.first : null;
    }
  }

  /// Map PriorityLevel enum to PriorityEntity
  PriorityEntity? _findPriorityEntity(PriorityLevel priority) {
    return availablePriorities.firstWhere(
      (p) => p.priorityLevel == priority,
      orElse: () => availablePriorities.isNotEmpty
          ? availablePriorities.first
          : PriorityEntity(
              id: 0,
              name: priority.toString(),
              priorityLevel: priority,
            ),
    );
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

          // Priority & Status Dropdowns (Editable)
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
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'STATUS & PRIORITY *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status *',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (isLoadingStatuses)
                              const SizedBox(
                                height: 48,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else
                              _buildStatusDropdown(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Priority *',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (isLoadingPriorities)
                              const SizedBox(
                                height: 48,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else
                              _buildPriorityDropdown(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Attachments Card (always visible in edit mode)
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
                  if (attachments.isNotEmpty)
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
                  const SizedBox(height: 16),
                  // Add Attachment Button (only in edit mode)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.isSaving
                          ? null
                          : () => _showAddAttachmentDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Attachment'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.primaryBlue),
                      ),
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

  Widget _buildStatusDropdown() {
    // If no statuses available yet, show a placeholder
    if (availableStatuses.isEmpty) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.background,
        ),
        child: const Text(
          'No statuses available',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }

    final currentStatusEntity = _findStatusEntity(editedStatus);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.background,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StatusEntity>(
          value: currentStatusEntity,
          isExpanded: true,
          isDense: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          items: availableStatuses.map((status) {
            return DropdownMenuItem<StatusEntity>(
              value: status,
              child: Row(
                children: [
                  if (status.colorHex != null)
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: _parseColor(status.colorHex!),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      status.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: widget.isSaving
              ? null
              : (StatusEntity? newStatus) {
                  if (newStatus != null) {
                    final mappedStatus = _mapStatusNameToEnum(newStatus.name);
                    if (mappedStatus != null) {
                      context.read<IssueDetailCubit>().updateStatus(
                        mappedStatus,
                      );
                    }
                  }
                },
          hint: Text(
            currentStatusEntity?.name ?? 'Select Status',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityDropdown() {
    final currentPriorityEntity = _findPriorityEntity(editedPriority);
    final selectedPriorityName =
        currentPriorityEntity?.name ?? 'Select Priority';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.background,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PriorityEntity>(
          value: currentPriorityEntity,
          isExpanded: true,
          isDense: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          items: availablePriorities.map((priority) {
            return DropdownMenuItem<PriorityEntity>(
              value: priority,
              child: Row(
                children: [
                  if (priority.colorHex != null)
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: _parseColor(priority.colorHex!),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      priority.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: widget.isSaving
              ? null
              : (PriorityEntity? newPriority) {
                  if (newPriority != null) {
                    context.read<IssueDetailCubit>().updatePriority(
                      newPriority.priorityLevel,
                    );
                  }
                },
          hint: Text(
            selectedPriorityName,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorHex) {
    try {
      // Remove # if present
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppColors.textSecondary;
    }
  }

  /// Show dialog to select attachment source (file picker)
  Future<void> _showAddAttachmentDialog(BuildContext context) async {
    // Show bottom sheet with options
    final result = await showModalBottomSheet<FilePickerResult?>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Select File'),
              subtitle: const Text('Choose a file from device'),
              onTap: () async {
                try {
                  final pickerResult = await FilePicker.platform.pickFiles(
                    type: FileType.any,
                    allowMultiple: false,
                  );
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop(pickerResult);
                  }
                } catch (e) {
                  // Handle any errors from file picker
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(
                        content: Text('Error selecting file: ${e.toString()}'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Select Image'),
              subtitle: const Text('Choose an image from gallery'),
              onTap: () async {
                try {
                  final pickerResult = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    allowMultiple: false,
                  );
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop(pickerResult);
                  }
                } catch (e) {
                  // Handle any errors from file picker
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(
                        content: Text('Error selecting image: ${e.toString()}'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () {
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
              },
            ),
          ],
        ),
      ),
    );

    // Check if user cancelled or no file was selected
    if (result == null || result.files.isEmpty) {
      return;
    }

    try {
      final pickedFile = result.files.single;
      if (pickedFile.path == null || pickedFile.path!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File path is not available'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final file = File(pickedFile.path!);
      final fileName = pickedFile.name;

      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Uploading attachment...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Call cubit to add attachment
      if (!context.mounted) return;

      final cubit = context.read<IssueDetailCubit>();
      final attachmentCountBefore = attachments.length;

      // Call addAttachment and wait for completion
      await cubit.addAttachment(filePath: file.path, fileName: fileName);

      // Check if attachment was added successfully
      if (!context.mounted) return;

      final currentState = cubit.state;
      if (currentState is IssueDetailEditing) {
        final attachmentCountAfter = currentState.attachments.length;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (attachmentCountAfter > attachmentCountBefore) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attachment added successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Error occurred (cubit logs it)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add attachment. Please try again.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // State changed unexpectedly
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add attachment. Please try again.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Handle any unexpected errors
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing file: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
