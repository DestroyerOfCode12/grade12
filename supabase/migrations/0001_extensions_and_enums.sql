-- MatricQuest SA — 0001: extensions and shared enum types
-- Safe to re-run: guards with IF NOT EXISTS / DO blocks where Postgres allows it.

create extension if not exists "pgcrypto";      -- gen_random_uuid()
create extension if not exists "pg_trgm";        -- fuzzy search on paper/question text
create extension if not exists "citext";         -- case-insensitive nickname/email lookups

-- Content lifecycle used by every publishable content table (section 12).
do $$ begin
  create type content_status as enum (
    'draft', 'in_review', 'approved', 'published', 'rejected', 'archived'
  );
exception when duplicate_object then null; end $$;

-- Verification status recorded on every imported/generated curriculum artifact (section 2).
do $$ begin
  create type verification_status as enum (
    'unverified',           -- freshly imported, not yet checked against a DBE source
    'source_recorded',      -- source URL + retrieval date recorded, not yet cross-checked
    'pending_manual_review', -- flagged for a human curriculum reviewer
    'verified',              -- confirmed against an authoritative DBE document
    'disputed'               -- a report or review found a discrepancy
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type subject_level as enum ('home_language', 'first_additional', 'second_additional', 'core');
exception when duplicate_object then null; end $$;

do $$ begin
  create type caps_term as enum ('term_1', 'term_2', 'term_3', 'term_4', 'cross_term');
exception when duplicate_object then null; end $$;

do $$ begin
  create type question_kind as enum (
    'multiple_choice', 'true_false', 'short_answer', 'numeric', 'essay', 'structured', 'matching'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type paper_session as enum ('may_june', 'october_november', 'february_march', 'supplementary');
exception when duplicate_object then null; end $$;

do $$ begin
  create type paper_exam_type as enum ('nsc', 'sc', 'irr', 'amended_nsc');
exception when duplicate_object then null; end $$;

do $$ begin
  create type app_role as enum ('learner', 'educator', 'content_reviewer', 'admin', 'super_admin');
exception when duplicate_object then null; end $$;

do $$ begin
  create type download_status as enum ('queued', 'downloading', 'complete', 'failed', 'removed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type attempt_mode as enum ('practice', 'timed_exam', 'diagnostic', 'boss_battle', 'daily_challenge');
exception when duplicate_object then null; end $$;

-- Generic updated_at trigger reused by every table with an updated_at column.
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
