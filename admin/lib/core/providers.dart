import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/audit_log_repository.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/lessons_repository.dart';
import '../data/repositories/papers_repository.dart';
import '../data/repositories/questions_repository.dart';
import '../data/repositories/review_repository.dart';
import '../data/repositories/subjects_repository.dart';
import '../data/repositories/users_repository.dart';
import 'supabase/supabase_providers.dart';

/// Every repository provider below throws if read while [supabaseClientProvider] is null
/// (no project configured) — [AuthGate] never lets the dashboard body build in that state, so in
/// practice these are only ever read once a real client exists.
SupabaseClient _requireClient(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('No Supabase project configured — see admin/.env.example');
  }
  return client;
}

final subjectsRepositoryProvider = Provider(
  (ref) => SubjectsRepository(_requireClient(ref)),
);
final lessonsRepositoryProvider = Provider(
  (ref) => LessonsRepository(_requireClient(ref)),
);
final questionsRepositoryProvider = Provider(
  (ref) => QuestionsRepository(_requireClient(ref)),
);
final reviewRepositoryProvider = Provider(
  (ref) => ReviewRepository(_requireClient(ref)),
);
final contentReportsRepositoryProvider = Provider(
  (ref) => ContentReportsRepository(_requireClient(ref)),
);
final contentVersionsRepositoryProvider = Provider(
  (ref) => ContentVersionsRepository(_requireClient(ref)),
);
final papersRepositoryProvider = Provider(
  (ref) => PapersRepository(_requireClient(ref)),
);
final usersRepositoryProvider = Provider(
  (ref) => UsersRepository(_requireClient(ref)),
);
final auditLogRepositoryProvider = Provider(
  (ref) => AuditLogRepository(_requireClient(ref)),
);
final dashboardRepositoryProvider = Provider(
  (ref) => DashboardRepository(_requireClient(ref)),
);
