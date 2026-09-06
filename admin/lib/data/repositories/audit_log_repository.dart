import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/governance_models.dart';

/// Section 14: append-only audit trail, admin-read-only (RLS: `audit_log_admin_read`). A
/// content_reviewer's client simply gets an empty result set here, not an error — RLS filters
/// rows rather than the query failing outright, which is why the Audit Log screen still needs its
/// own role check before it even renders the table (empty state vs "you can't view this").
class AuditLogRepository {
  final SupabaseClient client;
  AuditLogRepository(this.client);

  Future<List<AuditLogEntry>> fetchRecent({int limit = 200}) async {
    final rows = await client
        .from('audit_log')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => AuditLogEntry.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}
