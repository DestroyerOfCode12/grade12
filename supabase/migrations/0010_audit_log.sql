-- MatricQuest SA — 0010: audit log for admin/content actions (section 14)

create table if not exists audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references profiles(id) on delete set null,
  actor_role app_role,
  action text not null,              -- e.g. 'content.publish', 'admin.role_change', 'paper.import'
  entity_type text,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  ip_hash text,                        -- hashed, never raw IP
  created_at timestamptz not null default now()
);

create index if not exists audit_log_actor_idx on audit_log (actor_id);
create index if not exists audit_log_entity_idx on audit_log (entity_type, entity_id);
create index if not exists audit_log_created_idx on audit_log (created_at);

-- Audit rows are append-only: no update/delete policy is ever granted (enforced in 0011 RLS).
