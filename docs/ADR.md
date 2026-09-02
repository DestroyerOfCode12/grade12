# Architecture Decision Record — MatricQuest SA

Status: **Accepted for v0.1 (foundation + vertical slice)**. Revisit each decision at the end of
Phase 3 (content infrastructure) once real usage data exists.

## 1. Context

MatricQuest SA is a CAPS-aligned, gamified study app for South African Grade 12 learners, covering
every official FET subject, past papers with memoranda, an AI tutor grounded only in reviewed
content, offline-first study on low-cost devices, and a staff-only content/admin workflow. See the
product brief for full scope; this ADR records the technical decisions and why.

## 2. Decisions

### 2.1 Client: Flutter + Dart, single codebase for Android and iOS
Two native codebases would double the cost of every future change to lessons, quizzes, and offline
sync — the highest-churn part of this app. Flutter's ahead-of-time compilation gives acceptable
performance on low-cost Android devices (a core requirement, section 10), and one codebase keeps
CAPS-content-driven UI (rendered from `lesson_blocks`, not hand-built per screen) consistent across
platforms.

### 2.2 State management: Riverpod
Testable without a `BuildContext`, compile-time-safe provider graph, and scopes cleanly to
per-feature providers (subject catalogue, study plan, offline sync queue) without a global store.
Chosen over Bloc/Provider for less boilerplate at this team size and better support for combining
async (Supabase) and sync (Drift) data sources in one derived provider.

### 2.3 Navigation: GoRouter
Declarative, deep-link friendly (needed for "resume this paper attempt" / push notification →
specific lesson), and integrates with Riverpod for auth-gated redirects (guest vs signed-in vs
admin) without imperative navigator plumbing.

### 2.4 Backend: Supabase (Postgres + Auth + Storage + RLS + Edge Functions)
A single Postgres database gives us real relational integrity for a genuinely relational domain
(subjects → topics → lessons → questions → attempts → mastery). Row Level Security lets every
learner-data table be locked down at the database layer (section 14) rather than trusted to
application code alone. Edge Functions host the AI tutor and other server-side logic without a
separate backend service to operate. Supabase Storage holds paper PDFs and lesson media behind
signed URLs. All of this is one managed platform a small team can actually run.

### 2.5 Offline storage: Drift (SQLite) mirroring a subset of the Postgres schema
The app must work with no connection at all (section 10). Drift gives typed, testable local
queries and a migration story on-device. The local schema mirrors `subjects/topics/lessons/
questions/quizzes/attempts/xp_events` for anything downloaded, plus an `outbox` table of
not-yet-synced writes keyed by the same idempotency keys the server functions expect — so a retried
sync can never double-award XP or double-submit an attempt (section 13).

### 2.6 AI layer: provider-independent service behind Supabase Edge Functions
`supabase/functions/_shared/ai_provider.ts` defines an `AiProvider` interface; the concrete
implementation (Anthropic today) is chosen by one factory function reading an environment secret.
No provider SDK, key, or prompt ever ships in the mobile bundle. A `LocalStubProvider` lets the app
run in local dev / CI with zero external calls and zero cost.

### 2.7 Curriculum content is data, not code
Subjects, topics, lessons, questions, and papers are Postgres rows with a `content_status`
lifecycle (`draft → in_review → approved → published → archived`, section 12), not Dart source. The
app renders `lesson_blocks` generically. This is what lets curriculum updates ship without an app
store release (section 2's explicit requirement) and is why the schema (section 13) exists before
any UI does.

### 2.8 CI: GitHub Actions, Windows/Linux runner for Flutter analyze/test/Android build,
macOS runner for an **unsigned** iOS archive only
We do not have Apple Developer signing credentials in this environment, and per the brief we must
never claim to produce a signed IPA without them. The iOS workflow builds and archives unsigned to
catch platform-specific compile breaks early; producing a distributable IPA is a manual step once
the user supplies their own certificates and provisioning profile.

## 3. Consequences

- Every content table needs an RLS policy from day one (done in `0011_row_level_security.sql`) —
  there is no "add security later" phase.
- The offline/online data model has to be designed together, not offline-first bolted onto an
  online-first schema — hence idempotency keys living in the core schema, not as an afterthought.
- The AI tutor cannot ship before retrieval-grounding and rate limiting exist, because the schema
  and Edge Function are the same deliverable (`tutor_conversations` + `tutor_usage_daily` +
  `quest-coach/index.ts`).

## 4. Alternatives considered and rejected

- **Native Android (Kotlin) + native iOS (Swift):** rejected — doubles ongoing cost for a
  content-heavy app whose difficulty is in curriculum coverage, not platform-specific UI.
- **Firebase (Firestore) instead of Supabase/Postgres:** rejected — the domain is deeply relational
  (papers ↔ memoranda ↔ questions ↔ topics ↔ mastery) and Postgres RLS + SQL joins are a better fit
  than document-store denormalization for the analytics this app needs (topic-level mastery,
  readiness scores).
- **A custom Node/Express backend instead of Supabase:** rejected for v0.1 — more infrastructure to
  operate for no capability MatricQuest SA needs that Supabase (Postgres + RLS + Edge Functions)
  doesn't already provide. Revisit only if a specific Supabase limitation is hit.
- **Bundling a single global AI vendor SDK directly into the Flutter app:** rejected — violates
  "never expose provider keys client-side" and forecloses switching providers.
