import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../data/demo_content/demo_catalogue.dart';

/// Section 11, screen 14. Filter/search/bookmarks/download management (section 7) are Phase 3
/// items — see docs/CONTINUATION.md. This vertical slice lists papers for the demo Mathematics
/// subject and is honest about association_confidence/content_status rather than pretending a
/// bundled file exists.
class PapersLibraryScreen extends ConsumerWidget {
  const PapersLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = ref.watch(_papersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Past Papers')),
      body: papersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load papers: $e')),
        data: (papers) {
          if (papers.isEmpty) {
            return const Center(
              child: Text('No papers available yet for your subjects.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: papers.length,
            itemBuilder: (context, index) {
              final paper = papers[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.description_rounded),
                  title: Text(paper.title),
                  subtitle: Text(
                    '${paper.examYear} · ${_sessionLabel(paper.session)} · Paper ${paper.paperNumber} · '
                    '${paper.associationConfidence == 'confirmed' ? 'Memo linked' : 'Memo association unconfirmed'}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/papers/${paper.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _sessionLabel(String session) => switch (session) {
    'may_june' => 'May/June',
    'october_november' => 'Oct/Nov',
    'february_march' => 'Feb/March',
    'supplementary' => 'Supplementary',
    _ => session,
  };
}

final _papersProvider = FutureProvider(
  (ref) => ref
      .read(papersRepositoryProvider)
      .fetchPapersForSubject(DemoCatalogue.mathematicsSubjectId),
);
