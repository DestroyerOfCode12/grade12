import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/subject_models.dart';

/// Section 12: "Manage topics and lessons". Publishing a lesson still requires
/// `content_status = 'published'` — this repository does not bypass the review-state gate that
/// `ContentLifecycle` (domain/services) enforces in the UI, and that RLS enforces server-side.
class LessonsRepository {
  final SupabaseClient client;
  LessonsRepository(this.client);

  Future<List<AdminLesson>> fetchForTopic(String topicId) async {
    final rows = await client
        .from('lessons')
        .select()
        .eq('topic_id', topicId)
        .order('sort_order');
    return (rows as List)
        .map((r) => AdminLesson.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<AdminLesson> fetchOne(String lessonId) async {
    final row = await client
        .from('lessons')
        .select()
        .eq('id', lessonId)
        .single();
    return AdminLesson.fromMap(row);
  }

  Future<String> createLesson({
    required String topicId,
    required String title,
    required int estimatedMinutes,
  }) async {
    final row = await client
        .from('lessons')
        .insert({
          'topic_id': topicId,
          'title': title,
          'estimated_minutes': estimatedMinutes,
          'content_status': 'draft',
          'verification_status': 'unverified',
          'is_seed_demo_content': false,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> updateLesson(
    String lessonId, {
    String? title,
    int? estimatedMinutes,
  }) async {
    final patch = <String, dynamic>{};
    if (title != null) {
      patch['title'] = title;
    }
    if (estimatedMinutes != null) {
      patch['estimated_minutes'] = estimatedMinutes;
    }
    if (patch.isEmpty) {
      return;
    }
    await client.from('lessons').update(patch).eq('id', lessonId);
  }

  Future<void> updateStatus(
    String lessonId, {
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
    await client.from('lessons').update(patch).eq('id', lessonId);
  }

  // --- Lesson blocks (the 10-part structure, section 5) ---

  Future<List<AdminLessonBlock>> fetchBlocks(String lessonId) async {
    final rows = await client
        .from('lesson_blocks')
        .select()
        .eq('lesson_id', lessonId)
        .order('sort_order');
    return (rows as List)
        .map((r) => AdminLessonBlock.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertBlock({
    String? blockId,
    required String lessonId,
    required String blockType,
    required int sortOrder,
    required String bodyMarkdown,
  }) async {
    if (blockId == null) {
      await client.from('lesson_blocks').insert({
        'lesson_id': lessonId,
        'block_type': blockType,
        'sort_order': sortOrder,
        'body_markdown': bodyMarkdown,
      });
    } else {
      await client
          .from('lesson_blocks')
          .update({
            'block_type': blockType,
            'sort_order': sortOrder,
            'body_markdown': bodyMarkdown,
          })
          .eq('id', blockId);
    }
  }

  Future<void> deleteBlock(String blockId) async {
    await client.from('lesson_blocks').delete().eq('id', blockId);
  }
}
