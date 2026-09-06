import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Null when no Supabase project is configured (see [Env.isConfigured]) — [AuthGate] shows a
/// "not connected" screen in that case rather than letting every repository crash separately.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!Env.isConfigured) return null;
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const Stream.empty();
  return client.auth.onAuthStateChange;
});

final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider); // rebuild on auth changes
  final client = ref.watch(supabaseClientProvider);
  return client?.auth.currentUser?.id;
});

/// The signed-in staff member's own `profiles` row (role, nickname) — null while loading, not
/// signed in, or if the row doesn't exist. [AuthGate] uses `role` to decide dashboard access;
/// individual screens (Users & Roles, Audit Log) use it again to hide admin-only sections from a
/// content_reviewer. This is a UX convenience only — RLS enforces the real boundary server-side.
final currentStaffProfileProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (client == null || userId == null) return null;
  return client.from('profiles').select().eq('id', userId).maybeSingle();
});
