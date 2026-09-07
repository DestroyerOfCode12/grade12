/// Mirrors a `study_sessions` row (or its local-mode equivalent) — one scheduled study activity
/// on one day, section 9/11 (screen 20, "Study planner and calendar").
enum StudySessionStatus { scheduled, completed, skipped, rescheduled }

StudySessionStatus studySessionStatusFromDb(String value) => switch (value) {
  'completed' => StudySessionStatus.completed,
  'skipped' => StudySessionStatus.skipped,
  'rescheduled' => StudySessionStatus.rescheduled,
  _ => StudySessionStatus.scheduled,
};

String studySessionStatusToDb(StudySessionStatus status) => switch (status) {
  StudySessionStatus.scheduled => 'scheduled',
  StudySessionStatus.completed => 'completed',
  StudySessionStatus.skipped => 'skipped',
  StudySessionStatus.rescheduled => 'rescheduled',
};

class PlannedSession {
  final String id;
  final String subjectId;
  final String topicId;
  final String topicTitle;
  final DateTime scheduledFor; // date-only
  final int durationMinutes;
  final String
  sessionKind; // 'lesson' | 'spaced_repetition' | 'flashcards' | 'past_paper'
  final StudySessionStatus status;

  const PlannedSession({
    required this.id,
    required this.subjectId,
    required this.topicId,
    required this.topicTitle,
    required this.scheduledFor,
    required this.durationMinutes,
    required this.sessionKind,
    required this.status,
  });

  PlannedSession copyWith({StudySessionStatus? status}) => PlannedSession(
    id: id,
    subjectId: subjectId,
    topicId: topicId,
    topicTitle: topicTitle,
    scheduledFor: scheduledFor,
    durationMinutes: durationMinutes,
    sessionKind: sessionKind,
    status: status ?? this.status,
  );
}

/// One topic's current standing, fed into [StudyPlanGenerator] — deliberately the same shape the
/// dashboard's mastery display uses, so "why does my plan look like this" always has an answer
/// traceable back to a mastery estimate the learner can also see (section 9: never a black box).
class TopicPlanInput {
  final String subjectId;
  final String topicId;
  final String topicTitle;
  final double masteryEstimate;
  final int attemptsCount;

  const TopicPlanInput({
    required this.subjectId,
    required this.topicId,
    required this.topicTitle,
    required this.masteryEstimate,
    required this.attemptsCount,
  });
}
