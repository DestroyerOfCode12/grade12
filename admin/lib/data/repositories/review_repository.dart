import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/governance_models.dart';

/// Section 12: "Review AI-generated drafts" / manual review queue (section 2's requirement that
/// imported/AI-generated content cannot reach learners without a human checking it first).
class ReviewRepository {
  final SupabaseClient client;
  ReviewRepository(this.client);

  Future<List<ReviewTask>> fetchOpen() async {
    final rows = await client
        .from('review_tasks')
        .select()
        .inFilter('status', ['open', 'in_progress'])
        .order('priority')
        .order('created_at');
    return (rows as List)
        .map((r) => ReviewTask.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> setStatus(String taskId, String status, {String? notes}) async {
    final patch = <String, dynamic>{'status': status};
    if (notes != null) patch['notes'] = notes;
    if (status == 'resolved' || status == 'dismissed') {
      patch['resolved_at'] = DateTime.now().toIso8601String();
    }
    await client.from('review_tasks').update(patch).eq('id', taskId);
  }

  Future<void> assignToSelf(String taskId, String profileId) async {
    await client
        .from('review_tasks')
        .update({'assigned_to': profileId, 'status': 'in_progress'})
        .eq('id', taskId);
  }
}

/// Section 12: "View user content reports" / "Correct inaccurate content".
class ContentReportsRepository {
  final SupabaseClient client;
  ContentReportsRepository(this.client);

  Future<List<ContentReport>> fetchAll() async {
    final rows = await client
        .from('content_reports')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => ContentReport.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> setStatus(String reportId, String status) async {
    final patch = <String, dynamic>{'status': status};
    if (status == 'actioned' || status == 'dismissed') {
      patch['resolved_at'] = DateTime.now().toIso8601String();
    }
    await client.from('content_reports').update(patch).eq('id', reportId);
  }
}

/// Section 12: "Track content sources" / "Roll back content versions".
class ContentVersionsRepository {
  final SupabaseClient client;
  ContentVersionsRepository(this.client);

  Future<List<ContentVersionSnapshot>> fetchHistory(
    String entityType,
    String entityId,
  ) async {
    final rows = await client
        .from('content_versions')
        .select()
        .eq('entity_type', entityType)
        .eq('entity_id', entityId)
        .order('version_number', ascending: false);
    return (rows as List)
        .map((r) => ContentVersionSnapshot.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchSourceReferences(
    String entityType,
    String entityId,
  ) async {
    final rows = await client
        .from('source_references')
        .select()
        .eq('entity_type', entityType)
        .eq('entity_id', entityId)
        .order('retrieved_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }
}
