# MatricQuest SA

A CAPS-aligned, gamified study companion for South African Grade 12 learners — one Flutter
codebase for Android and iOS, a Supabase (Postgres) backend, and offline-first study so it works
on low-cost phones with limited data.

**Status: tested vertical slice, not a finished product.** This repository is a real, running
foundation (backend schema, RLS, a working guest-mode learning loop, CI) built to the checkpoint
strategy described in the brief — see [`CONTINUATION.md`](CONTINUATION.md) for exactly what's done,
what's stubbed, and what's next. Do not present this build to end users as feature-complete.

## What's actually working right now

- **Backend**: 13 Postgres migrations (`supabase/migrations/`) — full schema from
  [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md), Row Level Security on every table, idempotent
  `grant_xp` / `submit_attempt` / `record_daily_activity` RPCs, an append-only audit log, and a
  role-escalation guard.
- **Mobile app** (`app/`): Flutter + Riverpod + GoRouter, `flutter analyze` clean, 17 automated
  tests passing (unit + widget). Guest-mode vertical slice: splash → subject selection → home
  dashboard → lesson → checkpoint quiz → XP/streak → results → past-papers library.
- **Admin dashboard** (`admin/`): Flutter Web, section 12's content-review workflow — subjects,
  topics/lessons (10-part block editor), questions/quizzes, review queue, content reports, past
  papers (with Storage file upload), users & roles, audit log. Publishing is gated by
  `ContentLifecycle` (`admin/lib/domain/services/content_lifecycle.dart`): draft can't jump
  straight to published, and seed/unverified content can't publish at all. `flutter analyze
  --fatal-infos` clean, 12/12 tests passing. See [`admin/README.md`](admin/README.md) for exact
  coverage.
- **AI tutor scaffold**: `supabase/functions/quest-coach` — provider-independent, retrieval-grounded,
  rate-limited, with a zero-cost local stub when no API key is configured.
- **CI**: GitHub Actions — analyze/format/test, SQL lint, Android debug + release build, macOS
  unsigned-iOS-archive workflow, and an admin dashboard analyze/test/web-build workflow. **App and
  backend jobs verified green** on
  [github.com/DestroyerOfCode12/grade12](https://github.com/DestroyerOfCode12/grade12/actions):
  every job passed, including both Android build jobs, which could not be verified on the local
  dev machine (JVM-level loopback-socket restriction, unrelated to the app — see `docs/SETUP.md`
  §7 and `CONTINUATION.md`). Admin CI jobs are new and not yet confirmed on a live run — check
  Actions before relying on them.
- **Docs**: architecture decision record, data model, threat model, privacy policy draft, terms of
  use draft, Play Store data-safety and Apple privacy-label checklists.

## What's not built yet

Full curriculum content beyond one demo Mathematics topic, real past-paper ingestion (checksum
verification, bulk import), offline download management, most of the 26 mobile-app screens in the
brief, production AI-tutor citation verification, and several admin-dashboard capabilities (bulk
operations, content-version rollback UI, source-reference management UI — see
[`admin/README.md`](admin/README.md)). Full list with rationale: [`CONTINUATION.md`](CONTINUATION.md).

## Repository layout

```
app/                    Flutter mobile app (Android + iOS) — learner-facing
admin/                  Flutter Web staff dashboard (section 12) — content review & moderation
supabase/
  migrations/           Postgres schema + RLS, numbered and sequential
  seed/                 Local/dev seed data (subject catalogue + demo Mathematics content)
  functions/            Supabase Edge Functions (quest-coach AI tutor)
  tests/                pgTAP RLS/idempotency tests (run via `supabase test db`)
docs/                   ADR, data model, threat model, privacy/terms drafts, store checklists
.github/workflows/      CI (analyze/test/build for both app and admin)
```

## Quick start

See [`docs/SETUP.md`](docs/SETUP.md) for full instructions. In short:

```bash
cd app
flutter pub get
flutter test
flutter run   # runs in local dev mode with zero backend configured — see app/.env.example
```

## License and content sourcing

Original app code is [choose a license before release]. Curriculum content sourcing, verification
status, and copyright handling for official DBE material follows the policy in
[`docs/DATA_MODEL.md`](docs/DATA_MODEL.md#curriculum) — nothing in this repo claims to be official
DBE content unless its `verification_status` is `verified` and it carries a `source_references` row.
