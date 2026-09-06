import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../widgets/status_pill.dart';

/// Section 12: "Import past papers and memorandums" / section 7's ingestion pipeline entry point.
class PapersScreen extends ConsumerWidget {
  const PapersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = ref.watch(_papersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past papers'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('New paper record'),
              onPressed: () => _showCreateDialog(context, ref),
            ),
          ),
        ],
      ),
      body: papersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load papers: $e')),
        data: (papers) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Title')),
                DataColumn(label: Text('Year')),
                DataColumn(label: Text('Session')),
                DataColumn(label: Text('Paper')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Association')),
              ],
              rows: [
                for (final p in papers)
                  DataRow(
                    onSelectChanged: (_) => context.go('/papers/${p.id}'),
                    cells: [
                      DataCell(Text(p.title)),
                      DataCell(Text('${p.examYear}')),
                      DataCell(Text(p.session.replaceAll('_', '/'))),
                      DataCell(Text('${p.paperNumber}')),
                      DataCell(StatusPill(status: p.contentStatus)),
                      DataCell(Text(p.associationConfidence)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final subjectIdController = TextEditingController();
    final titleController = TextEditingController();
    final sourceUrlController = TextEditingController();
    final yearController = TextEditingController(
      text: '${DateTime.now().year}',
    );
    String session = 'may_june';
    int paperNumber = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New paper record'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectIdController,
                  decoration: const InputDecoration(
                    labelText: 'Subject ID (copy from the Subjects screen)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: sourceUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Source URL (official DBE page)',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: yearController,
                        decoration: const InputDecoration(labelText: 'Year'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: paperNumber,
                        decoration: const InputDecoration(labelText: 'Paper #'),
                        items: [1, 2, 3]
                            .map(
                              (n) =>
                                  DropdownMenuItem(value: n, child: Text('$n')),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => paperNumber = v ?? 1),
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: session,
                  decoration: const InputDecoration(labelText: 'Session'),
                  items: const [
                    DropdownMenuItem(
                      value: 'may_june',
                      child: Text('May/June'),
                    ),
                    DropdownMenuItem(
                      value: 'october_november',
                      child: Text('October/November'),
                    ),
                    DropdownMenuItem(
                      value: 'february_march',
                      child: Text('February/March'),
                    ),
                    DropdownMenuItem(
                      value: 'supplementary',
                      child: Text('Supplementary'),
                    ),
                  ],
                  onChanged: (v) => setState(() => session = v ?? 'may_june'),
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
                    .read(papersRepositoryProvider)
                    .createPaper(
                      subjectId: subjectIdController.text.trim(),
                      examYear:
                          int.tryParse(yearController.text.trim()) ??
                          DateTime.now().year,
                      session: session,
                      paperNumber: paperNumber,
                      languageCode: 'en',
                      examType: 'nsc',
                      title: titleController.text.trim(),
                      sourceUrl: sourceUrlController.text.trim(),
                    );
                ref.invalidate(_papersProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/papers/$id');
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

final _papersProvider = FutureProvider(
  (ref) => ref.read(papersRepositoryProvider).fetchAll(),
);
