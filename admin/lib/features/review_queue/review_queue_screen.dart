import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../domain/models/governance_models.dart';

/// Section 2/12: the manual review queue every imported/AI-generated piece of content lands in
/// before it can be published. This is the operational heart of "no one can publish merely
/// because they can generate it."
class ReviewQueueScreen extends ConsumerWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(_reviewTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Review queue')),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load review queue: $e')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text('Nothing waiting for review. 🎉'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) =>
                _ReviewTaskCard(task: tasks[index]),
          );
        },
      ),
    );
  }
}

final _reviewTasksProvider = FutureProvider(
  (ref) => ref.read(reviewRepositoryProvider).fetchOpen(),
);

class _ReviewTaskCard extends ConsumerWidget {
  final ReviewTask task;
  const _ReviewTaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityColor = switch (task.priority) {
      >= 4 => Colors.red,
      3 => Colors.orange,
      _ => Colors.blueGrey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: priorityColor.withValues(alpha: 0.15),
              child: Text(
                '${task.priority}',
                style: TextStyle(color: priorityColor, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${task.entityType} · ${task.reason.replaceAll('_', ' ')}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Entity: ${task.entityId}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    DateFormat.yMMMd().add_jm().format(
                      task.createdAt.toLocal(),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (task.status == 'open')
              TextButton(
                onPressed: () async {
                  final userId = ref.read(currentUserIdProvider);
                  if (userId == null) return;
                  await ref
                      .read(reviewRepositoryProvider)
                      .assignToSelf(task.id, userId);
                  ref.invalidate(_reviewTasksProvider);
                },
                child: const Text('Take'),
              ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(reviewRepositoryProvider)
                    .setStatus(task.id, 'resolved');
                ref.invalidate(_reviewTasksProvider);
              },
              child: const Text('Resolve'),
            ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(reviewRepositoryProvider)
                    .setStatus(task.id, 'dismissed');
                ref.invalidate(_reviewTasksProvider);
              },
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }
}
