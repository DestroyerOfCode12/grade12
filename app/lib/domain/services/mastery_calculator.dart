/// Readiness label thresholds. Section 9 requires these be called "mastery estimates" or
/// "readiness scores" and never presented as a guarantee of a final NSC result.
enum ReadinessLabel { notStarted, needsWork, developing, onTrack, strong }

class MasteryCalculator {
  MasteryCalculator._();

  /// Simple, explainable recency-weighted average: each new attempt's correctness score updates
  /// the running estimate, weighted so recent performance matters more than old performance
  /// (a learner who struggled early but has since improved should see that reflected). This is
  /// intentionally NOT a black-box ML model — every number it produces must be explainable to a
  /// learner and a curriculum reviewer.
  ///
  /// [previousEstimate] and [newScorePercent] are both 0-100. [recencyWeight] in (0,1] controls
  /// how much the new attempt moves the estimate; 0.35 means a single new attempt can move the
  /// estimate up to 35% of the way from its old value to the new score.
  static double updateEstimate({
    required double previousEstimate,
    required double newScorePercent,
    double recencyWeight = 0.35,
  }) {
    assert(recencyWeight > 0 && recencyWeight <= 1);
    final clampedScore = newScorePercent.clamp(0, 100).toDouble();
    final next =
        previousEstimate + (clampedScore - previousEstimate) * recencyWeight;
    return next.clamp(0, 100).toDouble();
  }

  static ReadinessLabel labelFor(
    double masteryEstimate, {
    int attemptsCount = 0,
  }) {
    if (attemptsCount == 0) return ReadinessLabel.notStarted;
    if (masteryEstimate < 40) return ReadinessLabel.needsWork;
    if (masteryEstimate < 65) return ReadinessLabel.developing;
    if (masteryEstimate < 85) return ReadinessLabel.onTrack;
    return ReadinessLabel.strong;
  }

  static String displayLabel(ReadinessLabel label) => switch (label) {
    ReadinessLabel.notStarted => 'Not started',
    ReadinessLabel.needsWork => 'Needs work',
    ReadinessLabel.developing => 'Developing',
    ReadinessLabel.onTrack => 'On track',
    ReadinessLabel.strong => 'Strong',
  };
}

/// XP award rules. Kept as pure, explainable, tunable constants (section 8: XP must reflect real
/// learning — a correction counts, not just first-try success).
class XpRules {
  XpRules._();

  static const int lessonCompleted = 15;
  static const int quizPassed = 20;
  static const int correctionCompleted =
      10; // learners gain XP for fixing a mistake, not losing it
  static const int dailyChallenge = 25;
  static const int bossBattle = 50;
  static const int paperAttemptCompleted = 40;

  static int levelForTotalXp(int totalXp) {
    // Level thresholds grow quadratically so early levels come quickly (onboarding momentum)
    // and later levels require sustained study — same curve style as Duolingo-class apps.
    var level = 1;
    var threshold = 100;
    var remaining = totalXp;
    while (remaining >= threshold) {
      remaining -= threshold;
      level++;
      threshold = 100 * level;
    }
    return level;
  }
}
