import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siren_app/core/di/injection.dart';
import 'package:siren_app/core/theme/app_colors.dart';
import 'package:siren_app/features/issues/presentation/cubit/work_package_type_cubit.dart';
import 'package:siren_app/features/issues/presentation/cubit/work_package_type_state.dart';
import '../cubit/server_config_cubit.dart';
import '../cubit/server_config_state.dart';

/// Settings page for modifying server URL configuration
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<ServerConfigCubit>()..loadExistingConfiguration(),
        ),
        // Use BlocProvider.value to use the singleton instance
        // This prevents the cubit from being closed when the page is disposed
        BlocProvider.value(value: getIt<WorkPackageTypeCubit>()..load()),
      ],
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  bool _isEditMode = false;

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  void _enterEditMode(String? currentUrl) {
    setState(() {
      _isEditMode = true;
      _serverUrlController.text = currentUrl ?? '';
    });
  }

  void _cancelEditMode() {
    _serverUrlController.clear();
    context.read<ServerConfigCubit>().loadExistingConfiguration();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: BlocConsumer<ServerConfigCubit, ServerConfigState>(
        listener: (context, state) {
          if (state is ServerConfigSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Configuration saved successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            setState(() => _isEditMode = false);
            context.read<ServerConfigCubit>().loadExistingConfiguration();
          } else if (state is ServerConfigLoaded && _isEditMode) {
            _serverUrlController.clear();
            setState(() => _isEditMode = false);
          } else if (state is ServerConfigError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is ServerConfigInitial) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/config', (route) => false);
          } else if (state is ServerConfigLoggedOut) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logged out successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/config', (route) => false);
          }
        },
        builder: (context, state) {
          if (state is ServerConfigLoading && !_isEditMode) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ServerConfigLoaded && !_isEditMode) {
            return _buildConfigDisplay(context, state);
          }

          if (_isEditMode || state is ServerConfigValidating) {
            return _buildEditForm(context, state);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildConfigDisplay(BuildContext context, ServerConfigLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud, color: AppColors.iconPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Server Configuration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildConfigItem(
                    context,
                    label: 'Server URL',
                    value: state.serverUrl ?? 'Not configured',
                    icon: Icons.link,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildTypeSelectionCard(context),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _enterEditMode(state.serverUrl),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Configuration'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primaryButton,
              foregroundColor: AppColors.buttonText,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showLogoutConfirmation(context),
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            label: const Text(
              'Logout',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppColors.warning,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showClearConfirmation(context),
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.textSecondary,
            ),
            label: const Text(
              'Clear Configuration',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppColors.error,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: AppColors.info.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Changes to server configuration will require restarting '
                      'the app to take effect.',
                      style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildTypeSelectionCard(BuildContext context) {
    return BlocBuilder<WorkPackageTypeCubit, WorkPackageTypeState>(
      builder: (context, state) {
        if (state is WorkPackageTypeLoading ||
            state is WorkPackageTypeInitial ||
            state is WorkPackageTypeSaving) {
          return const LinearProgressIndicator(minHeight: 3);
        }

        if (state is WorkPackageTypeError) {
          return Card(
            color: AppColors.error.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<WorkPackageTypeCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is WorkPackageTypeLoaded) {
          final items = state.availableTypes;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.category_outlined,
                        color: AppColors.iconPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Work Package Type',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: state.selectedType,
                    items: items
                        .map(
                          (type) => DropdownMenuItem(
                            value: type.name,
                            child: Text(type.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<WorkPackageTypeCubit>().selectType(value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildConfigItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.iconSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(BuildContext context, ServerConfigState state) {
    final validationState = state is ServerConfigValidating ? state : null;
    final isLoading = state is ServerConfigLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit Configuration',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _serverUrlController,
              decoration: InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://openproject.example.com',
                prefixIcon: const Icon(Icons.cloud),
                suffixIcon: validationState?.isServerUrlValid == true
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : null,
                errorText: validationState?.serverUrlError,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              enabled: !isLoading,
              onChanged: (value) {
                context.read<ServerConfigCubit>().validateServerUrl(value);
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Server URL is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : _cancelEditMode,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _saveConfiguration,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primaryButton,
                      foregroundColor: AppColors.buttonText,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.buttonText,
                              ),
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveConfiguration() {
    if (_formKey.currentState!.validate()) {
      context.read<ServerConfigCubit>().saveConfiguration(
        serverUrl: _serverUrlController.text.trim(),
      );
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'This will log you out and clear stored authentication tokens from this device.\n\n'
          'Note: If your browser has saved credentials, you may be automatically '
          're-authenticated when you log in again. This is expected OAuth2 behavior.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ServerConfigCubit>().logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Configuration?'),
        content: const Text(
          'This will remove all server configuration. '
          'You will need to reconfigure the app to use it again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ServerConfigCubit>().clearConfiguration();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
