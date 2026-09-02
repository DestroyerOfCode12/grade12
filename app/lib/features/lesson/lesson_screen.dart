import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/utils/idempotency.dart';
import '../../data/demo_content/demo_catalogue.dart';
import '../../domain/models/lesson.dart';
import '../../domain/services/mastery_calculator.dart';
import '../../widgets/demo_content_badge.dart';

/// Section 11, screen 9. Renders the 10-part lesson structure from section 5 generically off
/// `lesson.blocks`, with a toggle for "Explain it even more simply." Completing the lesson awards
/// XP (idempotent, section 13) and offers the checkpoint quiz.
class LessonScreen extends ConsumerStatefulWidget {
  final String lessonId;
  const LessonScreen({super.key, required this.lessonId});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _showSimpler = false;
  bool _completed = false;
  final _completionIdempotencyKey = IdempotencyKeys.generate();

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(_lessonProvider(widget.lessonId));

    return Scaffold(
      appBar: AppBar(title: const Text('Lesson')),
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load lesson: $e')),
        data: (lesson) {
          if (lesson == null) {
            return const Center(child: Text('Lesson not found.'));
          }
          return _buildLesson(context, lesson);
        },
      ),
    );
  }

  Widget _buildLesson(BuildContext context, Lesson lesson) {
    final blocksByType = {for (final b in lesson.blocks) b.type: b};
    final simpler = blocksByType[LessonBlockType.simplerExplanation];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                lesson.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        if (lesson.isSeedDemoContent) ...[
          const SizedBox(height: 8),
          const DemoContentBadge(),
        ],
        const SizedBox(height: 16),
        for (final block in lesson.blocks)
          if (block.type != LessonBlockType.simplerExplanation)
            _blockCard(context, block, lesson, simpler),
        const SizedBox(height: 24),
        if (!_completed)
          FilledButton.icon(
            icon: const Icon(Icons.check_rounded),
            label: const Text('Mark lesson complete'),
            onPressed: () => _completeLesson(lesson),
          )
        else
          FilledButton.icon(
            icon: const Icon(Icons.quiz_rounded),
            label: const Text('Take the checkpoint quiz'),
            onPressed: () =>
                context.go('/learn/quiz/${DemoCatalogue.checkpointQuizId}'),
          ),
      ],
    );
  }

  Widget _blockCard(
    BuildContext context,
    LessonBlock block,
    Lesson lesson,
    LessonBlock? simpler,
  ) {
    if (block.bodyMarkdown == null || block.bodyMarkdown!.isEmpty) {
      return const SizedBox.shrink();
    }

    final title = switch (block.type) {
      LessonBlockType.explanation => 'Explanation',
      LessonBlockType.localExample => 'A South African example',
      LessonBlockType.definitionOrFormula => 'Key definitions & formulas',
      LessonBlockType.workedExample => 'Worked example',
      LessonBlockType.commonMistakes => 'Common mistakes',
      LessonBlockType.citation => 'Source',
      _ => null,
    };
    if (title == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _showSimpler &&
                      simpler != null &&
                      block.type == LessonBlockType.explanation
                  ? simpler.bodyMarkdown!
                  : block.bodyMarkdown!,
            ),
            if (block.type == LessonBlockType.explanation &&
                simpler != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                icon: Icon(
                  _showSimpler
                      ? Icons.undo_rounded
                      : Icons.lightbulb_outline_rounded,
                ),
                label: Text(
                  _showSimpler
                      ? 'Show original explanation'
                      : 'Explain it even more simply',
                ),
                onPressed: () => setState(() => _showSimpler = !_showSimpler),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _completeLesson(Lesson lesson) async {
    final repo = ref.read(gamificationRepositoryProvider);
    final outcome = await repo.awardXp(
      profileId: ref.read(currentUserIdProvider),
      amount: XpRules.lessonCompleted,
      reason: 'lesson_completed',
      sourceEntityType: 'lesson',
      sourceEntityId: lesson.id,
      idempotencyKey: _completionIdempotencyKey,
    );
    if (!mounted) return;
    setState(() => _completed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '+${outcome.xpAwarded} XP — total ${outcome.totalXp} XP (Level ${outcome.level})',
        ),
      ),
    );
  }
}

final _lessonProvider = FutureProvider.family(
  (ref, String lessonId) =>
      ref.read(lessonRepositoryProvider).fetchLesson(lessonId),
);
