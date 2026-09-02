# Setup — MatricQuest SA

## Prerequisites

- Flutter 3.47.2 (stable) or later — this repo was built and tested against exactly this version.
  Install from https://docs.flutter.dev/get-started/install and run `flutter doctor`.
- For Android builds: Android SDK with `cmdline-tools`, a platform matching
  `app/android/app/build.gradle`, and accepted licenses (`flutter doctor --android-licenses`).
- For iOS builds: a macOS machine with Xcode — not available in every dev environment; CI's
  `ios-unsigned-archive.yml` workflow validates iOS compiles even without one locally.
- Optional: the [Supabase CLI](https://supabase.com/docs/guides/cli) for running the backend
  locally (`supabase start`) and applying migrations/tests.

## 1. Run the app with zero backend (local dev mode)

```bash
cd app
flutter pub get
flutter run
```

With no `--dart-define` values supplied, `lib/core/config/env.dart` reports `isLocalDevMode =
true` and every repository falls back to the embedded demo catalogue
(`lib/data/demo_content/demo_catalogue.dart`) instead of calling Supabase. Guest-mode XP/streak
state is stored in a local SQLite file via `package:sqlite3` (see
`lib/data/local/app_database.dart`). This is enough to exercise the full onboarding → lesson →
quiz → XP → papers vertical slice with no external service at all.

## 2. Configure a real Supabase backend

1. Create a project at https://supabase.com (or run one locally with `supabase start`).
2. Apply migrations in order:
   ```bash
   cd supabase
   supabase link --project-ref <your-project-ref>
   supabase db push          # applies supabase/migrations/*.sql in order
   ```
   Or, against a local stack: `supabase db reset` (applies migrations + `supabase/seed/*.sql`
   automatically if configured in `supabase/config.toml`).
3. Seed the subject catalogue and demo content (optional, recommended for a first run):
   ```bash
   psql "$DATABASE_URL" -f supabase/seed/0001_subjects_catalogue.sql
   psql "$DATABASE_URL" -f supabase/seed/0002_math_demo_content.sql
   ```
4. Copy `app/.env.example` values and run the app pointed at your project:
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://<your-ref>.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
   ```
   Never pass the `service_role` key here — it belongs only in Edge Function secrets (§4).

## 3. Configure the Quest Coach AI tutor (optional)

The Edge Function at `supabase/functions/quest-coach` runs a `LocalStubProvider` (zero external
calls, zero cost) until an API key is set:

```bash
cd supabase
cp .env.example .env.local        # fill in ANTHROPIC_API_KEY (never commit .env.local)
supabase secrets set --env-file .env.local
supabase functions deploy quest-coach
```

## 4. Server secrets vs. client config — what goes where

| Secret | Lives in | Never in |
|---|---|---|
| `SUPABASE_ANON_KEY` / publishable key | `--dart-define` at build time | committed source |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Edge Function secrets | the mobile app, ever |
| `ANTHROPIC_API_KEY` | Supabase Edge Function secrets | the mobile app, ever |
| Android signing key | `app/android/key.properties` (gitignored) + CI secret | committed source |

## 5. Running tests

```bash
cd app
flutter analyze          # must be clean before committing
dart format --set-exit-if-changed .
flutter test              # unit + widget tests
```

Backend RLS/idempotency tests (`supabase/tests/rls_and_idempotency_test.sql`) need a local
Supabase/Postgres stack with pgTAP:

```bash
cd supabase
supabase start
supabase test db
```

## 6. Known environment gotcha: Gradle "Unable to establish loopback connection"

If `flutter build apk` fails immediately with `java.io.IOException: Unable to establish loopback
connection`, this is a JVM-level socket restriction (commonly endpoint security software on a
managed/corporate Windows machine intercepting Java's socket calls), not a project misconfiguration
— raw OS-level loopback TCP working fine (test with a throwaway `TcpListener`/`TcpClient` in
PowerShell) while every Gradle invocation fails the same way is the tell. `org.gradle.daemon=false`,
`org.gradle.vfs.watch=false`, and `-Djava.net.preferIPv4Stack=true` (already set in
`app/android/gradle.properties`) did **not** fix it here. If you hit this: try a different network
(off VPN/corporate network), check endpoint security / firewall exceptions for `java.exe` and
`gradle`, or just build on CI instead — GitHub Actions runners don't have this restriction.

## 7. Known environment gotcha: Drift/build_runner and Dart 3.13

If you re-add Drift or any `build_runner`-based code generator (freezed, json_serializable,
riverpod_generator), you may hit:

```
Exception: Missing implementation of visitDotShorthandPropertyAccess
```

This is an upstream incompatibility between Flutter 3.47.2's Dart 3.13.2 SDK sources and every
currently-published `analyzer` version compatible with `build_resolvers` 2.5.4 — not something
fixable by editing this app's code (confirmed: `analyzer` 7.7.1 still hits it; `analyzer` 8.x fixes
the parse issue but breaks `build_resolvers`' API usage instead). This repo's local storage layer
therefore uses hand-written `package:sqlite3` access instead of Drift codegen (see
`lib/data/local/app_database.dart`). Check whether `drift_dev`/`build_resolvers` have shipped a fix
before re-introducing generated code, and re-run `dart run build_runner build
--delete-conflicting-outputs` to confirm before relying on it in CI.
