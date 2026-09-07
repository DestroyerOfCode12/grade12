import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../domain/models/subject.dart';
import '../../widgets/demo_content_badge.dart';

/// Section 11, screen 3 / section 4: "During onboarding, learners select only the subjects they
/// are taking. They must be able to change their selection later" — this same screen is reused
/// from Profile > Settings for that (see docs/CONTINUATION.md for wiring that entry point).
class SubjectSelectionScreen extends ConsumerWidget {
  const SubjectSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(_subjectsFutureProvider);
    final selected = ref.watch(selectedSubjectIdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your subjects')),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load subjects: $e')),
        data: (subjects) {
          final grouped = <String, List<Subject>>{};
          for (final s in subjects) {
            grouped.putIfAbsent(s.category, () => []).add(s);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Select every subject you are taking this year. You can change this anytime in Profile.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                for (final subject in entry.value)
                  Card(
                    child: CheckboxListTile(
                      value: selected.contains(subject.id),
                      onChanged: (checked) {
                        final next = {...selected};
                        checked == true
                            ? next.add(subject.id)
                            : next.remove(subject.id);
                        ref.read(selectedSubjectIdsProvider.notifier).state =
                            next;
                      },
                      title: Text(subject.name),
                      subtitle: Row(
                        children: [
                          Text(
                            subject.coverageLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (subject.verificationStatus !=
                              VerificationStatus.verified) ...[
                            const SizedBox(width: 8),
                            const DemoContentBadge(
                              label: 'Coverage not yet fully verified',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        ref.read(onboardingCompleteProvider.notifier).state =
                            true;
                        context.go('/onboarding/diagnostic');
                      },
                child: Text(
                  selected.isEmpty
                      ? 'Select at least one subject'
                      : 'Continue (${selected.length} selected)',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.read(onboardingCompleteProvider.notifier).state = true;
                  context.go('/home');
                },
                child: const Text('Skip for now'),
              ),
            ],
          );
        },
      ),
    );
  }
}

final _subjectsFutureProvider = FutureProvider(
  (ref) => ref.read(subjectsRepositoryProvider).fetchCatalogue(),
);
