import 'package:flutter_test/flutter_test.dart';
import 'package:matricquest_sa/domain/models/study_session.dart';
import 'package:matricquest_sa/domain/services/study_plan_generator.dart';

void main() {
  final start = DateTime(
    2026,
    9,
    7,
  ); // a Monday, arbitrary fixed date for determinism

  group('StudyPlanGenerator.generate', () {
    test('an empty topic list produces an empty plan', () {
      final plan = StudyPlanGenerator.generate(
        topics: const [],
        startDate: start,
        horizonDays: 14,
        dailyMinutes: 30,
      );
      expect(plan, isEmpty);
    });

    test('a brand-new (not started) topic is scheduled on day one', () {
      final plan = StudyPlanGenerator.generate(
        topics: const [
          TopicPlanInput(
            subjectId: 's1',
            topicId: 't1',
            topicTitle: 'Functions',
            masteryEstimate: 0,
            attemptsCount: 0,
          ),
        ],
        startDate: start,
        horizonDays: 7,
        dailyMinutes: 30,
      );

      expect(plan, isNotEmpty);
      expect(plan.first.scheduledFor, start);
      expect(
        plan.first.sessionKind,
        'lesson',
        reason: 'not-started topics get a lesson, not spaced repetition',
      );
    });

    test('a weak topic (needs_work) recurs more often than a strong one', () {
      final plan = StudyPlanGenerator.generate(
        topics: const [
          TopicPlanInput(
            subjectId: 's1',
            topicId: 'weak',
            topicTitle: 'Weak',
            masteryEstimate: 20,
            attemptsCount: 3,
          ),
          TopicPlanInput(
            subjectId: 's1',
            topicId: 'strong',
            topicTitle: 'Strong',
            masteryEstimate: 90,
            attemptsCount: 5,
          ),
        ],
        startDate: start,
        horizonDays: 28,
        dailyMinutes:
            120, // generous budget so nothing is starved by daily capacity
      );

      final weakCount = plan.where((s) => s.topicId == 'weak').length;
      final strongCount = plan.where((s) => s.topicId == 'strong').length;
      expect(weakCount, greaterThan(strongCount));
    });

    test('every session respects the requested session length', () {
      final plan = StudyPlanGenerator.generate(
        topics: const [
          TopicPlanInput(
            subjectId: 's1',
            topicId: 't1',
            topicTitle: 'A',
            masteryEstimate: 10,
            attemptsCount: 1,
          ),
        ],
        startDate: start,
        horizonDays: 10,
        dailyMinutes: 30,
        sessionLengthMinutes: 15,
      );
      for (final session in plan) {
        expect(session.durationMinutes, 15);
      }
    });

    test(
      'a full day never schedules more sessions than the daily budget allows',
      () {
        final topics = List.generate(
          10,
          (i) => TopicPlanInput(
            subjectId: 's1',
            topicId: 't$i',
            topicTitle: 'Topic $i',
            masteryEstimate: 0,
            attemptsCount: 0,
          ),
        );
        final plan = StudyPlanGenerator.generate(
          topics: topics,
          startDate: start,
          horizonDays: 1,
          dailyMinutes: 40, // room for 2 sessions of 20 min
          sessionLengthMinutes: 20,
        );
        expect(plan.where((s) => s.scheduledFor == start).length, 2);
      },
    );

    test('sessions that overflow a full day carry over to a later day instead of being dropped', () {
      final topics = List.generate(
        5,
        (i) => TopicPlanInput(
          subjectId: 's1',
          topicId: 't$i',
          topicTitle: 'Topic $i',
          masteryEstimate: 0,
          attemptsCount: 0,
        ),
      );
      final plan = StudyPlanGenerator.generate(
        topics: topics,
        startDate: start,
        horizonDays: 5,
        dailyMinutes:
            20, // only 1 session/day, 5 not-started topics all due immediately
        sessionLengthMinutes: 20,
      );

      // All 5 topics should eventually appear at least once across the horizon, none dropped.
      final scheduledTopicIds = plan.map((s) => s.topicId).toSet();
      expect(scheduledTopicIds, hasLength(5));
    });

    test(
      'every scheduled date falls within [startDate, startDate + horizonDays)',
      () {
        final topics = List.generate(
          3,
          (i) => TopicPlanInput(
            subjectId: 's1',
            topicId: 't$i',
            topicTitle: 'Topic $i',
            masteryEstimate: 30.0 * i,
            attemptsCount: 2,
          ),
        );
        const horizon = 21;
        final plan = StudyPlanGenerator.generate(
          topics: topics,
          startDate: start,
          horizonDays: horizon,
          dailyMinutes: 60,
        );

        final endExclusive = start.add(const Duration(days: horizon));
        for (final session in plan) {
          expect(session.scheduledFor.isBefore(endExclusive), isTrue);
          expect(session.scheduledFor.isBefore(start), isFalse);
        }
      },
    );

    test('each generated session gets a unique id', () {
      final topics = List.generate(
        4,
        (i) => TopicPlanInput(
          subjectId: 's1',
          topicId: 't$i',
          topicTitle: 'Topic $i',
          masteryEstimate: 10,
          attemptsCount: 1,
        ),
      );
      final plan = StudyPlanGenerator.generate(
        topics: topics,
        startDate: start,
        horizonDays: 14,
        dailyMinutes: 80,
      );
      final ids = plan.map((s) => s.id).toSet();
      expect(ids.length, plan.length);
    });

    test('a freshly generated session starts in scheduled status', () {
      final plan = StudyPlanGenerator.generate(
        topics: const [
          TopicPlanInput(
            subjectId: 's1',
            topicId: 't1',
            topicTitle: 'A',
            masteryEstimate: 50,
            attemptsCount: 2,
          ),
        ],
        startDate: start,
        horizonDays: 7,
        dailyMinutes: 30,
      );
      expect(
        plan.every((s) => s.status == StudySessionStatus.scheduled),
        isTrue,
      );
    });
  });
}
