import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../domain/models/governance_models.dart';

/// Section 12: "View user content reports" / "Correct inaccurate content" — what a learner
/// submits via the mobile app's "Report a content issue" screen lands here.
class ContentReportsScreen extends ConsumerWidget {
  const ContentReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(_reportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Content reports')),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load reports: $e')),
        data: (reports) {
          if (reports.isEmpty) return const Center(child: Text('No reports.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, i) => _ReportCard(report: reports[i]),
          );
        },
      ),
    );
  }
}

final _reportsProvider = FutureProvider(
  (ref) => ref.read(contentReportsRepositoryProvider).fetchAll(),
);

class _ReportCard extends ConsumerWidget {
  final ContentReport report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text(report.status)),
                const SizedBox(width: 8),
                Text(
                  '${report.entityType} · ${report.entityId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  DateFormat.yMMMd().format(report.createdAt.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              report.reason,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (report.details != null) Text(report.details!),
            if (report.status == 'open' || report.status == 'reviewing')
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(contentReportsRepositoryProvider)
                            .setStatus(report.id, 'reviewing');
                        ref.invalidate(_reportsProvider);
                      },
                      child: const Text('Mark reviewing'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(contentReportsRepositoryProvider)
                            .setStatus(report.id, 'actioned');
                        ref.invalidate(_reportsProvider);
                      },
                      child: const Text('Mark actioned'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(contentReportsRepositoryProvider)
                            .setStatus(report.id, 'dismissed');
                        ref.invalidate(_reportsProvider);
                      },
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
