import 'package:flutter/material.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

/// Priority color constants for consistent color coding across the app.
///
/// These colors are used in:
/// - Priority circles in issue listing components (Story 4)
/// - Priority segmented buttons in issue form (Story 3)
/// - Any other priority visualization components
class PriorityColors {
  const PriorityColors._();

  /// Low priority color.
  static const Color low = Color(0xFF81D4FA); // Light blue

  /// Normal/Medium priority color.
  static const Color normal = Color(0xFF42A5F5); // Blue

  /// High priority color.
  static const Color high = Color(0xFFFF9800); // Orange

  /// Immediate priority color.
  static const Color immediate = Color(0xFF9C27B0); // Purple

  /// Get color for a priority level.
  static Color getColor(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.low:
        return low;
      case PriorityLevel.normal:
        return normal;
      case PriorityLevel.high:
        return high;
      case PriorityLevel.immediate:
        return immediate;
    }
  }
}
