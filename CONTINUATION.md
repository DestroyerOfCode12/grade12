# CONTINUATION.md — MatricQuest SA build checkpoint

**Read this before continuing work.** It records exactly what is done, tested, and verified vs.
what is stubbed or missing, so the next session can continue without re-deriving or re-building
anything already complete. Written 2026-09-02 (session 1), updated 2026-09-06 (session 2 — admin
dashboard), updated 2026-09-07 (session 3 — study planner; session 4 — diagnostic assessment).

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

### Admin dashboard (session 2, `admin/`)
- Flutter Web app implementing section 12's content-review workflow — see
  [`admin/README.md`](admin/README.md) for exact screen-by-screen coverage. Not a stub: subjects,
  topics, lessons (full 10-part block editor), questions (options + solution with the official-
  memorandum/teaching-explanation split from section 6), review queue, content reports, past
  papers (including real Supabase Storage file upload), users & roles (via the audited
  `admin_set_user_role` RPC), and an admin-only audit log all have working CRUD screens.
- `flutter analyze --fatal-infos` → **0 issues** (verified). `flutter test` → **12/12 passing**
  (verified): `content_lifecycle_test.dart` (11 tests covering the publish-gate state machine) +
  one widget smoke test (the "not connected" screen when no Supabase project is configured, since
  this app — unlike `app/` — has no local dev mode).
- `flutter build web` — **verified on GitHub Actions** (`admin-web-build` job, run 34023196842):
  succeeded, including the previously-unrun web compile. `admin-analyze-and-test` also passed.
  Both new CI jobs confirmed green on their first real run, alongside the app/backend jobs from
  session 1 (Android debug/release, iOS archive, SQL lint) which also stayed green.
- `ContentLifecycle` (`admin/lib/domain/services/content_lifecycle.dart`) is the enforced state
  machine: draft → in_review → approved → published/rejected → archived, with `published` reachable
  only from `approved`, and `canPublish()` additionally blocking anything `is_seed_demo_content` or
  not `verified`/`source_recorded` — this is what makes "no one can publish merely by generating
  content" (section 2/12) an enforced rule in the UI, not a convention. Every editor screen defers
  to it rather than re-implementing the check.
- Auth gating (`AuthGate`) is a UX convenience layered on top of RLS, not the real boundary — a
  non-staff account reaching any screen would just see empty tables, since RLS already filters
  every query. Verify this claim once a local Postgres stack exists (see pgTAP note above);
  it was reasoned through, not tested end-to-end against a live database this session either.

### Study planner (session 3, `app/lib/features/planner/`)
- Section 9's "generate a study plan" + section 11 screen 20. `StudyPlanGenerator`
  (`app/lib/domain/services/study_plan_generator.dart`) is a pure, explainable spaced-repetition
  scheduler: review interval is derived from each topic's `MasteryCalculator.labelFor()` (not
  started → due immediately as a lesson; needs_work → every 2 days; developing → 4; on_track → 7;
  strong → 14), sessions fill a daily time budget, and anything that doesn't fit a full day carries
  over to the next day rather than being dropped. Covered by 9 unit tests (verified).
- `StudyPlanRepository` — Supabase-backed (reads `topics` for the learner's selected subjects +
  `mastery_scores` for the signed-in profile, writes `study_plans`/`study_sessions`) and a
  local/guest mirror (`local_study_sessions` table added to `app_database.dart`). As of session 4,
  the local path reads real mastery from `local_mastery_scores` (written by the diagnostic
  assessment) instead of a hardcoded zero — see below.
  Covered by 5 repository tests against the local path (verified) — the Supabase path's query
  shape (`study_plans!inner(...)` embedded filter) has NOT been exercised against a real Postgres
  instance yet; sanity-check it the same time you finally run the pgTAP suite.
- `StudyPlannerScreen` (generate/regenerate, mark done/skip, deep-links into the demo lesson) plus
  an "Upcoming study sessions" card on the Home dashboard. Reachable via `/planner`, not a bottom-
  nav tab (matches the brief's own five-tab list). 1 widget smoke test (empty state) — verified.
- **Not built**: no UI takes a target exam date, term structure, or past-paper performance as
  input yet — the generator accepts them as `TopicPlanInput`/parameters in principle (see that
  file's doc comment) but nothing upstream computes or passes them in.

### Diagnostic assessment (session 4, `app/lib/features/onboarding/diagnostic_assessment_screen.dart`)
- Section 9's "run a short diagnostic assessment for each selected subject" / section 11 screen 4.
  Sits between subject selection and Home in onboarding (`/onboarding/diagnostic`); "Skip for now"
  on subject selection still bypasses the whole thing, matching how it worked before this screen
  existed.
- `MasteryRepository` (`app/lib/data/repositories/mastery_repository.dart`) is the new single
  place any feature should call to update a topic's mastery — `recordAttempt()` sets the estimate
  directly on a topic's first-ever attempt (recency weight 1.0, so a real signal isn't diluted
  against a meaningless zero baseline) and blends subsequent attempts in at
  `MasteryCalculator`'s normal 0.35 weight. The diagnostic screen is this repository's first
  caller; a future quiz/lesson-checkpoint feature should call the same method rather than growing
  a second mastery-update path — this was flagged as a gap in session 3's CONTINUATION notes
  before this repository existed to close it.
- `DiagnosticRepository` finds any `quiz_kind = 'diagnostic'` quiz for the learner's selected
  subjects' topics (Supabase) or the one embedded demo Mathematics topic (local/guest mode, reusing
  the checkpoint quiz's MCQ question — the diagnostic UI only supports multiple-choice today, so
  the seed's `numeric` question is deliberately left out of the diagnostic quiz rather than
  included and silently unanswerable).
