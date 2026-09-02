-- MatricQuest SA — 0006: past examination papers, assets, attempts, bookmarks, downloads

create table if not exists papers (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references subjects(id) on delete cascade,
  exam_year int not null check (exam_year between 1994 and 2100),
  session paper_session not null,
  paper_number smallint not null default 1,
  language_code text not null default 'en',
  exam_type paper_exam_type not null default 'nsc',
  title text not null,
  source_url text not null,
  verification_date date,
  file_checksum text,                    -- sha256 of the question-paper file
  download_size_bytes bigint,
  interactive_conversion_status text not null default 'not_started' check (
    interactive_conversion_status in ('not_started', 'in_progress', 'available', 'not_applicable')
  ),
  association_confidence text not null default 'unconfirmed' check (
    association_confidence in ('unconfirmed', 'likely', 'confirmed')
  ),
  content_status content_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (subject_id, exam_year, session, paper_number, language_code, exam_type)
);

create index if not exists papers_subject_idx on papers (subject_id);
create index if not exists papers_year_idx on papers (exam_year);
create index if not exists papers_search_idx on papers using gin (title gin_trgm_ops);

drop trigger if exists trg_papers_updated_at on papers;
create trigger trg_papers_updated_at before update on papers
  for each row execute function set_updated_at();

alter table questions
  add constraint questions_source_paper_fk foreign key (source_paper_id) references papers(id) on delete set null;

alter table attempts
  add constraint attempts_paper_fk foreign key (paper_id) references papers(id) on delete set null;

create table if not exists paper_assets (
  id uuid primary key default gen_random_uuid(),
  paper_id uuid not null references papers(id) on delete cascade,
  asset_kind text not null check (asset_kind in (
    'question_paper', 'memorandum', 'addendum', 'formula_sheet', 'data_sheet', 'other'
  )),
  storage_path text not null,           -- Supabase Storage object path
  file_checksum text,
  file_size_bytes bigint,
  mime_type text not null default 'application/pdf',
  created_at timestamptz not null default now()
);

create index if not exists paper_assets_paper_idx on paper_assets (paper_id);

create table if not exists paper_attempts (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id) on delete cascade,
  paper_id uuid not null references papers(id) on delete cascade,
  idempotency_key text not null,
  mode attempt_mode not null default 'timed_exam',
  started_at timestamptz not null default now(),
  paused_at timestamptz,
  submitted_at timestamptz,
  marks_earned numeric(6,2),
  marks_available numeric(6,2),
  is_offline_attempt boolean not null default false,
  synced_at timestamptz,
  created_at timestamptz not null default now(),
  unique (profile_id, idempotency_key)
);

create index if not exists paper_attempts_profile_idx on paper_attempts (profile_id);
create index if not exists paper_attempts_paper_idx on paper_attempts (paper_id);

create table if not exists bookmarks (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  entity_type text not null check (entity_type in ('paper', 'lesson', 'question', 'topic')),
  entity_id uuid not null,
  created_at timestamptz not null default now(),
  unique (profile_id, entity_type, entity_id)
);

create index if not exists bookmarks_profile_idx on bookmarks (profile_id);

create table if not exists downloads (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  entity_type text not null check (entity_type in ('paper', 'subject_pack', 'lesson_pack')),
  entity_id uuid not null,
  status download_status not null default 'queued',
  bytes_total bigint,
  bytes_downloaded bigint not null default 0,
  wifi_only boolean not null default true,
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  removed_at timestamptz
);

create index if not exists downloads_profile_idx on downloads (profile_id);
create index if not exists downloads_status_idx on downloads (status);
