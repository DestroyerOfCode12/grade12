/// Section 12: "draft, in-review, approved, published, rejected and archived content states" and
/// "No person should be able to publish educational content merely because they can generate it
/// with AI." This file is the single source of truth for which transitions are legal, so every
/// screen (subjects, lessons, questions, papers) enforces the same rules instead of each screen
/// re-deciding independently.
enum ContentStatus { draft, inReview, approved, published, rejected, archived }

ContentStatus contentStatusFromDb(String value) => switch (value) {
  'draft' => ContentStatus.draft,
  'in_review' => ContentStatus.inReview,
  'approved' => ContentStatus.approved,
  'published' => ContentStatus.published,
  'rejected' => ContentStatus.rejected,
  'archived' => ContentStatus.archived,
  _ => ContentStatus.draft,
};

String contentStatusToDb(ContentStatus status) => switch (status) {
  ContentStatus.draft => 'draft',
  ContentStatus.inReview => 'in_review',
  ContentStatus.approved => 'approved',
  ContentStatus.published => 'published',
  ContentStatus.rejected => 'rejected',
  ContentStatus.archived => 'archived',
};

String contentStatusLabel(ContentStatus status) => switch (status) {
  ContentStatus.draft => 'Draft',
  ContentStatus.inReview => 'In review',
  ContentStatus.approved => 'Approved',
  ContentStatus.published => 'Published',
  ContentStatus.rejected => 'Rejected',
  ContentStatus.archived => 'Archived',
};

class ContentLifecycle {
  ContentLifecycle._();

  /// The legal next states from a given state. Publishing is reachable only from `approved` —
  /// draft/in_review content can never go straight to `published`, which is what makes "review
  /// before publish" an enforced workflow rather than a convention (section 12).
  static const Map<ContentStatus, List<ContentStatus>> _transitions = {
    ContentStatus.draft: [ContentStatus.inReview, ContentStatus.archived],
    ContentStatus.inReview: [
      ContentStatus.approved,
      ContentStatus.rejected,
      ContentStatus.draft,
    ],
    ContentStatus.approved: [ContentStatus.published, ContentStatus.draft],
    ContentStatus.published: [ContentStatus.archived, ContentStatus.draft],
    ContentStatus.rejected: [ContentStatus.draft, ContentStatus.archived],
    ContentStatus.archived: [ContentStatus.draft],
  };

  static List<ContentStatus> allowedNextStates(ContentStatus current) =>
      List.unmodifiable(_transitions[current] ?? const []);

  static bool canTransition(ContentStatus from, ContentStatus to) =>
      _transitions[from]?.contains(to) ?? false;

  /// Section 2/12: unverified/AI-generated/imported content must not be published. Callers
  /// should check this before allowing a transition into `published`, in addition to the
  /// draft->in_review->approved->published state-machine gate above.
  static bool canPublish({
    required bool isSeedDemoContent,
    required String verificationStatus,
  }) {
    if (isSeedDemoContent) return false;
    return verificationStatus == 'verified' ||
        verificationStatus == 'source_recorded';
  }
}
