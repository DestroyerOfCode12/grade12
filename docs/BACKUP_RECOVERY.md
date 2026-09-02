# Backup and Recovery — MatricQuest SA

## Database

- **Automated backups**: Supabase provides daily automated backups (and point-in-time recovery on
  paid tiers) for the Postgres database — confirm the plan's retention window matches your
  recovery objectives before production launch, and document the chosen tier here once decided.
- **Manual snapshot before risky operations**: `supabase db dump -f backup_$(date +%Y%m%d).sql`
  before any migration that touches existing data (as opposed to purely additive DDL).
- **Content-level recovery**: `content_versions` (0003 migration) retains prior versions of any
  publishable row, independent of full-database backups — this is the fast path for "a reviewer
  published something wrong," rather than restoring the whole database.

## Storage (past papers, lesson media)

- Enable versioning/soft-delete on the Supabase Storage buckets once the ingestion pipeline
  (Phase 3) is live, so an accidental overwrite of a paper/memorandum file is recoverable.
- `paper_assets.file_checksum` lets you verify a restored file matches what was originally
  ingested.

## Mobile app / local data

- Guest-mode progress lives only on the learner's device (`lib/data/local/app_database.dart`).
  There is no server-side backup for it by design (section 10: guest mode is local-only) — the
  in-app prompt to create an account is the recovery path, not a database backup.
- A signed-in learner's authoritative state lives in Postgres and is covered by the database
  backup policy above.

## Incident response checklist (fill in before production launch)

1. Who has access to trigger a Supabase point-in-time restore, and how do they request it.
2. How learners are notified if a restore causes visible data loss (e.g. "your last 2 hours of
   quiz attempts may need to be redone").
3. Where the on-call rotation / escalation contact list lives (not in this public repo).
