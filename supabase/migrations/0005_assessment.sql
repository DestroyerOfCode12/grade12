-- MatricQuest SA — 0005: questions, quizzes, attempts, mastery
-- Idempotency (section 13): attempts and attempt_answers carry a client-generated idempotency_key
-- so a retried submission cannot award XP or record a mark twice.

create table if not exists questions (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references topics(id) on delete cascade,
  kind question_kind not null,
  prompt_markdown text not null,
  difficulty smallint not null default 2 check (difficulty between 1 and 5),
  marks numeric(5,2) not null default 1 check (marks > 0),
  language_code text not null default 'en',
  rubric_markdown text,                  -- used for essay/extended-response self-assessment
  content_status content_status not null default 'draft',
  verification_status verification_status not null default 'unverified',
  is_seed_demo_content boolean not null default false,
  source_paper_id uuid,                    -- set when lifted from a past paper (FK added in 0006)
  created_by uuid references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists questions_topic_idx on questions (topic_id);
create index if not exists questions_status_idx on questions (content_status);

drop trigger if exists trg_questions_updated_at on questions;
create trigger trg_questions_updated_at before update on questions
  for each row execute function set_updated_at();

create table if not exists question_options (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references questions(id) on delete cascade,
  label text not null,                 -- 'A', 'B', 'C', 'D' or matching-pair key
  body_markdown text not null,
  is_correct boolean not null default false,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists question_options_question_idx on question_options (question_id);

create table if not exists question_solutions (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references questions(id) on delete cascade,
  solution_markdown text not null,        -- the worked/official solution or memorandum guidance
  is_official_memorandum boolean not null default false,  -- true only when sourced from a DBE memo
  explanation_markdown text,               -- additional teaching explanation, kept separate (section 6)
  created_at timestamptz not null default now()
);

create index if not exists question_solutions_question_idx on question_solutions (question_id);

create table if not exists quizzes (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references topics(id) on delete cascade,
  title text not null,
  quiz_kind text not null default 'checkpoint' check (quiz_kind in (
    'checkpoint', 'daily_challenge', 'boss_battle', 'diagnostic'
  )),
  content_status content_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists quizzes_topic_idx on quizzes (topic_id);

drop trigger if exists trg_quizzes_updated_at on quizzes;
create trigger trg_quizzes_updated_at before update on quizzes
  for each row execute function set_updated_at();

create table if not exists quiz_questions (
  quiz_id uuid not null references quizzes(id) on delete cascade,
  question_id uuid not null references questions(id) on delete cascade,
  sort_order int not null default 0,
  primary key (quiz_id, question_id)
);

create table if not exists attempts (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id) on delete cascade,   -- null for guest/local-only attempts synced later
  quiz_id uuid references quizzes(id) on delete set null,
  paper_id uuid,                                                  -- FK added in 0006 once papers exists
  mode attempt_mode not null default 'practice',
  idempotency_key text not null,          -- client-generated UUID; unique per profile
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  time_limit_seconds int,
  marks_earned numeric(6,2),
  marks_available numeric(6,2),
  is_offline_attempt boolean not null default false,
  synced_at timestamptz,
  created_at timestamptz not null default now(),
  unique (profile_id, idempotency_key)
);

create index if not exists attempts_profile_idx on attempts (profile_id);
create index if not exists attempts_quiz_idx on attempts (quiz_id);

create table if not exists attempt_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references attempts(id) on delete cascade,
  question_id uuid not null references questions(id) on delete cascade,
  selected_option_ids uuid[] not null default '{}',
  free_text_answer text,
  is_correct boolean,                     -- null until marked (essay/structured may need self-marking)
  marks_awarded numeric(5,2),
  self_assessed boolean not null default false,
  answered_at timestamptz not null default now(),
  unique (attempt_id, question_id)
);

create index if not exists attempt_answers_attempt_idx on attempt_answers (attempt_id);

create table if not exists mastery_scores (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  topic_id uuid not null references topics(id) on delete cascade,
  mastery_estimate numeric(5,2) not null default 0 check (mastery_estimate between 0 and 100),
  readiness_label text not null default 'not_started' check (readiness_label in (
    'not_started', 'needs_work', 'developing', 'on_track', 'strong'
  )),
  attempts_count int not null default 0,
  last_attempt_at timestamptz,
  next_review_due_at timestamptz,          -- spaced-repetition scheduling
  updated_at timestamptz not null default now(),
  unique (profile_id, topic_id)
);

create index if not exists mastery_scores_profile_idx on mastery_scores (profile_id);
create index if not exists mastery_scores_due_idx on mastery_scores (next_review_due_at);

drop trigger if exists trg_mastery_scores_updated_at on mastery_scores;
create trigger trg_mastery_scores_updated_at before update on mastery_scores
  for each row execute function set_updated_at();
