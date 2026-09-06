import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../domain/models/question_models.dart';
import '../../domain/models/subject_models.dart';
import '../../domain/services/content_lifecycle.dart';
import '../../widgets/status_pill.dart';

/// Section 12: subject + CAPS-version management, topic/lesson management, question/quiz
/// creation, all on one screen scoped to a subject — this is the day-to-day workspace a content
/// reviewer lives in.
class SubjectDetailScreen extends ConsumerWidget {
  final String subjectId;
  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectAsync = ref.watch(_subjectProvider(subjectId));
    final topicsAsync = ref.watch(_topicsProvider(subjectId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/subjects'),
        ),
        title: subjectAsync.when(
          data: (s) => Text(s.name),
          loading: () => const Text('Loading…'),
          error: (e, _) => const Text('Subject'),
        ),
      ),
      body: subjectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load subject: $e')),
        data: (subject) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SubjectHeaderCard(subject: subject),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Topics', style: Theme.of(context).textTheme.titleLarge),
                FilledButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New topic'),
                  onPressed: () => _showCreateTopicDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),
            topicsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load topics: $e'),
              data: (topics) {
                if (topics.isEmpty) return const Text('No topics yet.');
                return Column(
                  children: [
                    for (final t in topics)
                      _TopicCard(subjectId: subjectId, topic: t),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTopicDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    String term = 'term_1';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New topic'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: term,
                  decoration: const InputDecoration(labelText: 'Term'),
                  items: const [
                    DropdownMenuItem(value: 'term_1', child: Text('Term 1')),
                    DropdownMenuItem(value: 'term_2', child: Text('Term 2')),
                    DropdownMenuItem(value: 'term_3', child: Text('Term 3')),
                    DropdownMenuItem(value: 'term_4', child: Text('Term 4')),
                    DropdownMenuItem(
                      value: 'cross_term',
                      child: Text('Cross-term'),
                    ),
                  ],
                  onChanged: (v) => setState(() => term = v ?? 'term_1'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(subjectsRepositoryProvider)
                    .createTopic(
                      subjectId: subjectId,
                      title: titleController.text.trim(),
                      term: term,
                    );
                ref.invalidate(_topicsProvider(subjectId));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

final _subjectProvider = FutureProvider.family(
  (ref, String id) => ref.read(subjectsRepositoryProvider).fetchOne(id),
);
final _topicsProvider = FutureProvider.family(
  (ref, String id) => ref.read(subjectsRepositoryProvider).fetchTopics(id),
);

class _SubjectHeaderCard extends ConsumerWidget {
  final AdminSubject subject;
  const _SubjectHeaderCard({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = contentStatusFromDb(subject.contentStatus);
    final nextStates = ContentLifecycle.allowedNextStates(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  subject.code,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                StatusPill(status: subject.contentStatus),
                const SizedBox(width: 8),
                VerificationPill(status: subject.verificationStatus),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final next in nextStates)
                  OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(subjectsRepositoryProvider)
                          .updateStatus(
                            subject.id,
                            contentStatus: contentStatusToDb(next),
                          );
                      ref.invalidate(_subjectProvider(subject.id));
                    },
                    child: Text('Move to ${contentStatusLabel(next)}'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              children: [
                _CoverageToggle(
                  label: 'Papers available',
                  value: subject.papersAvailable,
                  onChanged: (v) async {
                    await ref
                        .read(subjectsRepositoryProvider)
                        .updateCoverageFlags(subject.id, papersAvailable: v);
                    ref.invalidate(_subjectProvider(subject.id));
                  },
                ),
                _CoverageToggle(
                  label: 'Lessons in review',
                  value: subject.lessonsInReview,
                  onChanged: (v) async {
                    await ref
                        .read(subjectsRepositoryProvider)
                        .updateCoverageFlags(subject.id, lessonsInReview: v);
                    ref.invalidate(_subjectProvider(subject.id));
                  },
                ),
                _CoverageToggle(
                  label: 'Full course available',
                  value: subject.fullCourseAvailable,
                  onChanged: (v) async {
                    await ref
                        .read(subjectsRepositoryProvider)
                        .updateCoverageFlags(
                          subject.id,
                          fullCourseAvailable: v,
                        );
                    ref.invalidate(_subjectProvider(subject.id));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverageToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CoverageToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(value: value, onChanged: onChanged),
        Text(label),
      ],
    );
  }
}

class _TopicCard extends ConsumerWidget {
  final String subjectId;
  final AdminTopic topic;
  const _TopicCard({required this.subjectId, required this.topic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(_lessonsProvider(topic.id));
    final questionsAsync = ref.watch(_questionsProvider(topic.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(topic.title),
        subtitle: Row(
          children: [
            Text(
              topic.term.replaceAll('_', ' '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            StatusPill(status: topic.contentStatus),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lessons',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add lesson'),
                      onPressed: () => _showCreateLessonDialog(context, ref),
                    ),
                  ],
                ),
                lessonsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (lessons) => Column(
                    children: [
                      for (final l in lessons)
                        ListTile(
                          dense: true,
                          title: Text(l.title),
                          trailing: StatusPill(status: l.contentStatus),
                          onTap: () => context.go(
                            '/subjects/$subjectId/lessons/${l.id}',
                          ),
                        ),
                      if (lessons.isEmpty) const Text('No lessons yet.'),
                    ],
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Questions',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add question'),
                      onPressed: () => _showCreateQuestionDialog(context, ref),
                    ),
                  ],
                ),
                questionsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (questions) => Column(
                    children: [
                      for (final q in questions)
                        ListTile(
                          dense: true,
                          title: Text(
                            q.promptMarkdown,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(q.kind),
                          trailing: StatusPill(status: q.contentStatus),
                          onTap: () => context.go(
                            '/subjects/$subjectId/questions/${q.id}',
                          ),
                        ),
                      if (questions.isEmpty) const Text('No questions yet.'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateLessonDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New lesson'),
        content: SizedBox(
          width: 380,
          child: TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final id = await ref
                  .read(lessonsRepositoryProvider)
                  .createLesson(
                    topicId: topic.id,
                    title: titleController.text.trim(),
                    estimatedMinutes: 6,
                  );
              ref.invalidate(_lessonsProvider(topic.id));
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/subjects/$subjectId/lessons/$id');
              }
            },
            child: const Text('Create & edit'),
          ),
        ],
      ),
    );
  }

  void _showCreateQuestionDialog(BuildContext context, WidgetRef ref) {
    final promptController = TextEditingController();
    String kind = 'multiple_choice';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New question'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: promptController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Question prompt',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: kind,
                  decoration: const InputDecoration(labelText: 'Kind'),
                  items: [
                    for (final k in AdminQuestion.kinds)
                      DropdownMenuItem(value: k, child: Text(k)),
                  ],
                  onChanged: (v) =>
                      setState(() => kind = v ?? 'multiple_choice'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final id = await ref
                    .read(questionsRepositoryProvider)
                    .createQuestion(
                      topicId: topic.id,
                      kind: kind,
                      promptMarkdown: promptController.text.trim(),
                      difficulty: 2,
                      marks: 1,
                    );
                ref.invalidate(_questionsProvider(topic.id));
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/subjects/$subjectId/questions/$id');
                }
              },
              child: const Text('Create & edit'),
            ),
          ],
        ),
      ),
    );
  }
}

final _lessonsProvider = FutureProvider.family(
  (ref, String topicId) =>
      ref.read(lessonsRepositoryProvider).fetchForTopic(topicId),
);
final _questionsProvider = FutureProvider.family(
  (ref, String topicId) =>
      ref.read(questionsRepositoryProvider).fetchForTopic(topicId),
);
