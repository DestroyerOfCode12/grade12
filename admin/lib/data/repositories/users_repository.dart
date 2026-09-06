import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/governance_models.dart';

/// Section 12: "Manage roles and permissions". Role changes go through the `admin_set_user_role`
/// RPC (supabase/migrations/0013), never a direct `update profiles set role = ...` — that RPC is
/// what writes the audit_log entry and is the only path the database itself allows for changing
/// someone else's role (the direct-update path is blocked by `trg_prevent_role_self_escalation`
/// for a caller's own row, and by the `profiles_update_own` RLS policy for anyone else's row).
class UsersRepository {
  final SupabaseClient client;
  UsersRepository(this.client);

  Future<List<AdminProfile>> fetchAll({String? searchNickname}) async {
    var query = client.from('profiles').select();
    if (searchNickname != null && searchNickname.isNotEmpty) {
      query = query.ilike('nickname', '%$searchNickname%');
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((r) => AdminProfile.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> setRole(String targetProfileId, String newRole) async {
    await client.rpc(
      'admin_set_user_role',
      params: {'p_target_profile_id': targetProfileId, 'p_new_role': newRole},
    );
  }
}
