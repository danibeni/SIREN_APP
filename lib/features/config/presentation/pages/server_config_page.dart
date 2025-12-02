import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siren_app/core/di/injection.dart';
import '../cubit/server_config_cubit.dart';
import '../cubit/server_config_state.dart';

/// Initial server configuration page
///
/// Prompts users to enter OpenProject server URL
/// on first-time setup with optimized UX for mobile devices.
class ServerConfigPage extends StatelessWidget {
  const ServerConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ServerConfigCubit>(),
      child: const _ServerConfigView(),
    );
  }
}

class _ServerConfigView extends StatefulWidget {
  const _ServerConfigView();

  @override
  State<_ServerConfigView> createState() => _ServerConfigViewState();
}

class _ServerConfigViewState extends State<_ServerConfigView> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _clientIdController = TextEditingController();

  @override
  void dispose() {
    _serverUrlController.dispose();
    _clientIdController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load existing configuration if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServerConfigCubit>().loadExistingConfiguration();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Configuration'),
        elevation: 0,
      ),
      body: BlocConsumer<ServerConfigCubit, ServerConfigState>(
        listener: (context, state) {
          if (state is ServerConfigLoaded) {
            // Pre-fill server URL if configuration exists
            if (state.serverUrl != null && _serverUrlController.text.isEmpty) {
              _serverUrlController.text = state.serverUrl!;
            }
          } else if (state is ServerConfigSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Configuration saved: ${state.serverUrl}'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is ServerConfigAuthenticationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication successful!'),
                backgroundColor: Colors.green,
              ),
            );
            // Clear navigation stack and go to home
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          } else if (state is ServerConfigError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ServerConfigLoading || 
                           state is ServerConfigAuthenticating;
          final isConfigSaved = state is ServerConfigSuccess || 
                               (state is ServerConfigLoaded && state.serverUrl != null);
          final validationState = state is ServerConfigValidating ? state : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Icon(
                    Icons.settings_remote,
                    size: 80,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to SIREN',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure your OpenProject server connection',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Server URL Field
                  TextFormField(
                    controller: _serverUrlController,
                    decoration: InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'https://openproject.example.com',
                      prefixIcon: const Icon(Icons.cloud),
                      suffixIcon: validationState?.isServerUrlValid == true
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      helperText: 'Enter your OpenProject server base URL',
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
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _clientIdController,
                    decoration: const InputDecoration(
                      labelText: 'OAuth2 Client ID',
                      hintText: 'Enter your OpenProject OAuth2 Client ID',
                      prefixIcon: Icon(Icons.vpn_key),
                      helperText: 'Required for OAuth2 authentication',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Client ID is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  if (!isConfigSaved) ...[
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context.read<ServerConfigCubit>().saveConfiguration(
                                      serverUrl: _serverUrlController.text.trim(),
                                    );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Configuration',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context.read<ServerConfigCubit>().authenticate(
                                      serverUrl: _serverUrlController.text.trim(),
                                      clientId: _clientIdController.text.trim(),
                                    );
                              }
                            },
                      icon: const Icon(Icons.login),
                      label: const Text(
                        'Authenticate',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context.read<ServerConfigCubit>().saveConfiguration(
                                      serverUrl: _serverUrlController.text.trim(),
                                    );
                              }
                            },
                      child: const Text('Update Configuration'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

