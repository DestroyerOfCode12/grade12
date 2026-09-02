/// Pure, unit-testable streak logic mirroring the server's `record_daily_activity()` function
/// (supabase/migrations/0012_functions.sql), so the offline client can advance a streak locally
/// and reconcile safely once it syncs.
///
/// Section 16 requirement: "Streak calculations must use the learner's chosen timezone,
/// defaulting South African users to Africa/Johannesburg." This class takes the learner's
/// *local calendar date* as an input rather than computing timezone conversion itself — the
/// caller is responsible for resolving `DateTime.now()` to the learner's timezone (via the
/// `timezone` package) before calling in. Keeping the conversion out of this class is what makes
/// it trivial to unit test without loading real timezone data.
class StreakState {
  final int currentStreakDays;
  final int longestStreakDays;
  final DateTime? lastActiveLocalDate; // date-only, no time-of-day component
  final int freezeTokens;

  const StreakState({
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.lastActiveLocalDate,
    required this.freezeTokens,
  });

  StreakState copyWith({
    int? currentStreakDays,
    int? longestStreakDays,
    DateTime? lastActiveLocalDate,
    int? freezeTokens,
  }) => StreakState(
    currentStreakDays: currentStreakDays ?? this.currentStreakDays,
    longestStreakDays: longestStreakDays ?? this.longestStreakDays,
    lastActiveLocalDate: lastActiveLocalDate ?? this.lastActiveLocalDate,
    freezeTokens: freezeTokens ?? this.freezeTokens,
  );
}

class StreakCalculator {
  StreakCalculator._();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Applies "the learner was active today" to [state], given today's date already resolved to
  /// the learner's local timezone. Idempotent: calling this twice on the same [todayLocal] is a
  /// no-op the second time, matching the server function's behaviour.
  static StreakState recordActivity(StreakState state, DateTime todayLocal) {
    final today = _dateOnly(todayLocal);
    final last = state.lastActiveLocalDate == null
        ? null
        : _dateOnly(state.lastActiveLocalDate!);

    if (last == today) {
      return state; // already recorded today — idempotent no-op
    }

    if (last == null) {
      return state.copyWith(
        currentStreakDays: 1,
        longestStreakDays: state.longestStreakDays < 1
            ? 1
            : state.longestStreakDays,
        lastActiveLocalDate: today,
      );
    }

    final gapDays = today.difference(last).inDays;

    if (gapDays == 1) {
      final newStreak = state.currentStreakDays + 1;
      return state.copyWith(
        currentStreakDays: newStreak,
        longestStreakDays: newStreak > state.longestStreakDays
            ? newStreak
            : state.longestStreakDays,
        lastActiveLocalDate: today,
      );
    }

    if (gapDays == 2 && state.freezeTokens > 0) {
      // Exactly one missed day, covered by a freeze token earned through learning (never bought).
      final newStreak = state.currentStreakDays + 1;
      return state.copyWith(
        currentStreakDays: newStreak,
        longestStreakDays: newStreak > state.longestStreakDays
            ? newStreak
            : state.longestStreakDays,
        lastActiveLocalDate: today,
        freezeTokens: state.freezeTokens - 1,
      );
    }

    // Streak lapsed. Section 8: never remove progress/access as punishment — only the *streak
    // counter* resets; XP, mastery, and unlocked content are untouched.
    return state.copyWith(currentStreakDays: 1, lastActiveLocalDate: today);
  }
}
