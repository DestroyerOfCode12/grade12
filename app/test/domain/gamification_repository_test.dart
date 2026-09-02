// Critical flow #2 (section 16): "Learner completes a lesson and earns XP", plus section 13's
// idempotency requirement — retrying the same award must not double the XP total.

import 'package:flutter_test/flutter_test.dart';
import 'package:matricquest_sa/core/utils/idempotency.dart';
import 'package:matricquest_sa/data/local/app_database.dart';
import 'package:matricquest_sa/data/repositories/gamification_repository.dart';

void main() {
  late AppDatabase db;
  late GamificationRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = GamificationRepository(
      client: null,
      db: db,
    ); // guest / local dev path
  });

  tearDown(() => db.close());

  test('awarding XP in guest mode updates the running total', () async {
    final outcome = await repo.awardXp(
      profileId: null,
      amount: 15,
      reason: 'lesson_completed',
      sourceEntityType: 'lesson',
      sourceEntityId: 'demo-lesson-linear-functions',
      idempotencyKey: IdempotencyKeys.generate(),
    );

    expect(outcome.xpAwarded, 15);
    expect(outcome.totalXp, 15);
    expect(outcome.level, 1);
    expect(outcome.currentStreakDays, 1);
  });

  test('retrying the same idempotency key does not double-award XP', () async {
    final key = IdempotencyKeys.generate();

    final first = await repo.awardXp(
      profileId: null,
      amount: 20,
      reason: 'quiz_passed',
      sourceEntityType: 'quiz',
      sourceEntityId: 'demo-quiz-functions-checkpoint',
      idempotencyKey: key,
    );

    // Simulate a network retry resubmitting the exact same request.
    final retried = await repo.awardXp(
      profileId: null,
      amount: 20,
      reason: 'quiz_passed',
      sourceEntityType: 'quiz',
      sourceEntityId: 'demo-quiz-functions-checkpoint',
      idempotencyKey: key,
    );

    expect(first.totalXp, 20);
    expect(first.xpAwarded, 20);

    // The retry must be a no-op: same total, zero XP awarded the second time.
    expect(retried.totalXp, 20);
    expect(retried.xpAwarded, 0);
  });

  test('a correction (failed quiz retried and improved) still earns XP, never zero', () async {
    final outcome = await repo.awardXp(
      profileId: null,
      amount: 10,
      reason: 'correction_completed',
      sourceEntityType: 'quiz',
      sourceEntityId: 'demo-quiz-functions-checkpoint',
      idempotencyKey: IdempotencyKeys.generate(),
    );

    expect(outcome.xpAwarded, greaterThan(0));
  });
}
