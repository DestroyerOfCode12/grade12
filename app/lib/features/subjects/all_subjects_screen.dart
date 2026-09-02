import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../data/demo_content/demo_catalogue.dart';
import '../../domain/models/subject.dart';
import '../../widgets/demo_content_badge.dart';

/// Section 11, screen 6 ("All subjects") doubling as screen 7 ("Subject overview") for the
/// vertical slice: tapping a subject with demo content jumps straight to its one lesson. A full
/// per-subject topic map (screen 8) is a Phase 3 item — see docs/CONTINUATION.md.
class AllSubjectsScreen extends ConsumerWidget {
  const AllSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(_allSubjectsProvider);
    final selected = ref.watch(selectedSubjectIdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load subjects: $e')),
        data: (subjects) {
          final ordered = [
            ...subjects.where((s) => selected.contains(s.id)),
            ...subjects.where((s) => !selected.contains(s.id)),
          ];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ordered.length,
            itemBuilder: (context, index) {
              final subject = ordered[index];
              final isMathsDemo =
                  subject.id == DemoCatalogue.mathematicsSubjectId;
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    subject.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(subject.coverageLabel),
                        if (subject.verificationStatus !=
                            VerificationStatus.verified)
                          const DemoContentBadge(),
                      ],
                    ),
                  ),
                  trailing: isMathsDemo
                      ? const Icon(Icons.chevron_right_rounded)
                      : null,
                  onTap: isMathsDemo
                      ? () => context.go(
                          '/learn/lesson/${DemoCatalogue.linearFunctionsLessonId}',
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

final _allSubjectsProvider = FutureProvider(
  (ref) => ref.read(subjectsRepositoryProvider).fetchCatalogue(),
);
