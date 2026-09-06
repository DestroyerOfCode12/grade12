import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../domain/services/content_lifecycle.dart';

/// Renders any `content_status` value with colour + icon + text — never colour alone (same
/// accessibility rule as the learner app).
class StatusPill extends StatelessWidget {
  final String status;
  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = StatusStyle.colorFor(status);
    final label = contentStatusLabel(contentStatusFromDb(status));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(StatusStyle.iconFor(status), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Same pill styling for `verification_status`, which uses a different value set.
class VerificationPill extends StatelessWidget {
  final String status;
  const VerificationPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      'verified' => (AppColors.success, 'Verified', Icons.verified_rounded),
      'source_recorded' => (Colors.blue, 'Source recorded', Icons.link_rounded),
      'pending_manual_review' => (
        AppColors.warning,
        'Pending review',
        Icons.hourglass_top_rounded,
      ),
      'disputed' => (AppColors.error, 'Disputed', Icons.report_problem_rounded),
      _ => (Colors.grey, 'Unverified', Icons.help_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
