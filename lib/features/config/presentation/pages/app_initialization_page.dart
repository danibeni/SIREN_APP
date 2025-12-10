import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siren_app/core/di/injection.dart';
import 'package:siren_app/core/theme/app_colors.dart';
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
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/siren_icon_mdpi.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 24),
                const Text(
                  'SIREN',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'System for Issue Reporting\nand Engineering Notification',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: AppColors.primaryBlue),
                const SizedBox(height: 16),
                const Text(
                  'Initializing...',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
