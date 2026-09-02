-- MatricQuest SA — 0003: subject catalogue, CAPS versions, topics, source tracking, review queue
-- Design goal (section 2 / 12): curriculum content can be updated without a new app release,
-- and nothing is presented as official DBE content unless verification_status = 'verified'
-- and a source_references row backs it.

create table if not exists subjects (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,                 -- stable machine key, e.g. 'mathematics', 'isizulu_hl'
  name text not null,                          -- official CAPS subject name
  category text not null,                      -- Languages | Mathematics & Sciences | Commerce | ...
  level subject_level not null default 'core', -- home_language / first_additional / second_additional / core
  grade int not null default 12 check (grade between 10 and 12),
  description text,
  content_status content_status not null default 'draft',
  verification_status verification_status not null default 'unverified',
  papers_available boolean not null default false,
  lessons_in_review boolean not null default false,
  full_course_available boolean not null default false,
  icon_key text,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists subjects_category_idx on subjects (category);
create index if not exists subjects_content_status_idx on subjects (content_status);

drop trigger if exists trg_subjects_updated_at on subjects;
create trigger trg_subjects_updated_at before update on subjects
  for each row execute function set_updated_at();

-- A subject may be offered in more than one language (e.g. Mathematics in English and Afrikaans).
create table if not exists subject_languages (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references subjects(id) on delete cascade,
  language_code text not null,          -- ISO 639-ish code: en, af, zu, xh, nso, st, tn, ss, ve, ts, nr, fr, zh
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  unique (subject_id, language_code)
);

-- Every distinct CAPS document version a subject's content is drawn from.
create table if not exists curriculum_versions (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references subjects(id) on delete cascade,
  version_label text not null,          -- e.g. "CAPS 2011 (amended 2020)"
  effective_year int,
  gazette_reference text,
  source_url text not null,
  retrieved_at timestamptz not null,
  verification_status verification_status not null default 'source_recorded',
  notes text,
  created_at timestamptz not null default now(),
  unique (subject_id, version_label)
);

create table if not exists topics (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references subjects(id) on delete cascade,
  curriculum_version_id uuid references curriculum_versions(id) on delete set null,
  parent_topic_id uuid references topics(id) on delete cascade,  -- null = top-level topic; else subtopic
  title text not null,
  term caps_term not null default 'term_1',
  learning_outcomes text[] not null default '{}',
  sort_order int not null default 0,
  content_status content_status not null default 'draft',
  verification_status verification_status not null default 'unverified',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists topics_subject_idx on topics (subject_id);
create index if not exists topics_parent_idx on topics (parent_topic_id);
create index if not exists topics_term_idx on topics (term);

drop trigger if exists trg_topics_updated_at on topics;
create trigger trg_topics_updated_at before update on topics
  for each row execute function set_updated_at();

-- Polymorphic source citation: every piece of content that claims a CAPS/DBE origin
-- must point to one of these rows. entity_type/entity_id is a loose FK (no cross-schema FK
-- possible cleanly with polymorphism); enforced instead by application code + a check constraint
-- on entity_type, and validated in tests (see supabase/tests).
create table if not exists source_references (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null check (entity_type in (
    'subject', 'curriculum_version', 'topic', 'lesson', 'lesson_block', 'flashcard',
    'question', 'paper', 'paper_asset'
  )),
  entity_id uuid not null,
  source_title text not null,
  source_url text not null,
  retrieved_at timestamptz not null,
  copyright_status text not null default 'unknown' check (copyright_status in (
    'public_domain_government_document', 'redistribution_permitted', 'link_out_only', 'unknown'
  )),
  verification_status verification_status not null default 'source_recorded',
  verified_by uuid references profiles(id),
  verified_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists source_references_entity_idx on source_references (entity_type, entity_id);

-- Generic version history for any publishable content row, enabling rollback (section 12).
create table if not exists content_versions (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  entity_id uuid not null,
  version_number int not null,
  snapshot jsonb not null,               -- full serialized row at this version
  content_status content_status not null,
  changed_by uuid references profiles(id),
  change_summary text,
  created_at timestamptz not null default now(),
  unique (entity_type, entity_id, version_number)
);

create index if not exists content_versions_entity_idx on content_versions (entity_type, entity_id);

-- Manual review queue for anything imported or AI-generated before it can reach 'published'.
create table if not exists review_tasks (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  entity_id uuid not null,
  reason text not null,                  -- 'ai_generated', 'imported_paper', 'uncertain_association', 'content_report', ...
  status text not null default 'open' check (status in ('open', 'in_progress', 'resolved', 'dismissed')),
  assigned_to uuid references profiles(id),
  priority smallint not null default 3 check (priority between 1 and 5),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz
);

create index if not exists review_tasks_status_idx on review_tasks (status);
create index if not exists review_tasks_entity_idx on review_tasks (entity_type, entity_id);

drop trigger if exists trg_review_tasks_updated_at on review_tasks;
create trigger trg_review_tasks_updated_at before update on review_tasks
  for each row execute function set_updated_at();

create table if not exists content_reports (
  id uuid primary key default gen_random_uuid(),
  reported_by uuid references profiles(id) on delete set null,
  entity_type text not null,
  entity_id uuid not null,
  reason text not null,
  details text,
  status text not null default 'open' check (status in ('open', 'reviewing', 'actioned', 'dismissed')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create index if not exists content_reports_entity_idx on content_reports (entity_type, entity_id);
create index if not exists content_reports_status_idx on content_reports (status);
