// Covers the mastery-update rule the diagnostic assessment (and, eventually, any future
// quiz/lesson checkpoint) relies on: the first attempt sets the estimate directly, later attempts
// blend in at the normal recency weight — see MasteryRepository's doc comment for why.

import 'package:flutter_test/flutter_test.dart';
import 'package:matricquest_sa/data/local/app_database.dart';
import 'package:matricquest_sa/data/repositories/mastery_repository.dart';

void main() {
  late AppDatabase db;
  late LocalMasteryRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = LocalMasteryRepository(db);
  });

  tearDown(() => db.close());

  test('a topic with no attempts yet is absent from fetchAll (treated as not-started)', () async {
    final result = await repo.fetchAll(['topic-1']);
    expect(result.containsKey('topic-1'), isFalse);
  });

  test(
    'the first attempt sets the mastery estimate directly to the score',
    () async {
      final mastery = await repo.recordAttempt(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        scorePercent: 50,
      );

      expect(mastery.masteryEstimate, 50);
      expect(mastery.attemptsCount, 1);
    },
  );

  test(
    'a second attempt blends in rather than replacing the estimate outright',
    () async {
      await repo.recordAttempt(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        scorePercent: 20,
      );
      final second = await repo.recordAttempt(
        topicId: 'topic-1',
        subjectId: 'subject-1',
        scorePercent: 100,
      );

      // recencyWeight 0.35 on the second attempt: 20 + (100 - 20) * 0.35 = 48
      expect(second.masteryEstimate, closeTo(48, 0.001));
      expect(second.attemptsCount, 2);
    },
  );

  test('fetchAll reflects a recorded attempt', () async {
    await repo.recordAttempt(
      topicId: 'topic-1',
      subjectId: 'subject-1',
      scorePercent: 75,
    );
    final result = await repo.fetchAll(['topic-1', 'topic-2']);

    expect(result['topic-1']!.masteryEstimate, 75);
    expect(result['topic-1']!.attemptsCount, 1);
    expect(result.containsKey('topic-2'), isFalse);
  });

  test('mastery for one topic does not leak into another', () async {
    await repo.recordAttempt(
      topicId: 'topic-1',
      subjectId: 'subject-1',
      scorePercent: 90,
    );
    final other = await repo.fetchAll(['topic-2']);
    expect(other.containsKey('topic-2'), isFalse);
  });
}
