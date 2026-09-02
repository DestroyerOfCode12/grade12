/// One block of a lesson's 10-part structure (section 5). Rendered generically by
/// `features/lesson/lesson_screen.dart` — new block types can be added server-side without an
/// app release as long as the client has a fallback renderer for unknown types.
enum LessonBlockType {
  explanation,
  simplerExplanation,
  localExample,
  definitionOrFormula,
  visual,
  workedExample,
  commonMistakes,
  checkpointQuizRef,
  examStyleQuestionRef,
  correctionLessonRef,
  citation,
  unknown,
}

LessonBlockType lessonBlockTypeFromDb(String value) => switch (value) {
  'explanation' => LessonBlockType.explanation,
  'simpler_explanation' => LessonBlockType.simplerExplanation,
  'local_example' => LessonBlockType.localExample,
  'definition_or_formula' => LessonBlockType.definitionOrFormula,
  'visual' => LessonBlockType.visual,
  'worked_example' => LessonBlockType.workedExample,
  'common_mistakes' => LessonBlockType.commonMistakes,
  'checkpoint_quiz_ref' => LessonBlockType.checkpointQuizRef,
  'exam_style_question_ref' => LessonBlockType.examStyleQuestionRef,
  'correction_lesson_ref' => LessonBlockType.correctionLessonRef,
  'citation' => LessonBlockType.citation,
  _ => LessonBlockType.unknown,
};

class LessonBlock {
  final String id;
  final LessonBlockType type;
  final int sortOrder;
  final String? bodyMarkdown;
  final String? mediaUrl;
  final String? mediaAltText;

  const LessonBlock({
    required this.id,
    required this.type,
    required this.sortOrder,
    this.bodyMarkdown,
    this.mediaUrl,
    this.mediaAltText,
  });

  factory LessonBlock.fromMap(Map<String, dynamic> map) => LessonBlock(
    id: map['id'] as String,
    type: lessonBlockTypeFromDb(map['block_type'] as String),
    sortOrder: map['sort_order'] as int? ?? 0,
    bodyMarkdown: map['body_markdown'] as String?,
    mediaUrl: map['media_url'] as String?,
    mediaAltText: map['media_alt_text'] as String?,
  );
}

class Lesson {
  final String id;
  final String topicId;
  final String title;
  final int estimatedMinutes;
  final bool isSeedDemoContent;
  final List<LessonBlock> blocks;

  const Lesson({
    required this.id,
    required this.topicId,
    required this.title,
    required this.estimatedMinutes,
    required this.isSeedDemoContent,
    required this.blocks,
  });

  factory Lesson.fromMap(Map<String, dynamic> map, List<LessonBlock> blocks) =>
      Lesson(
        id: map['id'] as String,
        topicId: map['topic_id'] as String,
        title: map['title'] as String,
        estimatedMinutes: map['estimated_minutes'] as int? ?? 6,
        isSeedDemoContent: map['is_seed_demo_content'] as bool? ?? false,
        blocks: blocks,
      );
}
