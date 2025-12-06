import 'package:flutter/material.dart';
import 'package:siren_app/core/theme/priority_colors.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

class PriorityCircle extends StatelessWidget {
  const PriorityCircle({super.key, required this.priority, this.size = 16});

  final PriorityLevel priority;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: PriorityColors.getColor(priority),
        shape: BoxShape.circle,
      ),
    );
  }
}
