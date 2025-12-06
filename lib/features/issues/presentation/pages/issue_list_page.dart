import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siren_app/core/di/injection.dart';
import 'package:siren_app/core/theme/app_colors.dart';
import 'package:siren_app/features/issues/presentation/cubit/issues_list_cubit.dart';
import 'package:siren_app/features/issues/presentation/cubit/issues_list_state.dart';
import 'package:siren_app/features/issues/presentation/cubit/work_package_type_cubit.dart';
import 'package:siren_app/features/issues/presentation/cubit/work_package_type_state.dart';
import 'package:siren_app/features/issues/presentation/widgets/issue_card.dart';

class IssueListPage extends StatelessWidget {
  const IssueListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<IssuesListCubit>()..loadIssues()),
        BlocProvider(create: (_) => getIt<WorkPackageTypeCubit>()..load()),
      ],
      child: const _IssueListView(),
    );
  }
}

class _IssueListView extends StatelessWidget {
  const _IssueListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<IssuesListCubit>().refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.of(context).pushNamed('/settings');
              // Reload type when returning from settings
              if (context.mounted) {
                context.read<WorkPackageTypeCubit>().load();
                context.read<IssuesListCubit>().refresh();
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
      body: Column(
        children: [
          _TypeBanner(),
          Expanded(
            child: BlocBuilder<IssuesListCubit, IssuesListState>(
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
                if (state is IssuesListLoaded ||
                    state is IssuesListRefreshing) {
                  final issues = state is IssuesListLoaded
                      ? state.issues
                      : (state as IssuesListRefreshing).issues;
                  final typeState = context.watch<WorkPackageTypeCubit>().state;
                  final statusColorByName = _statusColorMap(typeState);

                  if (issues.isEmpty) {
                    return const _EmptyView();
                  }

                  return RefreshIndicator(
                    onRefresh: () => context.read<IssuesListCubit>().refresh(),
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
                          onTap: () {
                            // Detail view will be added later
                          },
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
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

class _TypeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkPackageTypeCubit, WorkPackageTypeState>(
      builder: (context, state) {
        if (state is WorkPackageTypeLoading ||
            state is WorkPackageTypeInitial) {
          return const LinearProgressIndicator(minHeight: 3);
        }

        if (state is WorkPackageTypeLoaded) {
          return Container(
            width: double.infinity,
            color: AppColors.info.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.category_outlined,
                  size: 18,
                  color: AppColors.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Type: ${state.selectedType}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/settings'),
                  child: const Text('Change'),
                ),
              ],
            ),
          );
        }

        if (state is WorkPackageTypeError) {
          return Container(
            width: double.infinity,
            color: AppColors.error.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
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
