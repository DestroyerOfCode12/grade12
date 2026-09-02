/// Content lifecycle mirrored from `content_status` (Postgres enum) — see
/// supabase/migrations/0001_extensions_and_enums.sql and docs/DATA_MODEL.md.
enum ContentStatus { draft, inReview, approved, published, rejected, archived }

enum VerificationStatus {
  unverified,
  sourceRecorded,
  pendingManualReview,
  verified,
  disputed,
}

enum SubjectLevel { homeLanguage, firstAdditional, secondAdditional, core }

ContentStatus contentStatusFromDb(String value) => switch (value) {
  'draft' => ContentStatus.draft,
  'in_review' => ContentStatus.inReview,
  'approved' => ContentStatus.approved,
  'published' => ContentStatus.published,
  'rejected' => ContentStatus.rejected,
  'archived' => ContentStatus.archived,
  _ => ContentStatus.draft,
};

VerificationStatus verificationStatusFromDb(String value) => switch (value) {
  'unverified' => VerificationStatus.unverified,
  'source_recorded' => VerificationStatus.sourceRecorded,
  'pending_manual_review' => VerificationStatus.pendingManualReview,
  'verified' => VerificationStatus.verified,
  'disputed' => VerificationStatus.disputed,
  _ => VerificationStatus.unverified,
};

SubjectLevel subjectLevelFromDb(String value) => switch (value) {
  'home_language' => SubjectLevel.homeLanguage,
  'first_additional' => SubjectLevel.firstAdditional,
  'second_additional' => SubjectLevel.secondAdditional,
  _ => SubjectLevel.core,
};

/// A single Grade 12 CAPS subject, as shown in Subject Selection / All Subjects (section 4/11).
///
/// [papersAvailable] / [lessonsInReview] / [fullCourseAvailable] intentionally let the catalogue be
/// honest about partial coverage instead of pretending every subject is complete (section 2:
/// "A subject may appear in the catalogue while its status transparently shows...").
class Subject {
  final String id;
  final String code;
  final String name;
  final String category;
  final SubjectLevel level;
  final ContentStatus contentStatus;
  final VerificationStatus verificationStatus;
  final bool papersAvailable;
  final bool lessonsInReview;
  final bool fullCourseAvailable;
  final String? iconKey;

  const Subject({
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
    this.iconKey,
  });

  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
    id: map['id'] as String,
    code: map['code'] as String,
    name: map['name'] as String,
    category: map['category'] as String,
    level: subjectLevelFromDb(map['level'] as String? ?? 'core'),
    contentStatus: contentStatusFromDb(
      map['content_status'] as String? ?? 'draft',
    ),
    verificationStatus: verificationStatusFromDb(
      map['verification_status'] as String? ?? 'unverified',
    ),
    papersAvailable: map['papers_available'] as bool? ?? false,
    lessonsInReview: map['lessons_in_review'] as bool? ?? false,
    fullCourseAvailable: map['full_course_available'] as bool? ?? false,
    iconKey: map['icon_key'] as String?,
  );

  /// Human-readable coverage label shown on subject cards, per section 5 of the product brief.
  String get coverageLabel {
    if (fullCourseAvailable) return 'Full learning course available';
    if (lessonsInReview) return 'Lessons in review';
    if (papersAvailable) return 'Papers available';
    return 'Coming soon';
  }
}
