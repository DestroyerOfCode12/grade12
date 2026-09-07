import 'package:uuid/uuid.dart';

import '../models/study_session.dart';
import 'mastery_calculator.dart';

/// Section 9: "Generate a study plan based on: current topic mastery, target marks, CAPS term
/// structure, available study time, past-paper performance, time remaining before examinations,
/// spaced-repetition schedules."
///
/// This generator covers the mastery-driven spaced-repetition core deliberately, not the whole
/// list at once: term structure and past-paper performance are read as *inputs* elsewhere
/// (nothing here stops a caller passing a `TopicPlanInput` filtered to the current CAPS term, or
/// folding paper-attempt results into `masteryEstimate` before calling in) — see
/// docs/CONTINUATION.md for what's still a straight pass-through vs. genuinely modelled.
///
/// The rule set is intentionally simple and explainable rather than a black box (same reasoning
/// as [MasteryCalculator]): every session on the plan traces back to one topic's
/// [ReadinessLabel], and a learner (or a reviewer checking this code) can say exactly why a topic
/// was scheduled when it was.
class StudyPlanGenerator {
  StudyPlanGenerator._();

  static const _uuid = Uuid();

  /// Review interval, in days, for a topic at a given readiness level — shorter for weaker
  /// topics, matching standard spaced-repetition practice. `notStarted` topics are due
  /// immediately (interval 0) so a brand-new subject selection isn't left waiting.
  static int _intervalDaysFor(ReadinessLabel label) => switch (label) {
    ReadinessLabel.notStarted => 0,
    ReadinessLabel.needsWork => 2,
    ReadinessLabel.developing => 4,
    ReadinessLabel.onTrack => 7,
    ReadinessLabel.strong => 14,
  };

  /// Generates a day-by-day plan covering [horizonDays] starting at [startDate] (inclusive,
  /// date-only — time-of-day on [startDate] is ignored).
  ///
  /// Each day gets as many [sessionLengthMinutes] sessions as fit in [dailyMinutes], picking the
  /// most overdue / weakest topics first. A topic due on a day that doesn't have room for it
  /// carries over to the next day rather than being dropped, so a learner who under-books their
  /// daily time still eventually sees every weak topic instead of silently losing sessions.
  static List<PlannedSession> generate({
    required List<TopicPlanInput> topics,
    required DateTime startDate,
    required int horizonDays,
    required int dailyMinutes,
    int sessionLengthMinutes = 20,
  }) {
    assert(horizonDays > 0);
    assert(dailyMinutes > 0);
    assert(sessionLengthMinutes > 0);
    if (topics.isEmpty) return const [];

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final sessionsPerDay = (dailyMinutes / sessionLengthMinutes).floor().clamp(
      1,
      1000,
    );

    // dueOn[topicIndex] = next day-offset (from start) this topic is due; null once it has no
    // more occurrences scheduled within the horizon after its last placement.
    final nextDueOffset = List<int>.generate(
      topics.length,
      (i) => _intervalDaysFor(
        MasteryCalculator.labelFor(
          topics[i].masteryEstimate,
          attemptsCount: topics[i].attemptsCount,
        ),
      ),
    );

    final carryOver = <int>[]; // topic indices bumped from a full day
    final result = <PlannedSession>[];

    for (var dayOffset = 0; dayOffset < horizonDays; dayOffset++) {
      final dueToday = <int>[...carryOver];
      carryOver.clear();

      for (var i = 0; i < topics.length; i++) {
        if (nextDueOffset[i] == dayOffset && !dueToday.contains(i)) {
          dueToday.add(i);
        }
      }

      // Weakest (lowest mastery) first — carries the same "help where it's needed most"
      // intent as the interval choice above.
      dueToday.sort(
        (a, b) =>
            topics[a].masteryEstimate.compareTo(topics[b].masteryEstimate),
      );

      final today = start.add(Duration(days: dayOffset));
      final scheduledToday = dueToday.take(sessionsPerDay).toList();
      final overflow = dueToday.skip(sessionsPerDay).toList();
      carryOver.addAll(overflow);

      for (final topicIndex in scheduledToday) {
        final topic = topics[topicIndex];
        final label = MasteryCalculator.labelFor(
          topic.masteryEstimate,
          attemptsCount: topic.attemptsCount,
        );
        result.add(
          PlannedSession(
            id: _uuid.v4(),
            subjectId: topic.subjectId,
            topicId: topic.topicId,
            topicTitle: topic.topicTitle,
            scheduledFor: today,
            durationMinutes: sessionLengthMinutes,
            sessionKind: label == ReadinessLabel.notStarted
                ? 'lesson'
                : 'spaced_repetition',
            status: StudySessionStatus.scheduled,
          ),
        );

        final interval = _intervalDaysFor(label);
        final next = dayOffset + (interval == 0 ? 1 : interval);
        nextDueOffset[topicIndex] = next < horizonDays ? next : -1;
      }
    }

    return result;
  }
}
