// Critical-flow coverage for the guest/local-mode study planner (section 9/11 screen 20):
// generate a plan, see it on fetchUpcoming, mark a session done, see it drop off the upcoming
// list without being lost (still queryable as history via the raw table if needed later).

import 'package:flutter_test/flutter_test.dart';
import 'package:matricquest_sa/data/demo_content/demo_catalogue.dart';
import 'package:matricquest_sa/data/local/app_database.dart';
import 'package:matricquest_sa/data/repositories/study_plan_repository.dart';
import 'package:matricquest_sa/domain/models/study_session.dart';

void main() {
  late AppDatabase db;
  late LocalStudyPlanRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = LocalStudyPlanRepository(db);
  });

  tearDown(() => db.close());

  test('no plan exists before generatePlan is called', () async {
    expect(await repo.hasActivePlan(), isFalse);
    expect(await repo.fetchUpcoming(), isEmpty);
  });

  test(
    'generating a plan for the demo Mathematics subject produces sessions',
    () async {
      final plan = await repo.generatePlan(
        selectedSubjectIds: {DemoCatalogue.mathematicsSubjectId},
        horizonDays: 14,
        dailyMinutes: 30,
      );

      expect(plan, isNotEmpty);
      expect(await repo.hasActivePlan(), isTrue);

      final upcoming = await repo.fetchUpcoming();
      expect(upcoming, isNotEmpty);
      expect(upcoming.first.topicId, DemoCatalogue.functionsTopicId);
    },
  );

  test(
    'generating a plan for an unselected/unknown subject produces nothing',
    () async {
      final plan = await repo.generatePlan(
        selectedSubjectIds: {'some-other-subject'},
        horizonDays: 14,
        dailyMinutes: 30,
      );
      expect(plan, isEmpty);
    },
  );

  test(
    'marking a session completed removes it from the upcoming list',
    () async {
      await repo.generatePlan(
        selectedSubjectIds: {DemoCatalogue.mathematicsSubjectId},
        horizonDays: 7,
        dailyMinutes: 30,
      );
      final before = await repo.fetchUpcoming();
      expect(before, isNotEmpty);

      await repo.markStatus(before.first.id, StudySessionStatus.completed);

      final after = await repo.fetchUpcoming();
      expect(after.any((s) => s.id == before.first.id), isFalse);
    },
  );

  test('regenerating a plan does not duplicate sessions endlessly', () async {
    await repo.generatePlan(
      selectedSubjectIds: {DemoCatalogue.mathematicsSubjectId},
      horizonDays: 14,
      dailyMinutes: 30,
    );
    final firstCount = (await repo.fetchUpcoming()).length;

    await repo.generatePlan(
      selectedSubjectIds: {DemoCatalogue.mathematicsSubjectId},
      horizonDays: 14,
      dailyMinutes: 30,
    );
    final secondCount = (await repo.fetchUpcoming()).length;

    // Regenerating replaces the schedule rather than appending to it.
    expect(secondCount, firstCount);
  });
}
