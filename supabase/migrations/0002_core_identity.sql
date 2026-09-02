-- MatricQuest SA — 0002: profiles, learner preferences, notification preferences
-- profiles.id mirrors auth.users.id (Supabase auth). Guest/local-only learners never get a row here.

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname citext not null,                 -- shown on leaderboards; never the learner's real name
  display_name text,                          -- optional, private, shown only to the learner themself
  role app_role not null default 'learner',
  avatar_config jsonb not null default '{}'::jsonb,   -- cosmetic avatar layers, no PII
  timezone text not null default 'Africa/Johannesburg',
  date_of_birth date,                          -- used only to gate under-18 protections; never displayed
  is_leaderboard_opt_in boolean not null default false,
  is_profile_private boolean not null default true,
  is_minor boolean generated always as (
    date_of_birth is not null and date_of_birth > (current_date - interval '18 years')
  ) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,                      -- soft delete marker set by the account-deletion flow
  constraint nickname_length check (char_length(nickname) between 3 and 24)
);

create unique index if not exists profiles_nickname_unique_idx on profiles (nickname) where deleted_at is null;
create index if not exists profiles_role_idx on profiles (role);

drop trigger if exists trg_profiles_updated_at on profiles;
create trigger trg_profiles_updated_at before update on profiles
  for each row execute function set_updated_at();

create table if not exists learner_preferences (
  profile_id uuid primary key references profiles(id) on delete cascade,
  preferred_language text not null default 'en',
  examination_year int not null default (date_part('year', now()))::int,
  target_marks jsonb not null default '{}'::jsonb,      -- {subject_id: target_percentage}
  difficult_topics uuid[] not null default '{}',          -- topics learner flagged as hard
  daily_study_minutes int not null default 30 check (daily_study_minutes > 0),
  data_saver_mode boolean not null default false,
  wifi_only_downloads boolean not null default true,
  reduce_motion boolean not null default false,
  high_contrast boolean not null default false,
  dynamic_font_scale numeric(3,2) not null default 1.00 check (dynamic_font_scale between 0.80 and 2.00),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_learner_preferences_updated_at on learner_preferences;
create trigger trg_learner_preferences_updated_at before update on learner_preferences
  for each row execute function set_updated_at();

create table if not exists notification_preferences (
  profile_id uuid primary key references profiles(id) on delete cascade,
  daily_reminder boolean not null default true,
  daily_reminder_time time not null default '17:00',
  streak_risk_alert boolean not null default true,
  weekly_recap boolean not null default true,
  push_token text,                                 -- FCM/APNs token, rotated client-side
  push_token_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_notification_preferences_updated_at on notification_preferences;
create trigger trg_notification_preferences_updated_at before update on notification_preferences
  for each row execute function set_updated_at();
