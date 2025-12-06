import 'package:flutter/material.dart';
import 'package:siren_app/core/theme/app_colors.dart';
import 'package:siren_app/core/theme/status_colors.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.label,
    this.colorHex,
  });

  final IssueStatus status;
  final String? label;
  final String? colorHex;

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();
    final text = label ?? StatusColors.getText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.buttonText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _resolveColor() {
    if (colorHex != null && colorHex!.isNotEmpty) {
      final normalized = colorHex!.replaceFirst('#', '');
      final value = int.tryParse('FF$normalized', radix: 16);
      if (value != null) {
        return Color(value);
      }
    }
    return StatusColors.getColor(status);
  }
}
