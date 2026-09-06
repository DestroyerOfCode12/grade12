import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/paper_models.dart';

/// Section 12: "Import past papers and memorandums" / section 7's ingestion pipeline.
/// File upload writes to the `papers` Storage bucket (create it in the Supabase dashboard first —
/// see docs/SETUP.md) under `<paperId>/<assetKind>-<filename>`. This repository does not compute
/// or verify the sha256 checksum client-side; do that before/after upload with a server-side
/// function once the ingestion pipeline (CONTINUATION.md) is built out — this pass wires the
/// upload path itself, which is the part that was entirely missing before.
class PapersRepository {
  final SupabaseClient client;
  PapersRepository(this.client);

  Future<List<AdminPaper>> fetchAll() async {
    final rows = await client
        .from('papers')
        .select()
        .order('exam_year', ascending: false);
    return (rows as List)
        .map((r) => AdminPaper.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<AdminPaper> fetchOne(String paperId) async {
    final row = await client.from('papers').select().eq('id', paperId).single();
    return AdminPaper.fromMap(row);
  }

  Future<String> createPaper({
    required String subjectId,
    required int examYear,
    required String session,
    required int paperNumber,
    required String languageCode,
    required String examType,
    required String title,
    required String sourceUrl,
  }) async {
    final row = await client
        .from('papers')
        .insert({
          'subject_id': subjectId,
          'exam_year': examYear,
          'session': session,
          'paper_number': paperNumber,
          'language_code': languageCode,
          'exam_type': examType,
          'title': title,
          'source_url': sourceUrl,
          'content_status': 'draft',
          'association_confidence': 'unconfirmed',
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> updateStatus(
    String paperId, {
    String? contentStatus,
    String? associationConfidence,
  }) async {
    final patch = <String, dynamic>{};
    if (contentStatus != null) {
      patch['content_status'] = contentStatus;
    }
    if (associationConfidence != null) {
      patch['association_confidence'] = associationConfidence;
    }
    if (patch.isEmpty) {
      return;
    }
    await client.from('papers').update(patch).eq('id', paperId);
  }

  Future<List<AdminPaperAsset>> fetchAssets(String paperId) async {
    final rows = await client
        .from('paper_assets')
        .select()
        .eq('paper_id', paperId);
    return (rows as List)
        .map((r) => AdminPaperAsset.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> uploadAsset({
    required String paperId,
    required String assetKind,
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  }) async {
    final storagePath = '$paperId/$assetKind-$fileName';
    await client.storage
        .from('papers')
        .uploadBinary(
          storagePath,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );
    await client.from('paper_assets').insert({
      'paper_id': paperId,
      'asset_kind': assetKind,
      'storage_path': storagePath,
      'file_size_bytes': bytes.length,
      'mime_type': mimeType,
    });
  }

  Future<String> signedUrlForAsset(String storagePath) async {
    return client.storage.from('papers').createSignedUrl(storagePath, 3600);
  }
}
