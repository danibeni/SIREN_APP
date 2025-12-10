import 'package:flutter/material.dart';
import 'package:siren_app/core/di/injection.dart';
import 'package:siren_app/core/theme/app_colors.dart';
import 'package:siren_app/core/theme/priority_colors.dart';
import 'package:siren_app/features/issues/data/datasources/issue_remote_datasource.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/entities/status_entity.dart';

class IssueFilterSheet extends StatefulWidget {
  const IssueFilterSheet({
    super.key,
    required this.selectedStatusIds,
    required this.selectedPriorityIds,
    required this.selectedEquipmentId,
    required this.selectedGroupId,
    required this.statuses,
    required this.onApplyFilters,
    this.scrollController,
  });

  final List<int>? selectedStatusIds;
  final List<int>? selectedPriorityIds;
  final int? selectedEquipmentId;
  final int? selectedGroupId;
  final List<StatusEntity> statuses;
  final ScrollController? scrollController;
  final void Function({
    List<int>? statusIds,
    List<int>? priorityIds,
    int? equipmentId,
    int? groupId,
  })
  onApplyFilters;

  @override
  State<IssueFilterSheet> createState() => _IssueFilterSheetState();
}

class _IssueFilterSheetState extends State<IssueFilterSheet> {
  late List<int> _selectedStatusIds;
  late List<int> _selectedPriorityIds;
  int? _selectedEquipmentId;
  int? _selectedGroupId;

  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _priorities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedStatusIds = List.from(widget.selectedStatusIds ?? []);
    _selectedPriorityIds = List.from(widget.selectedPriorityIds ?? []);
    _selectedEquipmentId = widget.selectedEquipmentId;
    _selectedGroupId = widget.selectedGroupId;
    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    setState(() => _isLoading = true);
    try {
      final dataSource = getIt<IssueRemoteDataSource>();
      final groups = await dataSource.getGroups();
      final priorities = await dataSource.getPriorities();
      List<Map<String, dynamic>> projects = [];
      if (groups.isNotEmpty && _selectedGroupId != null) {
        projects = await dataSource.getProjectsByGroup(_selectedGroupId!);
      }

      setState(() {
        _groups = groups;
        _priorities = priorities;
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load filter options: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _toggleStatus(int statusId) {
    setState(() {
      if (_selectedStatusIds.contains(statusId)) {
        _selectedStatusIds.remove(statusId);
      } else {
        _selectedStatusIds.add(statusId);
      }
    });
  }

  void _togglePriority(int priorityId) {
    setState(() {
      if (_selectedPriorityIds.contains(priorityId)) {
        _selectedPriorityIds.remove(priorityId);
      } else {
        _selectedPriorityIds.add(priorityId);
      }
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(
      statusIds: _selectedStatusIds.isEmpty ? null : _selectedStatusIds,
      priorityIds: _selectedPriorityIds.isEmpty ? null : _selectedPriorityIds,
      equipmentId: _selectedEquipmentId,
      groupId: _selectedGroupId,
    );
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _selectedStatusIds.clear();
      _selectedPriorityIds.clear();
      _selectedEquipmentId = null;
      _selectedGroupId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Issues',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusSection(widget.statuses),
                    const SizedBox(height: 24),
                    _buildPrioritySection(),
                    const SizedBox(height: 24),
                    _buildGroupSection(),
                    const SizedBox(height: 24),
                    _buildEquipmentSection(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: AppColors.buttonText,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(List<StatusEntity> statuses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statuses.map((status) {
            final isSelected = _selectedStatusIds.contains(status.id);
            return FilterChip(
              selected: isSelected,
              label: Text(status.name),
              onSelected: (_) => _toggleStatus(status.id),
              selectedColor: status.colorHex != null
                  ? Color(
                      int.parse(status.colorHex!.replaceFirst('#', '0xFF')),
                    ).withValues(alpha: 0.2)
                  : AppColors.primaryPurple.withValues(alpha: 0.2),
              checkmarkColor: status.colorHex != null
                  ? Color(int.parse(status.colorHex!.replaceFirst('#', '0xFF')))
                  : AppColors.primaryPurple,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _priorities.map((priority) {
            final priorityId = priority['id'] as int?;
            final priorityName = priority['name'] as String? ?? '';
            if (priorityId == null) return const SizedBox.shrink();

            final isSelected = _selectedPriorityIds.contains(priorityId);
            return FilterChip(
              selected: isSelected,
              label: Text(priorityName),
              onSelected: (_) => _togglePriority(priorityId),
              selectedColor: PriorityColors.getColor(
                _mapPriorityNameToLevel(priorityName),
              ).withValues(alpha: 0.2),
              checkmarkColor: PriorityColors.getColor(
                _mapPriorityNameToLevel(priorityName),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGroupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Group',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (_groups.isEmpty)
          const Text(
            'No groups available',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _groups.map((group) {
              final groupId = group['id'] as int?;
              final groupName = group['name'] as String? ?? '';
              if (groupId == null) return const SizedBox.shrink();

              final isSelected = _selectedGroupId == groupId;
              return ChoiceChip(
                selected: isSelected,
                label: Text(groupName),
                onSelected: (selected) {
                  setState(() {
                    _selectedGroupId = selected ? groupId : null;
                    if (selected) {
                      _loadProjectsForGroup(groupId);
                    } else {
                      _selectedEquipmentId = null;
                      _projects = [];
                    }
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildEquipmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Equipment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedGroupId == null)
          const Text(
            'Select a group first',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else if (_projects.isEmpty)
          const Text(
            'No equipment available for selected group',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _projects.map((project) {
              final projectId = project['id'] as int?;
              final projectName = project['name'] as String? ?? '';
              if (projectId == null) return const SizedBox.shrink();

              final isSelected = _selectedEquipmentId == projectId;
              return ChoiceChip(
                selected: isSelected,
                label: Text(projectName),
                onSelected: (selected) {
                  setState(() {
                    _selectedEquipmentId = selected ? projectId : null;
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _loadProjectsForGroup(int groupId) async {
    try {
      final dataSource = getIt<IssueRemoteDataSource>();
      final projects = await dataSource.getProjectsByGroup(groupId);
      setState(() {
        _projects = projects;
        _selectedEquipmentId = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load equipment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  PriorityLevel _mapPriorityNameToLevel(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('low')) return PriorityLevel.low;
    if (lowerName.contains('normal')) return PriorityLevel.normal;
    if (lowerName.contains('high')) return PriorityLevel.high;
    if (lowerName.contains('immediate')) return PriorityLevel.immediate;
    return PriorityLevel.normal;
  }
}
