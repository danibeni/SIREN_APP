import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siren_app/core/di/injection.dart';
import '../cubit/app_initialization_cubit.dart';
import '../cubit/app_initialization_state.dart';

/// Page that checks configuration and redirects accordingly
class AppInitializationPage extends StatelessWidget {
  const AppInitializationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AppInitializationCubit>()..checkConfiguration(),
      child: BlocListener<AppInitializationCubit, AppInitializationState>(
        listener: (context, state) {
          if (state is AppInitializationConfigured) {
            Navigator.of(context).pushReplacementNamed('/home');
          } else if (state is AppInitializationNotConfigured) {
            Navigator.of(context).pushReplacementNamed('/config');
          }
        },
        child: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.settings_remote,
                  size: 80,
                  color: Colors.deepOrange,
                ),
                SizedBox(height: 24),
                Text(
                  'SIREN',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'System for Issue Reporting\nand Engineering Notification',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 32),
                CircularProgressIndicator(
                  color: Colors.deepOrange,
                ),
                SizedBox(height: 16),
                Text(
                  'Initializing...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

