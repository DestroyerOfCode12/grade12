import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/topic_mastery.dart';
import '../../domain/services/mastery_calculator.dart';
import '../local/app_database.dart';

/// Reads and records `mastery_scores` (docs/DATA_MODEL.md) — the single source of truth
/// `StudyPlanGenerator` schedules against. The diagnostic assessment is this repository's first
/// caller, but [recordAttempt] is deliberately generic ("record one attempt's result against a
/// topic"), not "record a diagnostic result" — a future quiz/lesson-checkpoint feature should call
/// the same method rather than inventing a second mastery-update path (see
/// docs/CONTINUATION.md: this was flagged as a gap before the diagnostic assessment existed).
abstract class MasteryRepository {
  Future<Map<String, TopicMastery>> fetchAll(Iterable<String> topicIds);

  /// Records one attempt's score (0-100) against a topic, updating its running mastery estimate.
  /// The very first attempt on a topic sets the estimate directly (recency weight 1.0) rather than
  /// diluting a real signal against a meaningless "0" baseline; later attempts blend in using
  /// [MasteryCalculator]'s normal recency weight.
  Future<TopicMastery> recordAttempt({
    required String topicId,
    required String subjectId,
    required double scorePercent,
  });
}

class SupabaseMasteryRepository implements MasteryRepository {
  final SupabaseClient client;
  final String profileId;
  SupabaseMasteryRepository(this.client, this.profileId);

  @override
  Future<Map<String, TopicMastery>> fetchAll(Iterable<String> topicIds) async {
    final ids = topicIds.toList();
    if (ids.isEmpty) return {};
    final rows = await client
        .from('mastery_scores')
        .select('topic_id, mastery_estimate, attempts_count')
        .eq('profile_id', profileId)
        .inFilter('topic_id', ids);
    return {
      for (final r in (rows as List))
        r['topic_id'] as String: TopicMastery(
          masteryEstimate: (r['mastery_estimate'] as num).toDouble(),
          attemptsCount: r['attempts_count'] as int,
        ),
    };
  }

  @override
  Future<TopicMastery> recordAttempt({
    required String topicId,
    required String subjectId,
    required double scorePercent,
  }) async {
    final existingRows = await client
        .from('mastery_scores')
        .select('mastery_estimate, attempts_count')
        .eq('profile_id', profileId)
        .eq('topic_id', topicId)
        .maybeSingle();

    final previousEstimate =
        (existingRows?['mastery_estimate'] as num?)?.toDouble() ?? 0;
    final previousAttempts = existingRows?['attempts_count'] as int? ?? 0;

    final newEstimate = MasteryCalculator.updateEstimate(
      previousEstimate: previousEstimate,
      newScorePercent: scorePercent,
      recencyWeight: previousAttempts == 0 ? 1.0 : 0.35,
    );
    final newAttempts = previousAttempts + 1;
    final label = MasteryCalculator.labelFor(
      newEstimate,
      attemptsCount: newAttempts,
    );

    await client.from('mastery_scores').upsert({
      'profile_id': profileId,
      'topic_id': topicId,
      'mastery_estimate': newEstimate,
      'attempts_count': newAttempts,
      'readiness_label': _labelToDb(label),
      'last_attempt_at': DateTime.now().toIso8601String(),
    }, onConflict: 'profile_id,topic_id');

    return TopicMastery(
      masteryEstimate: newEstimate,
      attemptsCount: newAttempts,
    );
  }

  String _labelToDb(ReadinessLabel label) => switch (label) {
    ReadinessLabel.notStarted => 'not_started',
    ReadinessLabel.needsWork => 'needs_work',
    ReadinessLabel.developing => 'developing',
    ReadinessLabel.onTrack => 'on_track',
    ReadinessLabel.strong => 'strong',
  };
}

/// Local dev mode / guest mode mirror, backed by the `local_mastery_scores` table
/// (`app_database.dart`) — same update rule as the Supabase path, kept in one place
/// ([MasteryCalculator]) so guest and signed-in learners see mastery move the same way.
class LocalMasteryRepository implements MasteryRepository {
  final AppDatabase db;
  static const _guestProfileId = 'guest';
  LocalMasteryRepository(this.db);

  @override
  Future<Map<String, TopicMastery>> fetchAll(Iterable<String> topicIds) async {
    final result = <String, TopicMastery>{};
    for (final topicId in topicIds) {
      final row = db.masteryScore(_guestProfileId, topicId);
      if (row != null) {
        result[topicId] = TopicMastery(
          masteryEstimate: row['mastery_estimate'] as double,
          attemptsCount: row['attempts_count'] as int,
        );
      }
    }
    return result;
  }

  @override
  Future<TopicMastery> recordAttempt({
    required String topicId,
    required String subjectId,
    required double scorePercent,
  }) async {
    final existing = db.masteryScore(_guestProfileId, topicId);
    final previousEstimate = existing?['mastery_estimate'] as double? ?? 0;
    final previousAttempts = existing?['attempts_count'] as int? ?? 0;

    final newEstimate = MasteryCalculator.updateEstimate(
      previousEstimate: previousEstimate,
      newScorePercent: scorePercent,
      recencyWeight: previousAttempts == 0 ? 1.0 : 0.35,
    );
    final newAttempts = previousAttempts + 1;

    db.upsertMasteryScore(
      profileId: _guestProfileId,
      topicId: topicId,
      subjectId: subjectId,
      masteryEstimate: newEstimate,
      attemptsCount: newAttempts,
    );

    return TopicMastery(
      masteryEstimate: newEstimate,
      attemptsCount: newAttempts,
    );
  }
}
