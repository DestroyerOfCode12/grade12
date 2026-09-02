import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/repositories/gamification_repository.dart';
import '../data/repositories/lesson_repository.dart';
import '../data/repositories/papers_repository.dart';
import '../data/repositories/quiz_repository.dart';
import '../data/repositories/subjects_repository.dart';
import 'config/env.dart';
import 'supabase/supabase_providers.dart';

/// Single shared local database instance for the app's lifetime. Opening it needs an `await`
/// (resolving the documents directory), so it is created once in `main()` and injected here via
/// `ProviderScope(overrides: [appDatabaseProvider.overrideWithValue(db)])` — this placeholder
/// throws if that override is ever missing, which is deliberate: a silent fallback would hide a
/// real startup bug.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden in main() with an opened AppDatabase',
  );
});

/// Repository providers pick the Supabase-backed implementation when a project is configured,
/// and the embedded local-seed implementation otherwise (local dev mode / no connectivity yet
/// wired up for the vertical slice — see docs/CONTINUATION.md for the full offline-sync queue).
final subjectsRepositoryProvider = Provider<SubjectsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) return SupabaseSubjectsRepository(client);
  return LocalSeedSubjectsRepository();
});

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) return SupabaseLessonRepository(client);
  return LocalSeedLessonRepository();
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) return SupabaseQuizRepository(client);
  return LocalSeedQuizRepository();
});

final papersRepositoryProvider = Provider<PapersRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) return SupabasePapersRepository(client);
  return LocalSeedPapersRepository();
});

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return GamificationRepository(client: client, db: db);
});

/// Learner's selected subjects, held in memory for the vertical slice. Persisted to
/// `learner_preferences` (signed in) or `LocalSubjects.isSelectedByLearner` (guest) — see
/// docs/CONTINUATION.md for wiring that persistence into this provider.
final selectedSubjectIdsProvider = StateProvider<Set<String>>((ref) => {});

/// True once onboarding (subject selection + diagnostic) has been completed this session.
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);

/// Convenience: is the app currently running with no backend configured at all.
final isLocalDevModeProvider = Provider<bool>((ref) => Env.isLocalDevMode);
