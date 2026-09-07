import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/demo_content/demo_catalogue.dart';

/// Section 11, screen 5. Section 9 lists what the dashboard must show; this vertical slice
/// implements streak/XP/level, recommended next lesson, upcoming study sessions (screen 20), and
/// a papers shortcut. Weak topics, per-subject progress, and downloaded-content status are Phase
/// 4 items once mastery_scores has real signed-in data flowing into them (docs/CONTINUATION.md).
class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final outcome = ref
        .read(gamificationRepositoryProvider)
        .currentState(userId);
    final upcomingAsync = ref.watch(_upcomingPreviewProvider);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming study sessions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () => context.go('/planner'),
                child: const Text('View planner'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          upcomingAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Text('Could not load your plan: $e'),
            data: (sessions) {
              if (sessions.isEmpty) {
                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('No study plan yet'),
                    subtitle: const Text(
                      'Get a personalised schedule based on your subjects.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go('/planner'),
                  ),
                );
              }
              return Column(
                children: [
                  for (final session in sessions.take(3))
                    Card(
                      child: ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.event_note_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(session.topicTitle),
                        subtitle: Text(
                          '${DateFormat('EEE, d MMM').format(session.scheduledFor)} · ${session.durationMinutes} min',
                        ),
                        onTap: () => context.go('/planner'),
                      ),
                    ),
                ],
              );
            },
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

final _upcomingPreviewProvider = FutureProvider(
  (ref) => ref.read(studyPlanRepositoryProvider).fetchUpcoming(),
);
