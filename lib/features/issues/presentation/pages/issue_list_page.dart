import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siren_app/core/di/injection.dart';
import 'package:siren_app/core/theme/app_colors.dart';
import 'package:siren_app/features/issues/domain/entities/status_entity.dart';
import 'package:siren_app/features/issues/presentation/cubit/issues_list_cubit.dart';
import 'package:siren_app/features/issues/presentation/cubit/issues_list_state.dart';
import 'package:siren_app/features/issues/presentation/cubit/work_package_type_cubit.dart';
import 'package:siren_app/features/issues/presentation/cubit/work_package_type_state.dart';
import 'package:siren_app/features/issues/presentation/widgets/issue_card.dart';
import 'package:siren_app/features/issues/presentation/widgets/issue_search_bar.dart';
import 'package:siren_app/features/issues/presentation/widgets/issue_filter_sheet.dart';

class IssueListPage extends StatelessWidget {
  const IssueListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<IssuesListCubit>()..loadIssues()),
        // Use BlocProvider.value to use the singleton instance
        // This prevents the cubit from being closed when the page is disposed
        BlocProvider.value(value: getIt<WorkPackageTypeCubit>()..load()),
      ],
      child: const _IssueListView(),
    );
  }
}

class _IssueListView extends StatelessWidget {
  const _IssueListView();

  Future<void> _refreshAll(BuildContext context) async {
    // Refresh statuses (colors) and then issues list
    await context.read<WorkPackageTypeCubit>().load();
    if (context.mounted) {
      await context.read<IssuesListCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorkPackageTypeCubit, WorkPackageTypeState>(
      listener: (context, state) {
        // When type changes (loaded), refresh the issue list
        if (state is WorkPackageTypeLoaded) {
          context.read<IssuesListCubit>().refresh();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SIREN: Issue Reporting'),
          actions: [
            BlocBuilder<IssuesListCubit, IssuesListState>(
              builder: (context, state) {
                final cubit = context.read<IssuesListCubit>();
                final hasFilters = cubit.hasActiveFilters;
                return IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.filter_list),
                      if (hasFilters)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => _showFilterSheet(context),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _refreshAll(context),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                await Navigator.of(context).pushNamed('/settings');
                // Reload type when returning from settings
                if (context.mounted) {
                  context.read<WorkPackageTypeCubit>().load();
                  // Don't call refresh here - BlocListener will handle it
                }
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).pushNamed('/create-issue'),
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: AppColors.buttonText,
          icon: const Icon(Icons.add),
          label: const Text('New Issue'),
        ),
        body: BlocBuilder<IssuesListCubit, IssuesListState>(
          builder: (context, state) {
            if (state is IssuesListLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is IssuesListError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<IssuesListCubit>().loadIssues(),
              );
            }
            if (state is IssuesListLoaded || state is IssuesListRefreshing) {
              final issues = state is IssuesListLoaded
                  ? state.issues
                  : (state as IssuesListRefreshing).issues;
              final isFromCache =
                  state is IssuesListLoaded && state.isFromCache;

              return BlocBuilder<WorkPackageTypeCubit, WorkPackageTypeState>(
                builder: (context, typeState) {
                  final statusColorByName = _statusColorMap(typeState);

                  return Column(
                    children: [
                      if (isFromCache)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: AppColors.info.withValues(alpha: 0.1),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.cloud_off,
                                size: 16,
                                color: AppColors.info,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Offline mode - Showing cached data',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      BlocBuilder<IssuesListCubit, IssuesListState>(
                        builder: (context, state) {
                          final cubit = context.read<IssuesListCubit>();
                          return IssueSearchBar(
                            initialValue: cubit.searchTerms ?? '',
                            onSearchChanged: (searchTerms) {
                              cubit.loadIssues(
                                searchTerms: searchTerms.isEmpty
                                    ? ''
                                    : searchTerms,
                              );
                            },
                          );
                        },
                      ),
                      Expanded(
                        child: issues.isEmpty
                            ? const _EmptyView()
                            : RefreshIndicator(
                                onRefresh: () => _refreshAll(context),
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: issues.length,
                                  itemBuilder: (context, index) {
                                    final issue = issues[index];
                                    final colorHex =
                                        statusColorByName[_normalizeStatusName(
                                          issue.statusName,
                                        )];
                                    return IssueCard(
                                      issue: issue,
                                      statusColorHex: colorHex,
                                      onTap: () async {
                                        // Navigate to detail page
                                        await Navigator.of(context).pushNamed(
                                          '/issue-detail',
                                          arguments: issue.id,
                                        );
                                        // Reload list when returning from detail page
                                        // This ensures pending sync changes are visible
                                        // Preserve current filters
                                        if (context.mounted) {
                                          final cubit = context.read<IssuesListCubit>();
                                          cubit.loadIssues(
                                            statusIds: cubit.statusIds,
                                            priorityIds: cubit.priorityIds,
                                            equipmentId: cubit.equipmentId,
                                            groupId: cubit.groupId,
                                            searchTerms: cubit.searchTerms,
                                          );
                                        }
                                      },
                                      onSync: issue.hasPendingSync
                                          ? () {
                                              context
                                                  .read<IssuesListCubit>()
                                                  .syncIssue(issue.id!);
                                            }
                                          : null,
                                      onCancelSync: issue.hasPendingSync
                                          ? () {
                                              // Show confirmation dialog
                                              _showDiscardConfirmation(
                                                context,
                                                issue.id!,
                                              );
                                            }
                                          : null,
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

Map<String, String?> _statusColorMap(WorkPackageTypeState state) {
  if (state is WorkPackageTypeLoaded) {
    final map = <String, String?>{};
    for (final status in state.statuses) {
      map[_normalizeStatusName(status.name)] = status.colorHex;
    }
    return map;
  }
  return {};
}

String _normalizeStatusName(String? name) {
  if (name == null) return '';
  return name.trim().toLowerCase().replaceAll(' ', '');
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'No issues found',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Pull to refresh or create a new issue.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Show confirmation dialog before discarding local changes
void _showDiscardConfirmation(BuildContext context, int issueId) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Discard Changes?'),
      content: const Text(
        'This will discard all local modifications and restore the issue from the server. This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            context.read<IssuesListCubit>().discardLocalChanges(issueId);
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Discard'),
        ),
      ],
    ),
  );
}

void _showFilterSheet(BuildContext context) {
  final cubit = context.read<IssuesListCubit>();
  final typeState = context.read<WorkPackageTypeCubit>().state;
  final statuses = typeState is WorkPackageTypeLoaded
      ? typeState.statuses
      : <StatusEntity>[];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => IssueFilterSheet(
        selectedStatusIds: cubit.statusIds,
        selectedPriorityIds: cubit.priorityIds,
        selectedEquipmentId: cubit.equipmentId,
        selectedGroupId: cubit.groupId,
        statuses: statuses,
        scrollController: scrollController,
        onApplyFilters:
            ({
              List<int>? statusIds,
              List<int>? priorityIds,
              int? equipmentId,
              int? groupId,
            }) {
              cubit.loadIssues(
                statusIds: statusIds,
                priorityIds: priorityIds,
                equipmentId: equipmentId,
                groupId: groupId,
              );
            },
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
