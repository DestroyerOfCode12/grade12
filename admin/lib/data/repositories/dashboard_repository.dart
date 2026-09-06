import 'package:supabase_flutter/supabase_flutter.dart';

/// Section 12: "View privacy-conscious usage analytics" — aggregate counts only, never a raw
/// learner list with identifying detail on this screen (that's what Users & Roles is for, and
/// even there only nickname/role/id are shown, never email or real name).
class DashboardStats {
  final int subjectCount;
  final int publishedLessonCount;
  final int openReviewTaskCount;
  final int openContentReportCount;
  final int learnerCount;
  final int paperCount;

  const DashboardStats({
    required this.subjectCount,
    required this.publishedLessonCount,
    required this.openReviewTaskCount,
    required this.openContentReportCount,
    required this.learnerCount,
    required this.paperCount,
  });
}

class DashboardRepository {
  final SupabaseClient client;
  DashboardRepository(this.client);

  Future<int> _count(
    String table, {
    List<(String, dynamic)> eq = const [],
  }) async {
    var query = client.from(table).select('id');
    for (final (col, val) in eq) {
      query = query.eq(col, val);
    }
    final rows = await query.count(CountOption.exact);
    return rows.count;
  }

  Future<DashboardStats> fetchStats() async {
    final results = await Future.wait([
      _count('subjects'),
      _count('lessons', eq: const [('content_status', 'published')]),
      _count('review_tasks', eq: const [('status', 'open')]),
      _count('content_reports', eq: const [('status', 'open')]),
      _count('profiles', eq: const [('role', 'learner')]),
      _count('papers'),
    ]);

    return DashboardStats(
      subjectCount: results[0],
      publishedLessonCount: results[1],
      openReviewTaskCount: results[2],
      openContentReportCount: results[3],
      learnerCount: results[4],
      paperCount: results[5],
    );
  }
}
