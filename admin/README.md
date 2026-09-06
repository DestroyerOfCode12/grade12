# MatricQuest SA — Staff Dashboard

Flutter Web admin/content-review dashboard implementing section 12 of the product brief. Separate
app, separate deployment from the learner-facing `app/` — staff tooling never ships inside the
mobile bundle.

See [`../docs/SETUP.md`](../docs/SETUP.md) §3 for how to run it, and
[`../CONTINUATION.md`](../CONTINUATION.md) for how this fits into the overall project checkpoint.

## What's covered

- **Auth & access control**: sign-in via Supabase Auth; a `profiles.role` check gates the whole
  dashboard (learner/no-role → refused), and admin-only sections (Users & roles, Audit log) are
  further hidden from `content_reviewer` accounts. RLS is the real enforcement in every case — this
  UI gating is a convenience, not the security boundary.
- **Dashboard**: aggregate counts only (subjects, published lessons, open review tasks, open
  reports, learner count, papers) — never a raw learner list with identifying detail.
- **Subjects**: list, create, edit `content_status`/`verification_status`/coverage flags
  (papers available / lessons in review / full course available).
- **Topics, lessons, questions, quizzes**: create topics under a subject; create/edit lessons and
  their 10-part block structure (section 5); create multiple-choice questions with options and a
  solution (kept separate from teaching explanation, section 6); status transitions for all of the
  above go through `ContentLifecycle` (`lib/domain/services/content_lifecycle.dart`), which blocks
  jumping straight to `published` and blocks publishing anything flagged `is_seed_demo_content` or
  not yet `verified`/`source_recorded`.
- **Review queue**: open `review_tasks`, take/resolve/dismiss.
- **Content reports**: learner-submitted reports from the mobile app, status transitions.
- **Past papers**: create paper metadata records, upload question-paper/memorandum/addendum/
  formula-sheet PDFs to Supabase Storage, confirm subject association, move through the content
  lifecycle.
- **Users & roles**: search learners by nickname, change roles via `admin_set_user_role()` (never
  a direct table update — that RPC is what makes role changes audited).
- **Audit log**: read-only, admin-only.

## What's not covered yet

- Bulk operations (bulk-publish, bulk-import) — everything above is one-record-at-a-time.
- A richer "review AI-generated drafts" diff/compare view — the review queue links to the entity by
  ID today; jumping straight to a pre-filled diff is future work.
- Content version rollback UI (`content_versions_repository.dart` can read history; there's no
  screen to actually restore a prior snapshot yet).
- Source reference management UI (`source_references` table exists and is read by
  `ContentVersionsRepository.fetchSourceReferences`, but nothing in the UI creates/edits rows there
  yet — subjects/topics/lessons need their citations added directly in SQL or a future ingestion
  pipeline).
- CAPS curriculum version management (`curriculum_versions` table exists, no screen).
- Checksum computation/verification for uploaded paper files (uploaded, not yet hashed client-side
  or verified against a stored checksum).
- Golden/visual tests; only domain-logic and one smoke test exist so far (see `test/`).

## Architecture notes

- Riverpod (plain providers, no codegen — same reasoning as `app/`, see the root
  `docs/SETUP.md` §8) + GoRouter (`ShellRoute` wrapping `AuthGate` wrapping `AdminShell`).
- No offline storage — this app always talks to Supabase directly; there is no local-dev-mode
  fallback because there is nothing meaningful to demo without real backend data to edit.
- `ContentLifecycle` (`lib/domain/services/content_lifecycle.dart`) is the single place that
  decides which `content_status` transitions are legal and whether a piece of content is eligible
  to publish — every editor screen defers to it rather than re-implementing the rule.
