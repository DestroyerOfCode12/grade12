class AdminPaper {
  final String id;
  final String subjectId;
  final int examYear;
  final String session;
  final int paperNumber;
  final String languageCode;
  final String examType;
  final String title;
  final String sourceUrl;
  final String? fileChecksum;
  final String associationConfidence;
  final String contentStatus;

  const AdminPaper({
    required this.id,
    required this.subjectId,
    required this.examYear,
    required this.session,
    required this.paperNumber,
    required this.languageCode,
    required this.examType,
    required this.title,
    required this.sourceUrl,
    required this.associationConfidence,
    required this.contentStatus,
    this.fileChecksum,
  });

  factory AdminPaper.fromMap(Map<String, dynamic> m) => AdminPaper(
    id: m['id'] as String,
    subjectId: m['subject_id'] as String,
    examYear: m['exam_year'] as int,
    session: m['session'] as String,
    paperNumber: m['paper_number'] as int,
    languageCode: m['language_code'] as String? ?? 'en',
    examType: m['exam_type'] as String? ?? 'nsc',
    title: m['title'] as String,
    sourceUrl: m['source_url'] as String,
    fileChecksum: m['file_checksum'] as String?,
    associationConfidence:
        m['association_confidence'] as String? ?? 'unconfirmed',
    contentStatus: m['content_status'] as String? ?? 'draft',
  );

  static const sessions = [
    'may_june',
    'october_november',
    'february_march',
    'supplementary',
  ];
  static const examTypes = ['nsc', 'sc', 'irr', 'amended_nsc'];
}

class AdminPaperAsset {
  final String id;
  final String paperId;
  final String assetKind;
  final String storagePath;
  final String? fileChecksum;
  final int? fileSizeBytes;

  const AdminPaperAsset({
    required this.id,
    required this.paperId,
    required this.assetKind,
    required this.storagePath,
    this.fileChecksum,
    this.fileSizeBytes,
  });

  factory AdminPaperAsset.fromMap(Map<String, dynamic> m) => AdminPaperAsset(
    id: m['id'] as String,
    paperId: m['paper_id'] as String,
    assetKind: m['asset_kind'] as String,
    storagePath: m['storage_path'] as String,
    fileChecksum: m['file_checksum'] as String?,
    fileSizeBytes: m['file_size_bytes'] as int?,
  );

  static const assetKinds = [
    'question_paper',
    'memorandum',
    'addendum',
    'formula_sheet',
    'data_sheet',
    'other',
  ];
}
