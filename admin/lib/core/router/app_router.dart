import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/audit_log/audit_log_screen.dart';
import '../../features/auth/auth_gate.dart';
import '../../features/content_reports/content_reports_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/papers/paper_detail_screen.dart';
import '../../features/papers/papers_screen.dart';
import '../../features/review_queue/review_queue_screen.dart';
import '../../features/subjects/lesson_editor_screen.dart';
import '../../features/subjects/question_editor_screen.dart';
import '../../features/subjects/subject_detail_screen.dart';
import '../../features/subjects/subjects_screen.dart';
import '../../features/users/users_screen.dart';

/// Section 12's admin dashboard screens, each behind [AuthGate] (staff-role check + the side
/// nav). Not every capability in section 12 has its own route yet — see admin/README.md and
/// the root CONTINUATION.md for what remains (analytics beyond the headline counts, a richer
/// "review AI drafts" diff view, bulk operations).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AuthGate(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/subjects',
            builder: (context, state) => const SubjectsScreen(),
            routes: [
              GoRoute(
                path: ':subjectId',
                builder: (context, state) => SubjectDetailScreen(
                  subjectId: state.pathParameters['subjectId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'lessons/:lessonId',
                    builder: (context, state) => LessonEditorScreen(
                      subjectId: state.pathParameters['subjectId']!,
                      lessonId: state.pathParameters['lessonId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'questions/:questionId',
                    builder: (context, state) => QuestionEditorScreen(
                      subjectId: state.pathParameters['subjectId']!,
                      questionId: state.pathParameters['questionId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/review',
            builder: (context, state) => const ReviewQueueScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ContentReportsScreen(),
          ),
          GoRoute(
            path: '/papers',
            builder: (context, state) => const PapersScreen(),
            routes: [
              GoRoute(
                path: ':paperId',
                builder: (context, state) => PaperDetailScreen(
                  paperId: state.pathParameters['paperId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/audit',
            builder: (context, state) => const AuditLogScreen(),
          ),
        ],
      ),
    ],
  );
});
