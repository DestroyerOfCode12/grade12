-- MatricQuest SA — 0007: personalised study plans and scheduled sessions

create table if not exists study_plans (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  examination_year int not null,
  generated_from text not null default 'diagnostic' check (generated_from in (
    'diagnostic', 'mastery_recalculation', 'manual_edit'
  )),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists study_plans_profile_idx on study_plans (profile_id);

drop trigger if exists trg_study_plans_updated_at on study_plans;
create trigger trg_study_plans_updated_at before update on study_plans
  for each row execute function set_updated_at();

create table if not exists study_sessions (
  id uuid primary key default gen_random_uuid(),
  study_plan_id uuid not null references study_plans(id) on delete cascade,
  subject_id uuid not null references subjects(id) on delete cascade,
  topic_id uuid references topics(id) on delete set null,
  scheduled_for date not null,
  duration_minutes int not null default 20 check (duration_minutes > 0),
  session_kind text not null default 'lesson' check (session_kind in (
    'lesson', 'quiz_review', 'flashcards', 'past_paper', 'spaced_repetition'
  )),
  status text not null default 'scheduled' check (status in ('scheduled', 'completed', 'skipped', 'rescheduled')),
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists study_sessions_plan_idx on study_sessions (study_plan_id);
create index if not exists study_sessions_scheduled_idx on study_sessions (scheduled_for);
