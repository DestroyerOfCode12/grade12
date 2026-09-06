import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories/dashboard_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load stats: $e')),
        data: (stats) => Padding(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                label: 'Subjects',
                value: stats.subjectCount,
                icon: Icons.menu_book_rounded,
              ),
              _StatCard(
                label: 'Published lessons',
                value: stats.publishedLessonCount,
                icon: Icons.public_rounded,
              ),
              _StatCard(
                label: 'Open review tasks',
                value: stats.openReviewTaskCount,
                icon: Icons.fact_check_rounded,
              ),
              _StatCard(
                label: 'Open content reports',
                value: stats.openContentReportCount,
                icon: Icons.flag_rounded,
              ),
              _StatCard(
                label: 'Learners',
                value: stats.learnerCount,
                icon: Icons.people_alt_rounded,
              ),
              _StatCard(
                label: 'Past papers',
                value: stats.paperCount,
                icon: Icons.description_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _statsProvider = FutureProvider<DashboardStats>(
  (ref) => ref.read(dashboardRepositoryProvider).fetchStats(),
);

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text('$value', style: Theme.of(context).textTheme.headlineMedium),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
