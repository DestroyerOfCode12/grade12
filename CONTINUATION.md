# CONTINUATION.md — MatricQuest SA build checkpoint

**Read this before continuing work.** It records exactly what is done, tested, and verified vs.
what is stubbed or missing, so the next session can continue without re-deriving or re-building
anything already complete. Written 2026-09-02, end of the first build session.

## Environment this was built in

- Windows 11, no pre-existing Flutter/Android/git tooling. Flutter 3.47.2 (stable, Dart 3.13.2) was
  downloaded and installed to `~/dev/flutter` this session (not part of the repo).
- Android SDK partially present (`build-tools`, `platforms`, `platform-tools`) but no
  `cmdline-tools`; `flutter doctor --android-licenses` has not been run.
- No macOS available — iOS cannot be built or run locally here; only CI's macOS runner can.
- **This machine blocks Java/Gradle's loopback socket** (see "Android debug APK" below) —
  confirmed environment-specific by building successfully on GitHub Actions instead. Not a
  project-config problem; nothing to fix in the repo itself.

## What is DONE and VERIFIED (commands actually run, output actually checked)

### Backend (Postgres/Supabase)
- 13 migrations, `supabase/migrations/0001` through `0013`, covering every table listed in section
  13 of the brief. Reviewed for RLS coverage on every learner-owned and curriculum table.
- Idempotent `grant_xp`, `record_daily_activity`, `submit_attempt` RPCs (0012); a role-escalation
  guard + audited `admin_set_user_role` (0013, added after the threat model surfaced the gap).
- Seed data: real DBE FET subject list (`0001_subjects_catalogue.sql`, sourced 2026-09-02, marked
  `source_recorded` not `verified` — still needs a curriculum reviewer) + one demo Mathematics
  topic/lesson/quiz/paper (`0002_math_demo_content.sql`), explicitly flagged
  `is_seed_demo_content` throughout.
- **Not run against a real Postgres instance** — no local Supabase/Postgres available in this
  environment. The pgTAP suite (`supabase/tests/rls_and_idempotency_test.sql`) is written but
  UNEXECUTED. Before trusting the RLS policies in production: `supabase start && supabase test db`.
- Quest Coach Edge Function (`supabase/functions/quest-coach`) — written, not deployed or run.
  `LocalStubProvider` path was not executed either. Needs `supabase functions serve` +  a manual
  smoke test before considering it "working."

### Mobile app
- `flutter analyze` → **0 issues** (verified, ran twice after fixes).
- `flutter test` → **17/17 passing** (verified): `streak_calculator_test.dart` (6),
  `mastery_calculator_test.dart` (7), `gamification_repository_test.dart` (3),
  `widget_test.dart` (1 end-to-end guest-mode flow test).
- `flutter build apk --debug` — **fails locally on this machine** (5 attempts, all the same
  `java.io.IOException: Unable to establish loopback connection` from Gradle's Tooling API /
  native-platform library, ~6s in). Confirmed NOT an app-code or Gradle-config issue: raw
  OS-level loopback TCP works fine here (tested directly with .NET `TcpListener`/`TcpClient`), so
  the block is JVM-specific — almost certainly endpoint security software on this
  managed/AzureAD-joined Windows machine intercepting Java's socket calls. Tried and ruled out as
  fixes: `org.gradle.daemon=false`, `org.gradle.vfs.watch=false`, `-Djava.net.preferIPv4Stack=true`,
  running with sandbox restrictions lifted — kept in `android/gradle.properties` anyway (harmless)
  but none of them were the actual fix.
