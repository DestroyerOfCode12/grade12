import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/supabase/supabase_providers.dart';

/// Section 11, screen 24 (+ a pointer to screen 25, privacy/export/delete — not yet implemented,
/// see docs/CONTINUATION.md). Nickname-first, private-by-default per section 14.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocalDevMode = ref.watch(isLocalDevModeProvider);
    final userId = ref.watch(currentUserIdProvider);
    final outcome = ref
        .read(gamificationRepositoryProvider)
        .currentState(userId);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 40,
            child: Icon(Icons.person_rounded, size: 40),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              isLocalDevMode ? 'Guest learner' : 'Signed in',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_fire_department_rounded),
              title: Text('${outcome.currentStreakDays}-day streak'),
              subtitle: Text('${outcome.totalXp} XP · Level ${outcome.level}'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.checklist_rounded),
              title: const Text('Change my subjects'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/onboarding/subjects'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('Privacy, export & delete my data'),
              subtitle: Text('Coming soon — see docs/CONTINUATION.md'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.flag_outlined),
              title: Text('Report a content issue'),
              subtitle: Text('Coming soon — see docs/CONTINUATION.md'),
            ),
          ),
          if (isLocalDevMode)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Running in local dev mode: no backend is configured, so progress stays on this '
                'device only. See app/.env.example to connect a real Supabase project.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}
