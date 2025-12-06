import 'package:flutter/material.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

/// Status color constants for consistent color coding across the app.
///
/// These colors are used in:
/// - Status badges in issue listing components (Story 4)
/// - Status indicators in issue form (Story 3)
/// - Any other status visualization components
///
/// Color scheme:
/// - New: Indigo (añil) - fresh, awaiting action
/// - In Progress: Light violet - active work
/// - On Hold: Light orange - paused/waiting
/// - Closed: Grey - completed/inactive
/// - Rejected: Pale red - declined/not approved
class StatusColors {
  const StatusColors._();

  /// New status color - Indigo (añil).
  static const Color newStatus = Color(0xFF5C6BC0);

  /// In Progress status color - Light violet.
  static const Color inProgress = Color(0xFF9575CD);

  /// On Hold status color - Light orange.
  static const Color onHold = Color(0xFFFFB74D);

  /// Closed status color - Grey.
  static const Color closed = Color(0xFF757575);

  /// Rejected status color - Pale red.
  static const Color rejected = Color(0xFFE57373);

  /// Get color for an issue status.
  static Color getColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.newStatus:
        return newStatus;
      case IssueStatus.inProgress:
        return inProgress;
      case IssueStatus.onHold:
        return onHold;
      case IssueStatus.closed:
        return closed;
      case IssueStatus.rejected:
        return rejected;
    }
  }

  /// Get display text for an issue status.
  static String getText(IssueStatus status) {
    switch (status) {
      case IssueStatus.newStatus:
        return 'New';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.onHold:
        return 'On Hold';
      case IssueStatus.closed:
        return 'Closed';
      case IssueStatus.rejected:
        return 'Rejected';
    }
  }
}
