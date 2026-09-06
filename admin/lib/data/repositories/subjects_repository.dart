import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/subject_models.dart';

/// Section 12: "Manage subjects and CAPS versions". Reads/writes go through RLS as any other
/// client would — a signed-in learner account would be refused these writes by the database
/// itself (`0011_row_level_security.sql`), not just by this app hiding the buttons.
class SubjectsRepository {
  final SupabaseClient client;
  SubjectsRepository(this.client);

  Future<List<AdminSubject>> fetchAll() async {
    final rows = await client.from('subjects').select().order('sort_order');
    return (rows as List)
        .map((r) => AdminSubject.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<AdminSubject> fetchOne(String subjectId) async {
    final row = await client
        .from('subjects')
        .select()
        .eq('id', subjectId)
        .single();
    return AdminSubject.fromMap(row);
  }

  Future<void> updateStatus(
    String subjectId, {
    String? contentStatus,
    String? verificationStatus,
  }) async {
    final patch = <String, dynamic>{};
    if (contentStatus != null) {
      patch['content_status'] = contentStatus;
    }
    if (verificationStatus != null) {
      patch['verification_status'] = verificationStatus;
    }
    if (patch.isEmpty) {
      return;
    }
    await client.from('subjects').update(patch).eq('id', subjectId);
  }

  Future<void> updateCoverageFlags(
    String subjectId, {
    bool? papersAvailable,
    bool? lessonsInReview,
    bool? fullCourseAvailable,
  }) async {
    final patch = <String, dynamic>{};
    if (papersAvailable != null) {
      patch['papers_available'] = papersAvailable;
    }
    if (lessonsInReview != null) {
      patch['lessons_in_review'] = lessonsInReview;
    }
    if (fullCourseAvailable != null) {
      patch['full_course_available'] = fullCourseAvailable;
    }
    if (patch.isEmpty) {
      return;
    }
    await client.from('subjects').update(patch).eq('id', subjectId);
  }

  Future<void> createSubject({
    required String code,
    required String name,
    required String category,
    required String level,
  }) async {
    await client.from('subjects').insert({
      'code': code,
      'name': name,
      'category': category,
      'level': level,
      'content_status': 'draft',
      'verification_status': 'unverified',
    });
  }

  // --- Topics ---

  Future<List<AdminTopic>> fetchTopics(String subjectId) async {
    final rows = await client
        .from('topics')
        .select()
        .eq('subject_id', subjectId)
        .order('sort_order');
    return (rows as List)
        .map((r) => AdminTopic.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> createTopic({
    required String subjectId,
    required String title,
    required String term,
  }) async {
    await client.from('topics').insert({
      'subject_id': subjectId,
      'title': title,
      'term': term,
      'content_status': 'draft',
      'verification_status': 'unverified',
    });
  }

  Future<void> updateTopicStatus(
    String topicId, {
    String? contentStatus,
    String? verificationStatus,
  }) async {
    final patch = <String, dynamic>{};
    if (contentStatus != null) {
      patch['content_status'] = contentStatus;
    }
    if (verificationStatus != null) {
      patch['verification_status'] = verificationStatus;
    }
    if (patch.isEmpty) {
      return;
    }
    await client.from('topics').update(patch).eq('id', topicId);
  }
}
