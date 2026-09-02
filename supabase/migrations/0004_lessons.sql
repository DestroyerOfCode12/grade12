-- MatricQuest SA — 0004: lessons, lesson content blocks, flashcards

create table if not exists lessons (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references topics(id) on delete cascade,
  title text not null,
  language_code text not null default 'en',
  estimated_minutes int not null default 6 check (estimated_minutes > 0),
  content_status content_status not null default 'draft',
  verification_status verification_status not null default 'unverified',
  is_seed_demo_content boolean not null default false,  -- true = clearly-labelled demo, not curriculum-verified
  sort_order int not null default 0,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists lessons_topic_idx on lessons (topic_id);
create index if not exists lessons_status_idx on lessons (content_status);

drop trigger if exists trg_lessons_updated_at on lessons;
create trigger trg_lessons_updated_at before update on lessons
  for each row execute function set_updated_at();

-- Each lesson is composed of ordered blocks matching the 10-part lesson structure (section 5):
-- explanation, simpler_explanation, local_example, definition_formula, visual, worked_example,
-- common_mistakes, checkpoint_quiz_ref, exam_style_question_ref, correction_lesson_ref, citation.
create table if not exists lesson_blocks (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references lessons(id) on delete cascade,
  block_type text not null check (block_type in (
    'explanation', 'simpler_explanation', 'local_example', 'definition_or_formula',
    'visual', 'worked_example', 'common_mistakes', 'checkpoint_quiz_ref',
    'exam_style_question_ref', 'correction_lesson_ref', 'citation'
  )),
  sort_order int not null default 0,
  body_markdown text,
  media_url text,                     -- image/audio/diagram asset in Supabase Storage
  media_alt_text text,                -- required for non-decorative media (accessibility, section 15)
  ref_quiz_id uuid,                    -- set when block_type references a quiz
  ref_question_id uuid,                -- set when block_type references a question
  ref_lesson_id uuid references lessons(id), -- set when block_type = correction_lesson_ref
  created_at timestamptz not null default now()
);

create index if not exists lesson_blocks_lesson_idx on lesson_blocks (lesson_id, sort_order);

create table if not exists flashcards (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references topics(id) on delete cascade,
  front_markdown text not null,
  back_markdown text not null,
  language_code text not null default 'en',
  content_status content_status not null default 'draft',
  is_seed_demo_content boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists flashcards_topic_idx on flashcards (topic_id);

drop trigger if exists trg_flashcards_updated_at on flashcards;
create trigger trg_flashcards_updated_at before update on flashcards
  for each row execute function set_updated_at();
