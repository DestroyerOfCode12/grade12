import 'package:flutter_test/flutter_test.dart';
import 'package:matricquest_sa/domain/services/mastery_calculator.dart';

void main() {
  group('MasteryCalculator.updateEstimate', () {
    test('moves toward the new score by the recency weight', () {
      final result = MasteryCalculator.updateEstimate(
        previousEstimate: 40,
        newScorePercent: 80,
        recencyWeight: 0.5,
      );
      expect(result, 60); // halfway between 40 and 80
    });

    test('clamps to [0, 100] even with an out-of-range input', () {
      expect(
        MasteryCalculator.updateEstimate(
          previousEstimate: 90,
          newScorePercent: 150,
        ),
        lessThanOrEqualTo(100),
      );
      expect(
        MasteryCalculator.updateEstimate(
          previousEstimate: 10,
          newScorePercent: -20,
        ),
        greaterThanOrEqualTo(0),
      );
    });

    test('a correction (improved retry) can raise mastery back up', () {
      final afterMistake = MasteryCalculator.updateEstimate(
        previousEstimate: 70,
        newScorePercent: 20,
      );
      final afterCorrection = MasteryCalculator.updateEstimate(
        previousEstimate: afterMistake,
        newScorePercent: 100,
      );
      expect(afterCorrection, greaterThan(afterMistake));
    });
  });

  group('MasteryCalculator.labelFor', () {
    test('no attempts yet is notStarted regardless of estimate value', () {
      expect(
        MasteryCalculator.labelFor(0, attemptsCount: 0),
        ReadinessLabel.notStarted,
      );
    });

    test('threshold boundaries map to the right label', () {
      expect(
        MasteryCalculator.labelFor(10, attemptsCount: 1),
        ReadinessLabel.needsWork,
      );
      expect(
        MasteryCalculator.labelFor(50, attemptsCount: 1),
        ReadinessLabel.developing,
      );
      expect(
        MasteryCalculator.labelFor(70, attemptsCount: 1),
        ReadinessLabel.onTrack,
      );
      expect(
        MasteryCalculator.labelFor(90, attemptsCount: 1),
        ReadinessLabel.strong,
      );
    });
  });

  group('XpRules.levelForTotalXp', () {
    test('starts at level 1 with zero XP', () {
      expect(XpRules.levelForTotalXp(0), 1);
    });

    test('advances levels using growing thresholds', () {
      expect(XpRules.levelForTotalXp(99), 1);
      expect(XpRules.levelForTotalXp(100), 2);
      expect(XpRules.levelForTotalXp(100 + 200 - 1), 2);
      expect(XpRules.levelForTotalXp(100 + 200), 3);
    });
  });
}
