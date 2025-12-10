import 'package:flutter/material.dart';
import 'package:siren_app/core/theme/app_colors.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/presentation/widgets/priority_circle.dart';
import 'package:siren_app/features/issues/presentation/widgets/status_badge.dart';

class IssueCard extends StatelessWidget {
  const IssueCard({
    super.key,
    required this.issue,
    this.onTap,
    this.statusColorHex,
    this.onSync,
    this.onCancelSync,
  });

  final IssueEntity issue;
  final VoidCallback? onTap;
  final String? statusColorHex;
  final VoidCallback? onSync;
  final VoidCallback? onCancelSync;

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final local = date.toLocal();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final day = twoDigits(local.day);
    final month = twoDigits(local.month);
    final year = local.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final equipmentLabel =
        issue.equipmentName ?? 'Equipment ${issue.equipment}';
    final statusLabel = issue.statusName ?? '';
    final dateLabel = _formatDate(issue.updatedAt);
    final userLabel = (issue.updatedByName ?? issue.creatorName)?.trim();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Pending sync indicator banner
            if (issue.hasPendingSync)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: const Border(
                    bottom: BorderSide(color: Colors.orange, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 14,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pending synchronization - Saved locally',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Main card content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      PriorityCircle(priority: issue.priorityLevel, size: 18),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                issue.subject,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              status: issue.status,
                              colorHex: issue.statusColorHex ?? statusColorHex,
                              label: statusLabel.isEmpty ? null : statusLabel,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (issue.description != null &&
                            issue.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            issue.description!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.memory,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 160,
                                  ),
                                  child: Text(
                                    equipmentLabel,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (userLabel != null && userLabel.isNotEmpty)
                                  Text(
                                    userLabel,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (dateLabel != null)
                                  Text(
                                    dateLabel,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if ((userLabel == null || userLabel.isEmpty) &&
                                    dateLabel == null)
                                  const Text(
                                    '—',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Sync/Cancel buttons (only when hasPendingSync)
            if (issue.hasPendingSync &&
                (onSync != null || onCancelSync != null))
              Container(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  top: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onCancelSync != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onCancelSync,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.error),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                    if (onCancelSync != null && onSync != null)
                      const SizedBox(width: 12),
                    if (onSync != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onSync,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryBlue),
                            ),
                            child: const Icon(
                              Icons.cloud_upload,
                              size: 18,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
