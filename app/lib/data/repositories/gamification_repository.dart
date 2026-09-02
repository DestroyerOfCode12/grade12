import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/services/mastery_calculator.dart';
import '../../domain/services/streak_calculator.dart';
import '../local/app_database.dart';

/// Result of a gamification action, enough for the UI to show an XP toast / level-up / streak
/// update without a second round-trip.
class GamificationOutcome {
  final int xpAwarded;
  final int totalXp;
  final int level;
  final int currentStreakDays;

  const GamificationOutcome({
    required this.xpAwarded,
    required this.totalXp,
    required this.level,
    required this.currentStreakDays,
  });
}

/// Owns both the "online, signed in" path (Supabase RPCs `grant_xp` / `record_daily_activity`,
/// section 13) and the "guest / offline" path (local SQLite `local_learner_state` +
/// `outbox_entries`, section 10). The same idempotency key is used in both paths and is reused
/// verbatim if an offline write is later replayed against Supabase, so a learner who finishes a
/// quiz on the bus with no signal and syncs later can never be awarded XP twice.
class GamificationRepository {
  final SupabaseClient? client; // null in local dev / guest mode
  final AppDatabase db;
  static const _guestProfileId = 'guest';

  GamificationRepository({required this.client, required this.db});

  Future<GamificationOutcome> awardXp({
    required String? profileId,
    required int amount,
    required String reason,
    required String? sourceEntityType,
    required String? sourceEntityId,
    required String idempotencyKey,
  }) async {
    if (client != null && profileId != null) {
      final rows = await client!.rpc(
        'grant_xp',
        params: {
          'p_profile_id': profileId,
          'p_amount': amount,
          'p_reason': reason,
          'p_source_entity_type': sourceEntityType,
          'p_source_entity_id': sourceEntityId,
          'p_idempotency_key': idempotencyKey,
        },
      );
      final row = (rows as List).first as Map<String, dynamic>;
      final totalXp = (row['total_xp'] as num).toInt();
      final streak = await _recordDailyActivityRemote(profileId);
      return GamificationOutcome(
        xpAwarded: amount,
        totalXp: totalXp,
        level: XpRules.levelForTotalXp(totalXp),
        currentStreakDays: streak,
      );
    }

    return _awardXpLocal(
      profileId: profileId ?? _guestProfileId,
      amount: amount,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<int> _recordDailyActivityRemote(String profileId) async {
    final rows = await client!.rpc(
      'record_daily_activity',
      params: {'p_profile_id': profileId},
    );
    final row = (rows as List).first as Map<String, dynamic>;
    return (row['current_streak_days'] as num).toInt();
  }

  GamificationOutcome _awardXpLocal({
    required String profileId,
    required int amount,
    required String idempotencyKey,
  }) {
    // Idempotency, offline: the outbox row's primary key IS the idempotency key. isNewRequest is
    // false when this exact key was already processed (a retry) — in that case we must NOT credit
    // XP again, only return the current (unchanged) state, or the outbox row would be decorative
    // instead of an actual guard (section 13).
    final isNewRequest = db.enqueueOutboxEntry(
      idempotencyKey: idempotencyKey,
      kind: 'xp_grant',
      payloadJson:
          '{"profileId":"$profileId","amount":$amount,"idempotencyKey":"$idempotencyKey"}',
    );

    final existing = db.learnerState(profileId);

    var totalXp = existing?['total_xp'] as int? ?? 0;
    var streakState = StreakState(
      currentStreakDays: existing?['current_streak_days'] as int? ?? 0,
      longestStreakDays: existing?['longest_streak_days'] as int? ?? 0,
      lastActiveLocalDate:
          (existing?['last_active_local_date'] as String?) == null
          ? null
          : DateTime.parse(existing!['last_active_local_date'] as String),
      freezeTokens: existing?['freeze_tokens'] as int? ?? 0,
    );

    if (!isNewRequest) {
      // Duplicate/retried request: report the current, already-up-to-date state without
      // crediting XP a second time.
      return GamificationOutcome(
        xpAwarded: 0,
        totalXp: totalXp,
        level: XpRules.levelForTotalXp(totalXp),
        currentStreakDays: streakState.currentStreakDays,
      );
    }

    totalXp += amount;
    final updatedStreak = StreakCalculator.recordActivity(
      streakState,
      DateTime.now(),
    );

    db.upsertLearnerState(
      profileId: profileId,
      totalXp: totalXp,
      currentStreakDays: updatedStreak.currentStreakDays,
      longestStreakDays: updatedStreak.longestStreakDays,
      lastActiveLocalDate: updatedStreak.lastActiveLocalDate?.toIso8601String(),
      freezeTokens: updatedStreak.freezeTokens,
    );

    return GamificationOutcome(
      xpAwarded: amount,
      totalXp: totalXp,
      level: XpRules.levelForTotalXp(totalXp),
      currentStreakDays: updatedStreak.currentStreakDays,
    );
  }

  GamificationOutcome currentState(String? profileId) {
    final id = profileId ?? _guestProfileId;
    final row = db.learnerState(id);
    final totalXp = row?['total_xp'] as int? ?? 0;
    return GamificationOutcome(
      xpAwarded: 0,
      totalXp: totalXp,
      level: XpRules.levelForTotalXp(totalXp),
      currentStreakDays: row?['current_streak_days'] as int? ?? 0,
    );
  }
}
