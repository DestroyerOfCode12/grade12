-- MatricQuest SA — 0009: Quest Coach (AI tutor) conversation log
-- Stores only what's needed for continuity, cost/rate-limit accounting and abuse review.
-- The tutor itself runs server-side (Supabase Edge Function); this table never stores
-- provider API keys or raw model prompts containing other users' data.

create table if not exists tutor_conversations (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  subject_id uuid references subjects(id),
  topic_id uuid references topics(id),
  mode text not null default 'teach_me' check (mode in ('teach_me', 'give_hint', 'check_work')),
  turn_index int not null default 0,
  learner_message text,
  learner_image_path text,               -- Supabase Storage path when a photographed question was sent
  tutor_response text,
  cited_sources jsonb not null default '[]'::jsonb,  -- [{entity_type, entity_id, title}]
  could_not_verify boolean not null default false,
  flagged_for_review boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists tutor_conversations_profile_idx on tutor_conversations (profile_id, created_at);

-- Per-profile per-day usage counter backing the tutor's rate limit and cost cap.
create table if not exists tutor_usage_daily (
  profile_id uuid not null references profiles(id) on delete cascade,
  usage_date date not null default current_date,
  request_count int not null default 0,
  estimated_cost_cents int not null default 0,
  primary key (profile_id, usage_date)
);
