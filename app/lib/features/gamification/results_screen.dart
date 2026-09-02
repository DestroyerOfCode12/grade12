import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/gamification_repository.dart';

/// Section 11, screen 18 (results). Shows XP earned this session, running total, level, and
/// streak — deliberately calls out that mastery/readiness figures (elsewhere in the app) are
/// estimates, never predicted final results (section 9).
class ResultsScreen extends StatelessWidget {
  final Object? outcome;
  const ResultsScreen({super.key, this.outcome});

  @override
  Widget build(BuildContext context) {
    final result = outcome is GamificationOutcome
        ? outcome as GamificationOutcome
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.stars_rounded, size: 72, color: AppColors.secondary),
              const SizedBox(height: 16),
              if (result != null) ...[
                Text(
                  '+${result.xpAwarded} XP',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text('Total: ${result.totalXp} XP · Level ${result.level}'),
                const SizedBox(height: 4),
                Text('🔥 ${result.currentStreakDays}-day streak'),
              ] else
                const Text('Nice work!'),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