- **Verified working on GitHub Actions** (pushed to
  https://github.com/DestroyerOfCode12/grade12, run
  [33642738884](https://github.com/DestroyerOfCode12/grade12/actions/runs/33642738884)): the
  `android-debug-build` and `android-release-bundle` jobs both **succeeded**, ~4.5 min each,
  producing real `app-debug.apk` / `app-release.aab` artifacts — confirming this was purely a
  local-machine JVM/network restriction, not a defect in the app, Gradle config, or CI workflow.
  The `ios-unsigned-archive.yml` workflow (run 33642738877) also **succeeded** on GitHub's macOS
  runner. All three platform builds are now CI-verified from a clean checkout.
- Vertical slice screens implemented and reachable via real navigation: splash → subject selection
  → home dashboard → all subjects → lesson (10-block structure, "explain more simply" toggle) →
  checkpoint quiz (MCQ, correctness shown with icon+colour+text) → results (XP/streak) → papers
  library → paper detail (honest placeholder, no bundled file) → profile.
- Offline-first data layer: hand-written `package:sqlite3` access (NOT Drift — see below),
  `outbox_entries` table with idempotency-key-gated writes, `local_learner_state` cache.

### Known-fixed issues from this session (don't re-introduce)
- **Drift/build_runner is deferred, not just "not done yet."** `drift_dev`/`build_resolvers`
  crash analyzing this Flutter version's SDK sources (`Missing implementation of
  visitDotShorthandPropertyAccess`) — confirmed with `analyzer` 7.6.0, 7.7.1 (latest 7.x), and 8.4.1
  (which fixes the parse crash but breaks `build_resolvers`' Element API usage instead). This is an
  upstream ecosystem gap between a very recent Flutter/Dart release and codegen tooling, not
  something fixable by editing this app's code. **Do not spend time re-attempting Drift codegen
  without first checking whether `drift_dev`/`build_resolvers` have shipped a compatible release.**
  The local database (`lib/data/local/app_database.dart`) is hand-written SQL instead — this
  satisfies the brief's own "Drift or an equally reliable SQLite-based solution" (section 3).
  Same reasoning applies to `riverpod_generator`, `freezed`, `json_serializable` — none are used;
  all Riverpod providers are hand-written (no `@riverpod` codegen annotations anywhere).
- The local (guest/offline) XP-award path had a real idempotency bug during development: it
  inserted an idempotent outbox row but then unconditionally re-credited XP on every call
  regardless of whether the row was new. Fixed in `gamification_repository.dart` — 
  `enqueueOutboxEntry` now returns whether the insert was new, and the repository skips crediting
  XP when it wasn't. Covered by `gamification_repository_test.dart`'s "retrying the same
  idempotency key does not double-award XP" test. If you touch this file, keep that test green.

## What is STUBBED (present but intentionally minimal)

- **Papers Library / Paper Detail**: one demo record, no bundled PDF, no PDF viewer, no
  timed/untimed exam mode, no self-marking. `PaperDetailScreen` says so explicitly rather than
  faking it.
- **"Play" bottom-nav tab**: placeholder screen. No Daily Challenge, no Boss Battle.
- **Quest Coach**: Edge Function exists; no chat UI screen in the app yet.
- **Study Planner**: `study_plans`/`study_sessions` tables exist; no screen, no plan-generation
  logic.
- **Diagnostic assessment**: not implemented — onboarding jumps straight from subject selection to
  home.

## What is MISSING entirely (not started)

- Admin/content-review web dashboard (section 12) — this was Phase 3 and the session ran out of
  scope before reaching it. All the tables it needs (`review_tasks`, `content_versions`,
  `content_reports`, the `content_status` lifecycle) exist and are exercised by the seed data, so
  building the dashboard is a pure frontend task against an already-designed API.
  - Recommended stack: same Supabase backend, a separate web app (Next.js or Flutter Web) — kept
    out of the mobile app bundle per section 12's role-based-admin requirement.
- Real past-paper ingestion pipeline (checksum verification, memo-association confidence scoring,
  manual review queue UI).
- Offline download management UI (Wi-Fi-only toggle, size warnings, storage management) — the
  `downloads` table and `learner_preferences.wifi_only_downloads`/`data_saver_mode` columns exist;
  no UI or actual file-download code yet.
- Push notifications (FCM/APNs) — `notification_preferences` table exists; no client integration.
- Achievements, Leaderboard, Boss Battle, Daily Challenge screens.
- Privacy/export/delete-account screen and Help/content-reporting screen (backend tables
  `content_reports` exist; POPIA export/delete flow does not).
- Spaced repetition scheduling logic (`mastery_scores.next_review_due_at` column exists, unused).
- Full curriculum content beyond the one demo Mathematics topic — by design (section 2 forbids
  mass-generating unverified content); this needs a real content pipeline + reviewers, not more
  AI-generated seed data.
- Golden tests, integration_test (device-level) suite, accessibility audit, performance testing on
  low-end device profiles, full security review beyond the threat model document.
- App icons, launch screens (still Flutter's default template assets).
- SQLCipher encryption for the local database (noted as an outstanding item in
  `docs/THREAT_MODEL.md`).
- Output-citation verification on Quest Coach responses (noted in `docs/THREAT_MODEL.md`).

## Recommended next session's order of work

1. Get a local Supabase stack running (`supabase start`) and actually execute
   `supabase/tests/rls_and_idempotency_test.sql` — this is the highest-priority unverified piece.
2. Finish the Android release signing setup and get a real device install working end to end
   against a live Supabase project (not local dev mode) — validates the full stack, not just the
   guest-mode local path.
3. Build the admin dashboard's content-review workflow (Phase 3) — it unblocks real content growth
   without more unverified AI-generated lessons.
4. Only then: expand verified subject content, following section 2's manual-review requirement.

## Files worth reading first if you're resuming cold

- [`docs/ADR.md`](docs/ADR.md), [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md),
  [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md) — the "why," not just the "what."
- [`docs/SETUP.md`](docs/SETUP.md) §6 — the Drift/analyzer gotcha, so you don't re-lose an hour to it.
