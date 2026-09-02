/// MatricQuest SA — runtime configuration.
///
/// Production credentials are NEVER hard-coded here. They are supplied at build time via
/// `--dart-define` (see docs/SETUP.md) and read through `String.fromEnvironment`. When they are
/// absent — which is the default for a fresh checkout — the app runs in **local dev mode**:
/// Supabase calls are routed through [LocalDevModeException] paths and the UI falls back to the
/// seeded demo repository instead of a network call, so the app is runnable with zero secrets.
class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// True when no Supabase project has been configured for this build. In this mode the app uses
  /// on-device seeded demo data and a local-only guest profile — see [LocalDevModeException] and
  /// `data/repositories/*_repository.dart` for the fallback implementations.
  static bool get isLocalDevMode =>
      supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;

  /// South Africa is the app's primary timezone; new guest profiles default to it per section 16
  /// (streak calculations use the learner's timezone, defaulting SA users to Africa/Johannesburg).
  static const String defaultTimezone = 'Africa/Johannesburg';
}
