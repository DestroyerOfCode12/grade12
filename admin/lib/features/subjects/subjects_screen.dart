import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../domain/models/subject_models.dart';
import '../../widgets/status_pill.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(_subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('New subject'),
              onPressed: () => _showCreateDialog(context, ref),
            ),
          ),
        ],
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load subjects: $e')),
        data: (subjects) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Level')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Verification')),
                DataColumn(label: Text('Coverage')),
              ],
              rows: [
                for (final s in subjects)
                  DataRow(
                    onSelectChanged: (_) => context.go('/subjects/${s.id}'),
                    cells: [
                      DataCell(Text(s.name)),
                      DataCell(Text(s.category)),
                      DataCell(Text(s.level)),
                      DataCell(StatusPill(status: s.contentStatus)),
                      DataCell(VerificationPill(status: s.verificationStatus)),
                      DataCell(Text(_coverageLabel(s))),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _coverageLabel(AdminSubject s) {
    if (s.fullCourseAvailable) return 'Full course';
    if (s.lessonsInReview) return 'Lessons in review';
    if (s.papersAvailable) return 'Papers available';
    return 'Coming soon';
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    String level = 'core';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New subject'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code (e.g. accounting)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: level,
                  decoration: const InputDecoration(labelText: 'Level'),
                  items: const [
                    DropdownMenuItem(
                      value: 'core',
                      child: Text('Core / non-language'),
                    ),
                    DropdownMenuItem(
                      value: 'home_language',
                      child: Text('Home Language'),
                    ),
                    DropdownMenuItem(
                      value: 'first_additional',
                      child: Text('First Additional Language'),
                    ),
                    DropdownMenuItem(
                      value: 'second_additional',
                      child: Text('Second Additional Language'),
                    ),
                  ],
                  onChanged: (v) => setState(() => level = v ?? 'core'),
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
                    .createSubject(
                      code: codeController.text.trim(),
                      name: nameController.text.trim(),
                      category: categoryController.text.trim(),
                      level: level,
                    );
                ref.invalidate(_subjectsProvider);
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

final _subjectsProvider = FutureProvider(
  (ref) => ref.read(subjectsRepositoryProvider).fetchAll(),
);
