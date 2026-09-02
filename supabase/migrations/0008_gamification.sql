-- MatricQuest SA — 0008: XP, streaks, achievements, challenges, leaderboards
-- xp_events is the single source of truth for XP; idempotency_key prevents duplicate rewards
-- from retried requests (section 13). A learner's total XP/level is a derived sum, never stored
-- redundantly in a way that could drift.

create table if not exists xp_events (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  amount int not null check (amount > 0),
  reason text not null check (reason in (
    'lesson_completed', 'quiz_passed', 'correction_completed', 'daily_challenge',
    'boss_battle', 'streak_bonus', 'paper_attempt_completed'
  )),
  source_entity_type text,          -- 'lesson' | 'quiz' | 'attempt' | 'paper_attempt' | ...
  source_entity_id uuid,
  idempotency_key text not null,
  created_at timestamptz not null default now(),
  unique (profile_id, idempotency_key)
);

create index if not exists xp_events_profile_idx on xp_events (profile_id);

create table if not exists streaks (
  profile_id uuid primary key references profiles(id) on delete cascade,
  current_streak_days int not null default 0,
  longest_streak_days int not null default 0,
  last_active_local_date date,             -- computed client/server-side in profile.timezone
  freeze_tokens int not null default 0,    -- earned via learning activities, never purchased
  timezone text not null default 'Africa/Johannesburg',
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_streaks_updated_at on streaks;
create trigger trg_streaks_updated_at before update on streaks
  for each row execute function set_updated_at();

create table if not exists achievements (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title text not null,
  description text not null,
  category text not null default 'subject_badge' check (category in (
    'subject_badge', 'topic_mastery_medal', 'streak', 'challenge', 'milestone'
  )),
  icon_key text,
  created_at timestamptz not null default now()
);

create table if not exists user_achievements (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  achievement_id uuid not null references achievements(id) on delete cascade,
  earned_at timestamptz not null default now(),
  unique (profile_id, achievement_id)
);

create index if not exists user_achievements_profile_idx on user_achievements (profile_id);

create table if not exists challenges (
  id uuid primary key default gen_random_uuid(),
  challenge_kind text not null check (challenge_kind in ('daily', 'weekly', 'friend')),
  title text not null,
  description text,
  topic_id uuid references topics(id),
  quiz_id uuid references quizzes(id),
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  xp_reward int not null default 20 check (xp_reward > 0),
  created_at timestamptz not null default now()
);

create index if not exists challenges_window_idx on challenges (starts_at, ends_at);

-- Opt-in only (section 8/14): a row here requires profiles.is_leaderboard_opt_in = true,
-- enforced by the leaderboard_entries_opt_in_only RLS policy + a check in app code.
create table if not exists leaderboard_entries (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  scope text not null default 'weekly' check (scope in ('weekly', 'all_time', 'subject')),
  subject_id uuid references subjects(id),
  xp_total int not null default 0,
  period_start date not null,
  period_end date not null,
  updated_at timestamptz not null default now(),
  unique (profile_id, scope, subject_id, period_start)
);

create index if not exists leaderboard_entries_scope_idx on leaderboard_entries (scope, period_start);

drop trigger if exists trg_leaderboard_entries_updated_at on leaderboard_entries;
create trigger trg_leaderboard_entries_updated_at before update on leaderboard_entries
  for each row execute function set_updated_at();
