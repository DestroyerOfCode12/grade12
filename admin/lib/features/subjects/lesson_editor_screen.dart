import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../domain/models/subject_models.dart';
import '../../domain/services/content_lifecycle.dart';
import '../../widgets/status_pill.dart';

/// Section 12: "Manage topics and lessons" — editor for one lesson's metadata and its 10-part
/// block structure (section 5). Publishing is blocked in the UI unless
/// [ContentLifecycle.canPublish] passes, mirroring the same rule the mobile app's demo-content
/// badge enforces on the read side (section 2: nothing reaches learners unverified).
class LessonEditorScreen extends ConsumerWidget {
  final String subjectId;
  final String lessonId;
  const LessonEditorScreen({
    super.key,
    required this.subjectId,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(_lessonProvider(lessonId));
    final blocksAsync = ref.watch(_blocksProvider(lessonId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/subjects/$subjectId'),
        ),
        title: lessonAsync.when(
          data: (l) => Text(l.title),
          loading: () => const Text('Loading…'),
          error: (e, _) => const Text('Lesson'),
        ),
      ),
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load lesson: $e')),
        data: (lesson) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _LessonHeader(lesson: lesson),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lesson blocks',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add block'),
                  onPressed: () => _showBlockEditor(
                    context,
                    ref,
                    null,
                    blocksAsync.valueOrNull?.length ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            blocksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load blocks: $e'),
              data: (blocks) => Column(
                children: [
                  for (final b in blocks)
                    Card(
                      child: ListTile(
                        title: Text(b.blockType.replaceAll('_', ' ')),
                        subtitle: Text(
                          b.bodyMarkdown ?? '(empty)',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded),
                              onPressed: () => _showBlockEditor(
                                context,
                                ref,
                                b,
                                b.sortOrder,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () async {
                                await ref
                                    .read(lessonsRepositoryProvider)
                                    .deleteBlock(b.id);
                                ref.invalidate(_blocksProvider(lessonId));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (blocks.isEmpty)
                    const Text(
                      'No blocks yet — add the explanation block first.',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockEditor(
    BuildContext context,
    WidgetRef ref,
    AdminLessonBlock? existing,
    int sortOrder,
  ) {
    final bodyController = TextEditingController(
      text: existing?.bodyMarkdown ?? '',
    );
    String blockType =
        existing?.blockType ?? AdminLessonBlock.allBlockTypes.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Add block' : 'Edit block'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: blockType,
                  decoration: const InputDecoration(labelText: 'Block type'),
                  items: [
                    for (final t in AdminLessonBlock.allBlockTypes)
                      DropdownMenuItem(
                        value: t,
                        child: Text(t.replaceAll('_', ' ')),
                      ),
                  ],
                  onChanged: (v) => setState(() => blockType = v ?? blockType),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bodyController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Body (Markdown)',
                    alignLabelWithHint: true,
                  ),
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
                    .read(lessonsRepositoryProvider)
                    .upsertBlock(
                      blockId: existing?.id,
                      lessonId: lessonId,
                      blockType: blockType,
                      sortOrder: sortOrder,
                      bodyMarkdown: bodyController.text,
                    );
                ref.invalidate(_blocksProvider(lessonId));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

final _lessonProvider = FutureProvider.family(
  (ref, String id) => ref.read(lessonsRepositoryProvider).fetchOne(id),
);
final _blocksProvider = FutureProvider.family(
  (ref, String id) => ref.read(lessonsRepositoryProvider).fetchBlocks(id),
);

class _LessonHeader extends ConsumerWidget {
  final AdminLesson lesson;
  const _LessonHeader({required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = contentStatusFromDb(lesson.contentStatus);
    final nextStates = ContentLifecycle.allowedNextStates(status);
    final canPublish = ContentLifecycle.canPublish(
      isSeedDemoContent: lesson.isSeedDemoContent,
      verificationStatus: lesson.verificationStatus,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusPill(status: lesson.contentStatus),
                const SizedBox(width: 8),
                VerificationPill(status: lesson.verificationStatus),
                if (lesson.isSeedDemoContent) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text('Seed demo content'),
                    avatar: Icon(Icons.science_rounded, size: 16),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final next in nextStates)
                  OutlinedButton(
                    onPressed: (next == ContentStatus.published && !canPublish)
                        ? null
                        : () async {
                            await ref
                                .read(lessonsRepositoryProvider)
                                .updateStatus(
                                  lesson.id,
                                  contentStatus: contentStatusToDb(next),
                                );
                            ref.invalidate(_lessonProvider(lesson.id));
                          },
                    child: Text('Move to ${contentStatusLabel(next)}'),
                  ),
              ],
            ),
            if (nextStates.contains(ContentStatus.published) && !canPublish)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Cannot publish: seed/demo content, or verification_status is not '
                  'verified/source_recorded. Confirm the source and update verification status first.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
