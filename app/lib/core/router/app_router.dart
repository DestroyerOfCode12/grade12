import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/home_dashboard_screen.dart';
import '../../features/gamification/results_screen.dart';
import '../../features/lesson/lesson_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/subject_selection_screen.dart';
import '../../features/papers/paper_detail_screen.dart';
import '../../features/papers/papers_library_screen.dart';
import '../../features/planner/study_planner_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/subjects/all_subjects_screen.dart';
import '../../widgets/app_shell.dart';

/// Section 11's required screens are implemented as routes here. Not every screen in the full
/// product brief has a route yet (Quest Coach chat UI, Boss Battle, Achievements, Leaderboard,
/// Downloads, Privacy/export/delete, Help — see docs/CONTINUATION.md for the tracked remainder).
/// The five bottom-nav sections (Home/Learn/Papers/Play/Profile, section 11) are wired via
/// [AppShell] with [StatefulShellRoute]; Study Planner (screen 20) is reached from Home rather
/// than being its own bottom-nav tab, matching the brief's own list of five tabs.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding/subjects',
        builder: (context, state) => const SubjectSelectionScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learn',
                builder: (context, state) => const AllSubjectsScreen(),
                routes: [
                  GoRoute(
                    path: 'lesson/:lessonId',
                    builder: (context, state) => LessonScreen(
                      lessonId: state.pathParameters['lessonId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'quiz/:quizId',
                    builder: (context, state) =>
                        QuizScreen(quizId: state.pathParameters['quizId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/papers',
                builder: (context, state) => const PapersLibraryScreen(),
                routes: [
                  GoRoute(
                    path: ':paperId',
                    builder: (context, state) => PaperDetailScreen(
                      paperId: state.pathParameters['paperId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // "Play" tab: Boss Battles / Daily Challenge land here in a later pass
              // (docs/CONTINUATION.md). Results screen is reachable from Learn/Papers today.
              GoRoute(
                path: '/play',
                builder: (context, state) => const ResultsPlaceholderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/results',
        builder: (context, state) => ResultsScreen(outcome: state.extra),
      ),
      GoRoute(
        path: '/planner',
        builder: (context, state) => const StudyPlannerScreen(),
      ),
    ],
  );
});

/// Minimal stand-in for the "Play" tab until Boss Battle / Daily Challenge screens exist.
class ResultsPlaceholderScreen extends StatelessWidget {
  const ResultsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Play')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Daily Challenge and Boss Battles are coming in the next build — see CONTINUATION.md.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