- `local_mastery_scores` table added to `app_database.dart`; `study_plans`/`0002_math_demo_content.sql`
  seed got a new `diagnostic`-kind quiz row reusing the existing MCQ question.
- `flutter analyze --fatal-infos`: 0 issues. `flutter test`: **37/37 passing** (up from 32 — 5
  mastery-repository tests added this session; the existing guest-mode critical-flow widget test
  was extended to walk through the diagnostic screen's skip path rather than getting a second,
  separate test).
- **Known gap, not a bug to "fix" by removing the seed question — fix the UI instead**: the
  diagnostic screen's question view only renders `question.options`, so a non-multiple-choice
  question (e.g. `numeric`, `short_answer`) would render with no answerable options and a
  permanently-disabled "Check answer" button — `DiagnosticRepository` does NOT filter by question
  kind, it was the seed data that was curated to avoid this (the diagnostic quiz includes only the
  MCQ question, deliberately excluding the seed's `numeric` one). Adding a diagnostic quiz with a
  non-MCQ question anywhere (admin dashboard included) will hit this until the UI handles other
  kinds. The Supabase path's `topics!inner(...)` embedded-filter query is also unexercised against
  a real Postgres instance, same caveat as the study planner above.

## What is STUBBED (present but intentionally minimal)

- **Papers Library / Paper Detail**: one demo record, no bundled PDF, no PDF viewer, no
  timed/untimed exam mode, no self-marking. `PaperDetailScreen` says so explicitly rather than
  faking it.
- **"Play" bottom-nav tab**: placeholder screen. No Daily Challenge, no Boss Battle.
- **Quest Coach**: Edge Function exists; no chat UI screen in the app yet.
- **Diagnostic assessment**: only multiple-choice questions are supported (see the "known gap"
  note above); only one topic has diagnostic content (the demo Mathematics topic).

## What is MISSING entirely (not started)

- Real past-paper ingestion pipeline: checksum computation/verification (files upload via the
  admin dashboard now, but nothing hashes or verifies them yet), memo-association confidence
  scoring beyond a manual "confirm" button, bulk import.
- Admin-dashboard extras noted in `admin/README.md`: bulk operations, content-version rollback UI,
  source-reference management UI, CAPS curriculum-version management UI.
- Offline download management UI (Wi-Fi-only toggle, size warnings, storage management) — the
  `downloads` table and `learner_preferences.wifi_only_downloads`/`data_saver_mode` columns exist;
  no UI or actual file-download code yet.
- Push notifications (FCM/APNs) — `notification_preferences` table exists; no client integration.
- Achievements, Leaderboard, Boss Battle, Daily Challenge screens.
- Privacy/export/delete-account screen and Help/content-reporting screen (backend tables
  `content_reports` exist; POPIA export/delete flow does not).
- `mastery_scores.next_review_due_at` still isn't written by anything — the study planner
  (session 3) computes its own review cadence from `mastery_estimate`/`attempts_count` directly
  rather than reading/writing that column. Worth reconciling later: either the planner should
  start writing `next_review_due_at` so other future features can read it, or the column should
  be considered superseded by the planner's approach — pick one rather than letting both exist
  unreconciled.
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
   `supabase/tests/rls_and_idempotency_test.sql` — this is the highest-priority unverified piece,
   and it also verifies the admin dashboard's AuthGate assumption, the study planner's
   `study_plans!inner(...)` embedded filter, and the diagnostic assessment's `topics!inner(...)`
   one — none of which have touched a real Postgres instance yet.
2. Finish the Android release signing setup and get a real device install working end to end
   against a live Supabase project (not local dev mode) — validates the full stack, not just the
   guest-mode local path.
3. Now that the admin dashboard exists: expand verified subject content through it, following
   section 2's manual-review requirement — this was blocked on the dashboard existing; it no
   longer is. This would also give the study planner and diagnostic assessment more than one topic
   to actually work with.
4. Extend the diagnostic (and quiz-taking generally) UI to handle non-multiple-choice questions —
   see the "known gap" note under session 4 above — before adding any diagnostic content beyond
   MCQ through the admin dashboard.

## Files worth reading first if you're resuming cold

- [`docs/ADR.md`](docs/ADR.md), [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md),
  [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md) — the "why," not just the "what."
- [`docs/SETUP.md`](docs/SETUP.md) §7–8 — the Gradle-loopback and Drift/analyzer gotchas, so you
  don't re-lose time to either.
- [`admin/README.md`](admin/README.md) — exact coverage of the staff dashboard before you assume
  a section-12 capability is missing and rebuild it.
