import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Null in local dev mode (no Supabase project configured) — every repository must check
/// [Env.isLocalDevMode] / whether this is null before using it, and fall back to the local seed
/// or Drift-cached implementation instead. See docs/SETUP.md for configuring real credentials.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (Env.isLocalDevMode) return null;
  return Supabase.instance.client;
});

/// Emits the current Supabase auth user, or null for guest mode / local dev mode.
final authStateProvider = StreamProvider<AuthState?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const Stream.empty();
  return client.auth.onAuthStateChange;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client?.auth.currentUser?.id;
});
