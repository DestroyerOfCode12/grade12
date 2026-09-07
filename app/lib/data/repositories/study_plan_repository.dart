import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/study_session.dart';
import '../../domain/services/study_plan_generator.dart';
import '../demo_content/demo_catalogue.dart';
import '../local/app_database.dart';

/// Section 9/11 (screen 20): generate and track a personalised study plan. Signed-in learners get
/// a real `study_plans`/`study_sessions` row set (docs/DATA_MODEL.md); guest/local-dev mode keeps
/// the same shape in the local SQLite mirror so the screen above doesn't need to know which one
/// it's talking to.
abstract class StudyPlanRepository {
  Future<bool> hasActivePlan();
  Future<List<PlannedSession>> fetchUpcoming();
  Future<List<PlannedSession>> generatePlan({
    required Set<String> selectedSubjectIds,
    required int horizonDays,
    required int dailyMinutes,
  });
  Future<void> markStatus(String sessionId, StudySessionStatus status);
}

class SupabaseStudyPlanRepository implements StudyPlanRepository {
  final SupabaseClient client;
  final String profileId;
  SupabaseStudyPlanRepository(this.client, this.profileId);

  @override
  Future<bool> hasActivePlan() async {
    final rows = await client
        .from('study_plans')
        .select('id')
        .eq('profile_id', profileId)
        .eq('is_active', true)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  @override
  Future<List<PlannedSession>> fetchUpcoming() async {
    final today = DateTime.now();
    final todayIso = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String().substring(0, 10);

    final rows = await client
        .from('study_sessions')
        .select('*, topics(title), study_plans!inner(profile_id, is_active)')
        .eq('study_plans.profile_id', profileId)
        .eq('study_plans.is_active', true)
        .gte('scheduled_for', todayIso)
        .neq('status', 'completed')
        .order('scheduled_for');

    return (rows as List)
        .map((r) => _fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PlannedSession>> generatePlan({
    required Set<String> selectedSubjectIds,
    required int horizonDays,
    required int dailyMinutes,
  }) async {
    if (selectedSubjectIds.isEmpty) return const [];

    final topicRows = await client
        .from('topics')
        .select('id, subject_id, title')
        .inFilter('subject_id', selectedSubjectIds.toList())
        .eq('content_status', 'published');

    if ((topicRows as List).isEmpty) return const [];

    final topicIds = topicRows.map((t) => t['id'] as String).toList();
    final masteryRows = await client
        .from('mastery_scores')
        .select('topic_id, mastery_estimate, attempts_count')
        .eq('profile_id', profileId)
        .inFilter('topic_id', topicIds);

    final masteryByTopic = {
      for (final m in (masteryRows as List))
        m['topic_id'] as String: m as Map<String, dynamic>,
    };

    final topics = topicRows.map((t) {
      final mastery = masteryByTopic[t['id']];
      return TopicPlanInput(
        subjectId: t['subject_id'] as String,
        topicId: t['id'] as String,
        topicTitle: t['title'] as String,
        masteryEstimate:
            (mastery?['mastery_estimate'] as num?)?.toDouble() ?? 0,
        attemptsCount: mastery?['attempts_count'] as int? ?? 0,
      );
    }).toList();

    final plan = StudyPlanGenerator.generate(
      topics: topics,
      startDate: DateTime.now(),
      horizonDays: horizonDays,
      dailyMinutes: dailyMinutes,
    );

    // Deactivate any prior plan, then create a fresh active one — a learner only ever has one
    // live schedule, matching the local-mode "replace" semantics.
    await client
        .from('study_plans')
        .update({'is_active': false})
        .eq('profile_id', profileId)
        .eq('is_active', true);

    final examinationYear = DateTime.now().year;
    final planRow = await client
        .from('study_plans')
        .insert({
          'profile_id': profileId,
          'examination_year': examinationYear,
          'generated_from': 'manual_edit',
          'is_active': true,
        })
        .select('id')
        .single();
    final studyPlanId = planRow['id'] as String;

    if (plan.isNotEmpty) {
      await client.from('study_sessions').insert([
        for (final s in plan)
          {
            'id': s.id,
            'study_plan_id': studyPlanId,
            'subject_id': s.subjectId,
            'topic_id': s.topicId,
            'scheduled_for': s.scheduledFor.toIso8601String().substring(0, 10),
            'duration_minutes': s.durationMinutes,
            'session_kind': s.sessionKind,
            'status': 'scheduled',
          },
      ]);
    }

    return plan;
  }

  @override
  Future<void> markStatus(String sessionId, StudySessionStatus status) async {
    final patch = <String, dynamic>{'status': studySessionStatusToDb(status)};
    if (status == StudySessionStatus.completed) {
      patch['completed_at'] = DateTime.now().toIso8601String();
    }
    await client.from('study_sessions').update(patch).eq('id', sessionId);
  }

  PlannedSession _fromRow(Map<String, dynamic> r) => PlannedSession(
    id: r['id'] as String,
    subjectId: r['subject_id'] as String,
    topicId: r['topic_id'] as String,
    topicTitle:
        (r['topics'] as Map<String, dynamic>?)?['title'] as String? ?? 'Topic',
    scheduledFor: DateTime.parse(r['scheduled_for'] as String),
    durationMinutes: r['duration_minutes'] as int,
    sessionKind: r['session_kind'] as String,
    status: studySessionStatusFromDb(r['status'] as String? ?? 'scheduled'),
  );
}

/// Local dev mode / guest mode: only the embedded demo Mathematics topic exists to schedule.
/// Mastery comes from `local_mastery_scores` (`app_database.dart`) — written by the diagnostic
/// assessment if the learner took it, or the "not started" default otherwise, exactly matching
/// what an unattempted topic would score via [MasteryCalculator.labelFor].
class LocalStudyPlanRepository implements StudyPlanRepository {
  final AppDatabase db;
  static const _guestProfileId = 'guest';
  LocalStudyPlanRepository(this.db);

  @override
  Future<bool> hasActivePlan() async => db.hasAnyStudySessions(_guestProfileId);

  @override
  Future<List<PlannedSession>> fetchUpcoming() async {
    final today = DateTime.now();
    final todayIso = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String().substring(0, 10);
    final rows = db.upcomingStudySessions(
      _guestProfileId,
      fromDateIso: todayIso,
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<PlannedSession>> generatePlan({
    required Set<String> selectedSubjectIds,
    required int horizonDays,
    required int dailyMinutes,
  }) async {
    final topics = <TopicPlanInput>[];
    if (selectedSubjectIds.contains(DemoCatalogue.mathematicsSubjectId)) {
      final mastery = db.masteryScore(
        _guestProfileId,
        DemoCatalogue.functionsTopicId,
      );
      topics.add(
        TopicPlanInput(
          subjectId: DemoCatalogue.mathematicsSubjectId,
          topicId: DemoCatalogue.functionsTopicId,
          topicTitle: DemoCatalogue.functionsTopicTitle,
          masteryEstimate: mastery?['mastery_estimate'] as double? ?? 0,
          attemptsCount: mastery?['attempts_count'] as int? ?? 0,
        ),
      );
    }

    final plan = StudyPlanGenerator.generate(
      topics: topics,
      startDate: DateTime.now(),
      horizonDays: horizonDays,
      dailyMinutes: dailyMinutes,
    );

    db.replaceStudySessions(_guestProfileId, [
      for (final s in plan)
        {
          'id': s.id,
          'subject_id': s.subjectId,
          'topic_id': s.topicId,
          'topic_title': s.topicTitle,
          'scheduled_for': s.scheduledFor.toIso8601String().substring(0, 10),
          'duration_minutes': s.durationMinutes,
          'session_kind': s.sessionKind,
        },
    ]);

    return plan;
  }

  @override
  Future<void> markStatus(String sessionId, StudySessionStatus status) async {
    db.updateStudySessionStatus(
      sessionId,
      studySessionStatusToDb(status),
      completedAtIso: status == StudySessionStatus.completed
          ? DateTime.now().toIso8601String()
          : null,
    );
  }

  PlannedSession _fromRow(Map<String, Object?> r) => PlannedSession(
    id: r['id'] as String,
    subjectId: r['subject_id'] as String,
    topicId: r['topic_id'] as String,
    topicTitle: r['topic_title'] as String,
    scheduledFor: DateTime.parse(r['scheduled_for'] as String),
    durationMinutes: r['duration_minutes'] as int,
    sessionKind: r['session_kind'] as String,
    status: studySessionStatusFromDb(r['status'] as String? ?? 'scheduled'),
  );
}
