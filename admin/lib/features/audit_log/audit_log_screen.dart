import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';

/// Section 14: append-only audit log, admin-only. RLS (`audit_log_admin_read`) filters this to an
/// empty list for a content_reviewer even if they reach the URL directly — the nav item is hidden
/// too, but the real boundary is server-side.
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(_auditLogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load audit log: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'No audit entries yet (or your role cannot view this — admin only).',
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('When')),
                  DataColumn(label: Text('Actor')),
                  DataColumn(label: Text('Action')),
                  DataColumn(label: Text('Entity')),
                ],
                rows: [
                  for (final e in entries)
                    DataRow(
                      cells: [
                        DataCell(
                          Text(
                            DateFormat.yMMMd().add_jm().format(
                              e.createdAt.toLocal(),
                            ),
                          ),
                        ),
                        DataCell(Text(e.actorRole ?? e.actorId ?? '—')),
                        DataCell(Text(e.action)),
                        DataCell(
                          Text(
                            e.entityType == null
                                ? '—'
                                : '${e.entityType}:${e.entityId}',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

final _auditLogProvider = FutureProvider(
  (ref) => ref.read(auditLogRepositoryProvider).fetchRecent(),
);
