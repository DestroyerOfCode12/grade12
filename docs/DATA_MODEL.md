# Data Model — MatricQuest SA

Full DDL lives in [`supabase/migrations/`](../supabase/migrations); this is the narrative map.
Every table below exists in the migrations; see the file name in parentheses.

## Identity & preferences
- **profiles** (0002) — mirrors `auth.users`; nickname (public, never real name by default),
  role, timezone, `is_minor` (generated column), soft-delete via `deleted_at`.
- **learner_preferences** (0002) — subjects/language/exam year/target marks/data-saver/accessibility.
- **notification_preferences** (0002) — reminder cadence, push token.

## Curriculum (section 2/12 — versioned, source-tracked, updatable without an app release)
- **subjects** (0003) — the FET catalogue; `content_status` + `verification_status` +
  `papers_available` / `lessons_in_review` / `full_course_available` flags so the catalogue can be
  transparent about coverage instead of all-or-nothing.
- **subject_languages** (0003), **curriculum_versions** (0003), **topics** (0003, self-referencing
  for subtopics), **source_references** (0003, polymorphic citation for any content row),
  **content_versions** (0003, rollback history), **review_tasks** (0003, manual review queue),
  **content_reports** (0003, learner-submitted reports).

## Lessons
- **lessons** (0004), **lesson_blocks** (0004 — the 10-part lesson structure from section 5, one
  row per block type), **flashcards** (0004).

## Assessment
- **questions** (0005), **question_options** (0005), **question_solutions** (0005 — separates
  `is_official_memorandum` guidance from `explanation_markdown` teaching notes, section 6),
  **quizzes** / **quiz_questions** (0005), **attempts** / **attempt_answers** (0005, idempotent via
  `(profile_id, idempotency_key)`), **mastery_scores** (0005 — `mastery_estimate` +
  `readiness_label`, never called a "predicted result", plus `next_review_due_at` for spaced
  repetition).

## Past papers
- **papers** (0006 — year/session/paper number/language/exam type/checksum/association_confidence),
  **paper_assets** (0006 — question paper/memo/addendum/formula sheet as separate rows),
  **paper_attempts** (0006, idempotent like `attempts`), **bookmarks**, **downloads** (0006).

## Planning
- **study_plans**, **study_sessions** (0007).

## Gamification (section 8/13 — XP is idempotent by design)
- **xp_events** (0008 — append-only ledger, `(profile_id, idempotency_key)` unique; total XP is
  `sum(amount)`, never a mutable counter that can drift), **streaks** (0008 — timezone-aware, freeze
  tokens earned not bought), **achievements** / **user_achievements**, **challenges**,
  **leaderboard_entries** (0008 — opt-in only, enforced in RLS).

## AI tutor
- **tutor_conversations**, **tutor_usage_daily** (0009 — backs the per-learner rate limit/cost cap).

## Governance
- **audit_log** (0010 — append-only, admin-read-only, no update/delete policy exists at all).

## Security model (0011)
Every learner-owned table is `USING (auth.uid() = profile_id)`. Every curriculum table is
public-read *only* when `content_status = 'published'`; staff roles (`content_reviewer`, `admin`,
`super_admin`) read/write everything via `is_staff()`. `xp_events` has no client insert policy at
all — the only way to add XP is the `grant_xp()` SECURITY DEFINER function (0012), which is what
makes XP idempotent end to end rather than just "idempotent if the client behaves."

## Idempotency (section 13), concretely
- `attempts`, `paper_attempts`, `xp_events` all carry a client-generated `idempotency_key` (a UUID
  made once when the learner starts the action, stored locally, reused on every retry).
- `grant_xp(profile_id, amount, reason, source_entity_type, source_entity_id, idempotency_key)` and
  `submit_attempt(attempt_id, marks_earned, marks_available)` are the only way to write those rows;
  both are `SECURITY DEFINER` and both check-then-insert inside the same statement.
- The Drift `outbox` table (mobile) reuses the exact same idempotency key it generated offline when
  it finally syncs, so a paper finished on the bus with no signal cannot double-submit once the
  learner is back on Wi-Fi.
