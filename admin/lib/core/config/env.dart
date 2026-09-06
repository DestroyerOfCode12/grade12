/// MatricQuest SA Admin — runtime configuration.
///
/// Unlike the learner app, there is no meaningful "local dev mode" for an admin tool — its whole
/// purpose is editing real backend data. When no project is configured, [SignInScreen] shows a
/// clear "not connected" state instead of crashing, but nothing in the dashboard works until a
/// real Supabase project is supplied at build time via `--dart-define` (see admin/.env.example).
class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
