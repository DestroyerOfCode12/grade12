class AdminQuestion {
  final String id;
  final String topicId;
  final String kind;
  final String promptMarkdown;
  final int difficulty;
  final num marks;
  final String contentStatus;
  final String verificationStatus;
  final bool isSeedDemoContent;

  const AdminQuestion({
    required this.id,
    required this.topicId,
    required this.kind,
    required this.promptMarkdown,
    required this.difficulty,
    required this.marks,
    required this.contentStatus,
    required this.verificationStatus,
    required this.isSeedDemoContent,
  });

  factory AdminQuestion.fromMap(Map<String, dynamic> m) => AdminQuestion(
    id: m['id'] as String,
    topicId: m['topic_id'] as String,
    kind: m['kind'] as String,
    promptMarkdown: m['prompt_markdown'] as String,
    difficulty: m['difficulty'] as int? ?? 2,
    marks: m['marks'] as num? ?? 1,
    contentStatus: m['content_status'] as String? ?? 'draft',
    verificationStatus: m['verification_status'] as String? ?? 'unverified',
    isSeedDemoContent: m['is_seed_demo_content'] as bool? ?? false,
  );

  static const kinds = [
    'multiple_choice',
    'true_false',
    'short_answer',
    'numeric',
    'essay',
    'structured',
    'matching',
  ];
}

class AdminQuestionOption {
  final String id;
  final String questionId;
  final String label;
  final String bodyMarkdown;
  final bool isCorrect;
  final int sortOrder;

  const AdminQuestionOption({
    required this.id,
    required this.questionId,
    required this.label,
    required this.bodyMarkdown,
    required this.isCorrect,
    required this.sortOrder,
  });

  factory AdminQuestionOption.fromMap(Map<String, dynamic> m) =>
      AdminQuestionOption(
        id: m['id'] as String,
        questionId: m['question_id'] as String,
        label: m['label'] as String,
        bodyMarkdown: m['body_markdown'] as String,
        isCorrect: m['is_correct'] as bool? ?? false,
        sortOrder: m['sort_order'] as int? ?? 0,
      );
}

class AdminQuiz {
  final String id;
  final String topicId;
  final String title;
  final String quizKind;
  final String contentStatus;

  const AdminQuiz({
    required this.id,
    required this.topicId,
    required this.title,
    required this.quizKind,
    required this.contentStatus,
  });

  factory AdminQuiz.fromMap(Map<String, dynamic> m) => AdminQuiz(
    id: m['id'] as String,
    topicId: m['topic_id'] as String,
    title: m['title'] as String,
    quizKind: m['quiz_kind'] as String? ?? 'checkpoint',
    contentStatus: m['content_status'] as String? ?? 'draft',
  );

  static const quizKinds = [
    'checkpoint',
    'daily_challenge',
    'boss_battle',
    'diagnostic',
  ];
}
