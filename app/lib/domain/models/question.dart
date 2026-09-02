enum QuestionKind {
  multipleChoice,
  trueFalse,
  shortAnswer,
  numeric,
  essay,
  structured,
  matching,
}

QuestionKind questionKindFromDb(String value) => switch (value) {
  'multiple_choice' => QuestionKind.multipleChoice,
  'true_false' => QuestionKind.trueFalse,
  'short_answer' => QuestionKind.shortAnswer,
  'numeric' => QuestionKind.numeric,
  'essay' => QuestionKind.essay,
  'structured' => QuestionKind.structured,
  'matching' => QuestionKind.matching,
  _ => QuestionKind.shortAnswer,
};

class QuestionOption {
  final String id;
  final String label;
  final String bodyMarkdown;
  final bool isCorrect;

  const QuestionOption({
    required this.id,
    required this.label,
    required this.bodyMarkdown,
    required this.isCorrect,
  });

  factory QuestionOption.fromMap(Map<String, dynamic> map) => QuestionOption(
    id: map['id'] as String,
    label: map['label'] as String,
    bodyMarkdown: map['body_markdown'] as String,
    isCorrect: map['is_correct'] as bool? ?? false,
  );
}

/// [officialSolution] and [teachingExplanation] are kept separate end to end (schema, API, UI) so
/// the app never blurs "what the memorandum says" with "additional teaching guidance" — a
/// requirement from section 6.
class Question {
  final String id;
  final String topicId;
  final QuestionKind kind;
  final String promptMarkdown;
  final num marks;
  final List<QuestionOption> options;
  final String? officialSolution;
  final String? teachingExplanation;
  final bool isSeedDemoContent;

  const Question({
    required this.id,
    required this.topicId,
    required this.kind,
    required this.promptMarkdown,
    required this.marks,
    required this.options,
    required this.isSeedDemoContent,
    this.officialSolution,
    this.teachingExplanation,
  });

  factory Question.fromMap(
    Map<String, dynamic> map, {
    List<QuestionOption> options = const [],
  }) => Question(
    id: map['id'] as String,
    topicId: map['topic_id'] as String,
    kind: questionKindFromDb(map['kind'] as String),
    promptMarkdown: map['prompt_markdown'] as String,
    marks: map['marks'] as num? ?? 1,
    options: options,
    isSeedDemoContent: map['is_seed_demo_content'] as bool? ?? false,
    officialSolution: map['official_solution'] as String?,
    teachingExplanation: map['teaching_explanation'] as String?,
  );
}
