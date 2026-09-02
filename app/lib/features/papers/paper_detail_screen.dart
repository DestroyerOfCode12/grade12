import 'package:flutter/material.dart';

import '../../widgets/demo_content_badge.dart';

/// Section 11, screens 15-18 (PDF viewer, timed/untimed exam mode, memo split view, results) are
/// collapsed into one honest placeholder for the vertical slice: no real PDF is bundled, so this
/// screen says so rather than pretending. Full ingestion + viewer + self-marking is Phase 3
/// (docs/CONTINUATION.md).
class PaperDetailScreen extends StatelessWidget {
  final String paperId;
  const PaperDetailScreen({super.key, required this.paperId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paper')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DemoContentBadge(label: 'Demo record — no bundled file yet'),
            const SizedBox(height: 16),
            Text(
              'Paper ID: $paperId',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'This is a placeholder for the past-paper viewer. In the full build this screen shows '
              'the question paper and memorandum side by side, with timed/untimed exam modes and '
              'automatic + self-assessed marking (see docs/CONTINUATION.md).',
            ),
          ],
        ),
      ),
    );
  }
}
