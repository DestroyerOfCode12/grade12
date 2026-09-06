import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../widgets/admin_shell.dart';
import 'sign_in_screen.dart';

const _staffRoles = {'content_reviewer', 'admin', 'super_admin'};

/// Wraps every routed screen (GoRouter `ShellRoute`, `child` = the matched sub-route) and decides
/// what actually renders:
///  1. No Supabase project configured -> "not connected" screen (nothing else can work).
///  2. Not signed in -> [SignInScreen].
///  3. Signed in but `profiles.role` is not a staff role -> refused, with sign-out offered.
///     (UX convenience only — RLS is the real enforcement. A learner account that somehow reached
///     this screen would see empty tables everywhere even without this gate.)
///  4. Staff role confirmed -> [AdminShell] wrapping [child].
class AuthGate extends ConsumerWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.isConfigured) return const _NotConnectedScreen();

    final authState = ref.watch(authStateProvider);
    final client = ref.watch(supabaseClientProvider);

    if (client?.auth.currentUser == null) {
      return authState.when(
        data: (_) => client?.auth.currentUser == null
            ? const SignInScreen()
            : _RoleCheck(child: child),
        loading: () => const _LoadingScreen(),
        error: (e, _) => const SignInScreen(),
      );
    }

    return _RoleCheck(child: child);
  }
}

class _RoleCheck extends ConsumerWidget {
  final Widget child;
  const _RoleCheck({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentStaffProfileProvider);

    return profileAsync.when(
      loading: () => const _LoadingScreen(),
      error: (e, _) =>
          _AccessDeniedScreen(reason: 'Could not load your profile: $e'),
      data: (profile) {
        final role = profile?['role'] as String?;
        if (role == null || !_staffRoles.contains(role)) {
          return const _AccessDeniedScreen(
            reason:
                'Your account does not have staff access to this dashboard.',
          );
        }
        return AdminShell(child: child);
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _AccessDeniedScreen extends ConsumerWidget {
  final String reason;
  const _AccessDeniedScreen({required this.reason});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Access denied',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(reason, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () =>
                    ref.read(supabaseClientProvider)?.auth.signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotConnectedScreen extends StatelessWidget {
  const _NotConnectedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                'No Supabase project configured',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'This dashboard edits real backend data, so there is no local demo mode. Build with\n'
                '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...\n'
                'See admin/.env.example.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
