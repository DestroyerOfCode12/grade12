import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/demo_content/demo_catalogue.dart';

/// Section 11, screen 5. Section 9 lists what the dashboard must show; this vertical slice
/// implements streak/XP/level, recommended next lesson, and a papers shortcut. Weak topics,
/// upcoming study sessions, per-subject progress, and downloaded-content status are Phase 4
/// items once mastery_scores/study_plans have real data flowing into them (docs/CONTINUATION.md).
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final outcome = ref
        .read(gamificationRepositoryProvider)
        .currentState(userId);

    return Scaffold(
      appBar: AppBar(title: const Text('MatricQuest SA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _statChip(
                context,
                Icons.local_fire_department_rounded,
                '${outcome.currentStreakDays}',
                'day streak',
                AppColors.secondary,
              ),
              const SizedBox(width: 12),
              _statChip(
                context,
                Icons.bolt_rounded,
                '${outcome.totalXp}',
                'XP',
                AppColors.primary,
              ),
              const SizedBox(width: 12),
              _statChip(
                context,
                Icons.emoji_events_rounded,
                '${outcome.level}',
                'level',
                AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Recommended next lesson',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.play_circle_fill_rounded,
                size: 36,
                color: AppColors.primary,
              ),
              title: const Text('Understanding Linear Functions'),
              subtitle: const Text(
                'Mathematics · Functions and Graphs · ~6 min',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go(
                '/learn/lesson/${DemoCatalogue.linearFunctionsLessonId}',
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Study shortcuts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Learn'),
                  onPressed: () => context.go('/learn'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.description_rounded),
                  label: const Text('Papers'),
                  onPressed: () => context.go('/papers'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
