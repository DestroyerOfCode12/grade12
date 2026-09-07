import '../../domain/models/lesson.dart';
import '../../domain/models/question.dart';
import '../../domain/models/subject.dart';

/// Local-dev-mode / offline-seed content mirroring supabase/seed/0001 and 0002. Everything here
/// is explicitly demo content (`isSeedDemoContent = true` where applicable) so the UI's "Demo
/// content — not yet curriculum-verified" badge (see widgets/demo_content_badge.dart) always
/// shows for it, exactly as it would for the same rows read from Postgres. This file exists so
/// the full onboarding -> lesson -> quiz -> XP -> paper -> results journey is runnable with zero
/// backend configured (section 3: "If external credentials are unavailable, implement a local
/// development mode with seeded data").
class DemoCatalogue {
  DemoCatalogue._();

  static const mathematicsSubjectId = 'demo-subject-mathematics';
  static const functionsTopicId = 'demo-topic-functions';
  static const functionsTopicTitle = 'Functions and Graphs (demo)';
  static const linearFunctionsLessonId = 'demo-lesson-linear-functions';
  static const checkpointQuizId = 'demo-quiz-functions-checkpoint';

  static List<Subject> subjects() => const [
    Subject(
      id: mathematicsSubjectId,
      code: 'mathematics',
      name: 'Mathematics',
      category: 'Mathematics and Sciences',
      level: SubjectLevel.core,
      contentStatus: ContentStatus.published,
      verificationStatus: VerificationStatus.sourceRecorded,
      papersAvailable: true,
      lessonsInReview: false,
      fullCourseAvailable: false,
    ),
    Subject(
      id: 'demo-subject-physical-sciences',
      code: 'physical_sciences',
      name: 'Physical Sciences',
      category: 'Mathematics and Sciences',
      level: SubjectLevel.core,
      contentStatus: ContentStatus.draft,
      verificationStatus: VerificationStatus.sourceRecorded,
      papersAvailable: false,
      lessonsInReview: true,
      fullCourseAvailable: false,
    ),
    Subject(
      id: 'demo-subject-english-hl',
      code: 'english_hl',
      name: 'English',
      category: 'Languages',
      level: SubjectLevel.homeLanguage,
      contentStatus: ContentStatus.draft,
      verificationStatus: VerificationStatus.sourceRecorded,
      papersAvailable: false,
      lessonsInReview: false,
      fullCourseAvailable: false,
    ),
    Subject(
      id: 'demo-subject-accounting',
      code: 'accounting',
      name: 'Accounting',
      category: 'Commerce and Business',
      level: SubjectLevel.core,
      contentStatus: ContentStatus.draft,
      verificationStatus: VerificationStatus.sourceRecorded,
      papersAvailable: false,
      lessonsInReview: false,
      fullCourseAvailable: false,
    ),
    Subject(
      id: 'demo-subject-life-sciences',
      code: 'life_sciences',
      name: 'Life Sciences',
      category: 'Mathematics and Sciences',
      level: SubjectLevel.core,
      contentStatus: ContentStatus.draft,
      verificationStatus: VerificationStatus.sourceRecorded,
      papersAvailable: false,
      lessonsInReview: false,
      fullCourseAvailable: false,
    ),
    Subject(
      id: 'demo-subject-geography',
      code: 'geography',
      name: 'Geography',
      category: 'Humanities',
      level: SubjectLevel.core,
      contentStatus: ContentStatus.draft,
      verificationStatus: VerificationStatus.sourceRecorded,
      papersAvailable: false,
      lessonsInReview: false,
      fullCourseAvailable: false,
    ),
  ];

