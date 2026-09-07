/// A learner's current standing on one topic — the same shape `mastery_scores` rows take
/// server-side (docs/DATA_MODEL.md), and exactly what [MasteryRepository] reads/writes and what
/// `StudyPlanGenerator` consumes as a `TopicPlanInput`. Kept as its own tiny model so both the
/// diagnostic assessment and the study planner agree on what "mastery" means without importing
/// each other's feature code.
class TopicMastery {
  final double masteryEstimate;
  final int attemptsCount;

  const TopicMastery({
    required this.masteryEstimate,
    required this.attemptsCount,
  });

  static const notStarted = TopicMastery(masteryEstimate: 0, attemptsCount: 0);
}
