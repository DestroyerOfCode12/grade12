import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/demo_content/demo_catalogue.dart';
import '../../domain/models/study_session.dart';

/// Section 11, screen 20 ("Study planner and calendar") / section 9 ("Generate a study plan...").
/// Every session on the list traces back to a topic's mastery estimate via
/// [StudyPlanGenerator] — see that class's doc comment for exactly which section-9 inputs are
/// modelled today vs. still a pass-through (docs/CONTINUATION.md has the same summary).
class StudyPlannerScreen extends ConsumerStatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  ConsumerState<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends ConsumerState<StudyPlannerScreen> {
  int _dailyMinutes = 30;
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(_upcomingSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Regenerate plan',
            onPressed: _generating ? null : _showGenerateSheet,
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load your plan: $e')),
        data: (sessions) {
          if (sessions.isEmpty) return _emptyState(context);
          return _sessionList(context, sessions);
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No study plan yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'We\'ll schedule short review sessions for your subjects, focusing more often on '
              'topics you\'re still building up.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Generate my study plan'),
              onPressed: _generating ? null : _showGenerateSheet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionList(BuildContext context, List<PlannedSession> sessions) {
    final byDate = <DateTime, List<PlannedSession>>{};
    for (final s in sessions) {
      byDate.putIfAbsent(s.scheduledFor, () => []).add(s);
    }
    final dates = byDate.keys.toList()..sort();
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final date in dates) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              date == todayDateOnly
                  ? 'Today'
                  : DateFormat('EEEE, d MMMM').format(date),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          for (final session in byDate[date]!) _sessionCard(session),
        ],
      ],
    );
  }

  Widget _sessionCard(PlannedSession session) {
    final icon = switch (session.sessionKind) {
      'lesson' => Icons.play_circle_fill_rounded,
      'spaced_repetition' => Icons.replay_circle_filled_rounded,
      'past_paper' => Icons.description_rounded,
      _ => Icons.style_rounded,
    };
    final canOpenLesson =
        session.topicId == DemoCatalogue.functionsTopicId &&
        session.sessionKind == 'lesson';

    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(session.topicTitle),
        subtitle: Text(
          '${session.durationMinutes} min · ${session.sessionKind.replaceAll('_', ' ')}',
        ),
        onTap: canOpenLesson
            ? () => context.go(
                '/learn/lesson/${DemoCatalogue.linearFunctionsLessonId}',
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded),
              tooltip: 'Mark done',
              color: AppColors.success,
              onPressed: () =>
                  _updateStatus(session.id, StudySessionStatus.completed),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Skip',
              onPressed: () =>
                  _updateStatus(session.id, StudySessionStatus.skipped),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
    String sessionId,
    StudySessionStatus status,
  ) async {
    await ref.read(studyPlanRepositoryProvider).markStatus(sessionId, status);
    ref.invalidate(_upcomingSessionsProvider);
  }

  void _showGenerateSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generate study plan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text('Minutes per day: $_dailyMinutes'),
              Slider(
                value: _dailyMinutes.toDouble(),
                min: 10,
                max: 120,
                divisions: 11,
                label: '$_dailyMinutes min',
                onChanged: (v) =>
                    setSheetState(() => _dailyMinutes = v.round()),
              ),
              const SizedBox(height: 8),
              const Text(
                'Covers the next 14 days. Weaker topics come up more often — that adjusts '
                'automatically as your mastery improves.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _generate();
                },
                child: const Text('Generate'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final selected = ref.read(selectedSubjectIdsProvider);
      await ref
          .read(studyPlanRepositoryProvider)
          .generatePlan(
            selectedSubjectIds: selected,
            horizonDays: 14,
            dailyMinutes: _dailyMinutes,
          );
      ref.invalidate(_upcomingSessionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Study plan generated.')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}

final _upcomingSessionsProvider = FutureProvider(
  (ref) => ref.read(studyPlanRepositoryProvider).fetchUpcoming(),
);
