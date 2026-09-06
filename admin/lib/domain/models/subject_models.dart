class AdminSubject {
  final String id;
  final String code;
  final String name;
  final String category;
  final String level;
  final String contentStatus;
  final String verificationStatus;
  final bool papersAvailable;
  final bool lessonsInReview;
  final bool fullCourseAvailable;
  final int sortOrder;

  const AdminSubject({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.level,
    required this.contentStatus,
    required this.verificationStatus,
    required this.papersAvailable,
    required this.lessonsInReview,
    required this.fullCourseAvailable,
    required this.sortOrder,
  });

  factory AdminSubject.fromMap(Map<String, dynamic> m) => AdminSubject(
    id: m['id'] as String,
    code: m['code'] as String,
    name: m['name'] as String,
    category: m['category'] as String,
    level: m['level'] as String? ?? 'core',
    contentStatus: m['content_status'] as String? ?? 'draft',
    verificationStatus: m['verification_status'] as String? ?? 'unverified',
    papersAvailable: m['papers_available'] as bool? ?? false,
    lessonsInReview: m['lessons_in_review'] as bool? ?? false,
    fullCourseAvailable: m['full_course_available'] as bool? ?? false,
    sortOrder: m['sort_order'] as int? ?? 0,
  );
}

class AdminTopic {
  final String id;
  final String subjectId;
  final String? parentTopicId;
  final String title;
  final String term;
  final String contentStatus;
  final String verificationStatus;
  final int sortOrder;

  const AdminTopic({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.term,
    required this.contentStatus,
    required this.verificationStatus,
    required this.sortOrder,
    this.parentTopicId,
  });

  factory AdminTopic.fromMap(Map<String, dynamic> m) => AdminTopic(
    id: m['id'] as String,
    subjectId: m['subject_id'] as String,
    parentTopicId: m['parent_topic_id'] as String?,
    title: m['title'] as String,
    term: m['term'] as String? ?? 'term_1',
    contentStatus: m['content_status'] as String? ?? 'draft',
    verificationStatus: m['verification_status'] as String? ?? 'unverified',
    sortOrder: m['sort_order'] as int? ?? 0,
  );
}

class AdminLesson {
  final String id;
  final String topicId;
  final String title;
  final int estimatedMinutes;
  final String contentStatus;
  final String verificationStatus;
  final bool isSeedDemoContent;

  const AdminLesson({
    required this.id,
    required this.topicId,
    required this.title,
    required this.estimatedMinutes,
    required this.contentStatus,
    required this.verificationStatus,
    required this.isSeedDemoContent,
  });

  factory AdminLesson.fromMap(Map<String, dynamic> m) => AdminLesson(
    id: m['id'] as String,
    topicId: m['topic_id'] as String,
    title: m['title'] as String,
    estimatedMinutes: m['estimated_minutes'] as int? ?? 6,
    contentStatus: m['content_status'] as String? ?? 'draft',
    verificationStatus: m['verification_status'] as String? ?? 'unverified',
    isSeedDemoContent: m['is_seed_demo_content'] as bool? ?? false,
  );
}

class AdminLessonBlock {
  final String id;
  final String lessonId;
  final String blockType;
  final int sortOrder;
  final String? bodyMarkdown;

  const AdminLessonBlock({
    required this.id,
    required this.lessonId,
    required this.blockType,
    required this.sortOrder,
    this.bodyMarkdown,
  });

  factory AdminLessonBlock.fromMap(Map<String, dynamic> m) => AdminLessonBlock(
    id: m['id'] as String,
    lessonId: m['lesson_id'] as String,
    blockType: m['block_type'] as String,
    sortOrder: m['sort_order'] as int? ?? 0,
    bodyMarkdown: m['body_markdown'] as String?,
  );

  static const allBlockTypes = [
    'explanation',
    'simpler_explanation',
    'local_example',
    'definition_or_formula',
    'visual',
    'worked_example',
    'common_mistakes',
    'checkpoint_quiz_ref',
    'exam_style_question_ref',
    'correction_lesson_ref',
    'citation',
  ];
}
