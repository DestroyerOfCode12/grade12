import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';

/// Section 11, screen 1. Decides where a learner lands: straight to onboarding for a first run
/// (guest mode by default — no account required, section 2/10), or Home if subjects were already
/// chosen this session. Full "resume where I left off" persistence across app restarts is a
/// CONTINUATION.md item (needs learner_preferences / LocalSubjects persistence wired in).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideNextRoute());
  }

  Future<void> _decideNextRoute() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final onboardingComplete = ref.read(onboardingCompleteProvider);
    context.go(onboardingComplete ? '/home' : '/onboarding/subjects');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_rounded, size: 72, color: scheme.onPrimary),
            const SizedBox(height: 16),
            Text(
              'MatricQuest SA',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your CAPS study companion',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }
}
