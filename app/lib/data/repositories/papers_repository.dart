import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimal past-paper record for the vertical slice's Papers Library screen. Full filtering
/// (year/session/paper number/language), checksum verification, and offline download management
/// are tracked in docs/CONTINUATION.md as Phase 3 ingestion-pipeline work; this repository
/// currently supports listing + the metadata needed to render the library and a detail view.
class PaperSummary {
  final String id;
  final String title;
  final int examYear;
  final String session;
  final int paperNumber;
  final String languageCode;
  final String associationConfidence;
  final String contentStatus;

  const PaperSummary({
    required this.id,
    required this.title,
    required this.examYear,
    required this.session,
    required this.paperNumber,
    required this.languageCode,
    required this.associationConfidence,
    required this.contentStatus,
  });

  factory PaperSummary.fromMap(Map<String, dynamic> map) => PaperSummary(
    id: map['id'] as String,
    title: map['title'] as String,
    examYear: map['exam_year'] as int,
    session: map['session'] as String,
    paperNumber: map['paper_number'] as int,
    languageCode: map['language_code'] as String,
    associationConfidence: map['association_confidence'] as String,
    contentStatus: map['content_status'] as String,
  );
}

abstract class PapersRepository {
  Future<List<PaperSummary>> fetchPapersForSubject(String subjectId);
}

class SupabasePapersRepository implements PapersRepository {
  final SupabaseClient client;
  SupabasePapersRepository(this.client);

  @override
  Future<List<PaperSummary>> fetchPapersForSubject(String subjectId) async {
    final rows = await client
        .from('papers')
        .select()
        .eq('subject_id', subjectId)
        .order('exam_year', ascending: false);
    return (rows as List)
        .map((r) => PaperSummary.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}

/// Local dev mode: one demo record, matching supabase/seed/0002 — intentionally shows the
/// association_confidence:'unconfirmed' / content_status:'draft' state honestly rather than
/// pretending a bundled PDF exists (section 7: "Items with uncertain associations must enter a
/// manual review queue").
class LocalSeedPapersRepository implements PapersRepository {
  @override
  Future<List<PaperSummary>> fetchPapersForSubject(String subjectId) async =>
      const [
        PaperSummary(
          id: 'demo-paper-math-2023-p1',
          title: 'Mathematics Paper 1 (demo record — no bundled file)',
          examYear: 2023,
          session: 'may_june',
          paperNumber: 1,
          languageCode: 'en',
          associationConfidence: 'unconfirmed',
          contentStatus: 'draft',
        ),
      ];
}