  static Lesson linearFunctionsLesson() => Lesson(
    id: linearFunctionsLessonId,
    topicId: functionsTopicId,
    title: 'Understanding Linear Functions (demo)',
    estimatedMinutes: 6,
    isSeedDemoContent: true,
    blocks: [
      const LessonBlock(
        id: 'b1',
        type: LessonBlockType.explanation,
        sortOrder: 1,
        bodyMarkdown: 'A linear function has the form y = mx + c. Here m is the gradient (how steep the line is) and c is the y-intercept (where the line crosses the y-axis).',
      ),
      const LessonBlock(
        id: 'b2',
        type: LessonBlockType.simplerExplanation,
        sortOrder: 2,
        bodyMarkdown: 'Think of it as: start at c, then for every step of 1 to the right, go up (or down) by m.',
      ),
      const LessonBlock(
        id: 'b3',
        type: LessonBlockType.localExample,
        sortOrder: 3,
        bodyMarkdown: 'A prepaid airtime deal costs R2 to connect plus R0.80 per minute. Total cost after x minutes is y = 0.80x + 2 — a linear function you use every time you check your airtime balance.',
      ),
      const LessonBlock(
        id: 'b4',
        type: LessonBlockType.definitionOrFormula,
        sortOrder: 4,
        bodyMarkdown: 'Gradient formula: m = (y2 − y1) / (x2 − x1). Standard form: y = mx + c.',
      ),
      const LessonBlock(
        id: 'b5',
        type: LessonBlockType.workedExample,
        sortOrder: 5,
        bodyMarkdown: 'Find the equation of the line through (1, 5) and (3, 9).\n\nm = (9 − 5) / (3 − 1) = 2\n\nUsing y = mx + c and (1, 5): 5 = 2(1) + c → c = 3\n\nSo y = 2x + 3.',
      ),
      const LessonBlock(
        id: 'b6',
        type: LessonBlockType.commonMistakes,
        sortOrder: 6,
        bodyMarkdown: 'Learners often subtract x and y values in the wrong order when finding the gradient — always keep (y2 − y1) over (x2 − x1) using the same two points in the same order on top and bottom.',
      ),
      const LessonBlock(
        id: 'b7',
        type: LessonBlockType.citation,
        sortOrder: 7,
        bodyMarkdown: 'Demo lesson only — not yet checked against the official CAPS Mathematics document.',
      ),
    ],
  );

  static List<Question> checkpointQuestions() => [
    Question(
      id: 'demo-q1',
      topicId: functionsTopicId,
      kind: QuestionKind.multipleChoice,
      promptMarkdown: 'What is the gradient of the line y = 4x − 7?',
      marks: 1,
      isSeedDemoContent: true,
      officialSolution: 'A: 4',
      teachingExplanation:
          'In y = mx + c, the coefficient of x is the gradient, so m = 4.',
      options: const [
        QuestionOption(
          id: 'o1',
          label: 'A',
          bodyMarkdown: '4',
          isCorrect: true,
        ),
        QuestionOption(
          id: 'o2',
          label: 'B',
          bodyMarkdown: '-7',
          isCorrect: false,
        ),
        QuestionOption(
          id: 'o3',
          label: 'C',
          bodyMarkdown: '7',
          isCorrect: false,
        ),
        QuestionOption(
          id: 'o4',
          label: 'D',
          bodyMarkdown: '-4',
          isCorrect: false,
        ),
      ],
    ),
    Question(
      id: 'demo-q2',
      topicId: functionsTopicId,
      kind: QuestionKind.multipleChoice,
      promptMarkdown:
          'A line passes through (0, 3) and (2, 11). What is the gradient?',
      marks: 2,
      isSeedDemoContent: true,
      officialSolution: 'B: 4',
      teachingExplanation: 'm = (11 − 3) / (2 − 0) = 8 / 2 = 4.',
      options: const [
        QuestionOption(
          id: 'o5',
          label: 'A',
          bodyMarkdown: '2',
          isCorrect: false,
        ),
        QuestionOption(
          id: 'o6',
          label: 'B',
          bodyMarkdown: '4',
          isCorrect: true,
        ),
        QuestionOption(
          id: 'o7',
          label: 'C',
          bodyMarkdown: '8',
          isCorrect: false,
        ),
        QuestionOption(
          id: 'o8',
          label: 'D',
          bodyMarkdown: '3',
          isCorrect: false,
        ),
      ],
    ),
  ];
}
