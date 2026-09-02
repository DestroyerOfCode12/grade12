import 'package:flutter_test/flutter_test.dart';
import 'package:matricquest_sa/domain/services/streak_calculator.dart';

void main() {
  group('StreakCalculator', () {
    test('first ever activity starts a 1-day streak', () {
      const initial = StreakState(
        currentStreakDays: 0,
        longestStreakDays: 0,
        lastActiveLocalDate: null,
        freezeTokens: 0,
      );

      final result = StreakCalculator.recordActivity(
        initial,
        DateTime(2026, 9, 2),
      );

      expect(result.currentStreakDays, 1);
      expect(result.longestStreakDays, 1);
      expect(result.lastActiveLocalDate, DateTime(2026, 9, 2));
    });

    test('consecutive day activity increments the streak', () {
      final state = StreakState(
        currentStreakDays: 5,
        longestStreakDays: 5,
        lastActiveLocalDate: DateTime(2026, 9, 1),
        freezeTokens: 0,
      );

      final result = StreakCalculator.recordActivity(
        state,
        DateTime(2026, 9, 2),
      );

      expect(result.currentStreakDays, 6);
      expect(result.longestStreakDays, 6);
    });

    test(
      'calling recordActivity twice on the same local day is idempotent',
      () {
        final state = StreakState(
          currentStreakDays: 3,
          longestStreakDays: 3,
          lastActiveLocalDate: DateTime(2026, 9, 2),
          freezeTokens: 0,
        );

        final result = StreakCalculator.recordActivity(
          state,
          DateTime(2026, 9, 2),
        );

        expect(result.currentStreakDays, 3);
        expect(result.lastActiveLocalDate, DateTime(2026, 9, 2));
      },
    );

    test('a missed day with no freeze token resets the streak to 1, not 0', () {
      final state = StreakState(
        currentStreakDays: 10,
        longestStreakDays: 10,
        lastActiveLocalDate: DateTime(2026, 9, 1),
        freezeTokens: 0,
      );

      // Two days later — one full day was skipped.
      final result = StreakCalculator.recordActivity(
        state,
        DateTime(2026, 9, 3),
      );

      expect(result.currentStreakDays, 1);
      expect(
        result.longestStreakDays,
        10,
        reason: 'longest streak record must not be erased',
      );
    });

    test(
      'a single missed day is covered by a freeze token, earned not purchased',
      () {
        final state = StreakState(
          currentStreakDays: 10,
          longestStreakDays: 10,
          lastActiveLocalDate: DateTime(2026, 9, 1),
          freezeTokens: 2,
        );

        final result = StreakCalculator.recordActivity(
          state,
          DateTime(2026, 9, 3),
        );

        expect(result.currentStreakDays, 11);
        expect(
          result.freezeTokens,
          1,
          reason: 'exactly one freeze token should be consumed',
        );
      },
    );

    test(
      'time-of-day component is ignored — only the calendar date matters',
      () {
        final state = StreakState(
          currentStreakDays: 1,
          longestStreakDays: 1,
          lastActiveLocalDate: DateTime(2026, 9, 1, 23, 59),
          freezeTokens: 0,
        );

        final result = StreakCalculator.recordActivity(
          state,
          DateTime(2026, 9, 2, 0, 1),
        );

        expect(result.currentStreakDays, 2);
      },
    );
  });
}
