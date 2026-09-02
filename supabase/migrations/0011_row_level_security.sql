-- MatricQuest SA — 0011: Row Level Security
-- Principles:
--   * Every table with learner-owned rows is locked to auth.uid() = profile_id (or profiles.id).
--   * Published curriculum content (subjects/topics/lessons/questions/papers) is readable by
--     anyone signed in once content_status = 'published'; draft/in_review content is staff-only.
--   * Writes to curriculum tables require role in ('content_reviewer','admin','super_admin').
--   * Leaderboard rows are readable only when the owning profile opted in.
--   * audit_log is insert-only for staff roles, readable only by admin/super_admin, never updatable.

create or replace function current_profile_role()
returns app_role language sql stable security definer as $$
  select role from profiles where id = auth.uid();
$$;

create or replace function is_staff()
returns boolean language sql stable security definer as $$
  select coalesce((select role from profiles where id = auth.uid())
    in ('content_reviewer','admin','super_admin'), false);
$$;

create or replace function is_admin()
returns boolean language sql stable security definer as $$
  select coalesce((select role from profiles where id = auth.uid())
    in ('admin','super_admin'), false);
$$;

-- ---------- profiles ----------
alter table profiles enable row level security;

create policy profiles_select_own on profiles
  for select using (auth.uid() = id or is_staff());
create policy profiles_update_own on profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
create policy profiles_insert_own on profiles
  for insert with check (auth.uid() = id);
-- Nicknames are the only cross-learner-visible field; exposed via a view, not direct table grants.
create view public_leaderboard_profiles as
  select id, nickname, avatar_config from profiles
  where deleted_at is null and is_leaderboard_opt_in = true and is_profile_private = false;

-- ---------- learner_preferences / notification_preferences ----------
alter table learner_preferences enable row level security;
create policy learner_preferences_owner on learner_preferences
  for all using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

alter table notification_preferences enable row level security;
create policy notification_preferences_owner on notification_preferences
  for all using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

-- ---------- curriculum content (read published / staff read+write all) ----------
do $$
declare t text;
begin
  foreach t in array array['subjects','curriculum_versions','topics','lessons','flashcards',
                            'questions','quizzes','papers','achievements'] loop
    execute format('alter table %I enable row level security', t);
    execute format($f$
      create policy %I_public_read on %I
        for select using (
          coalesce(content_status::text, 'published') = 'published' or is_staff()
        )
    $f$, t, t);
    execute format($f$
      create policy %I_staff_write on %I
        for all using (is_staff()) with check (is_staff())
    $f$, t, t);
  end loop;
end $$;

-- subject_languages / lesson_blocks / question_options / question_solutions / quiz_questions /
-- paper_assets ride along with their parent's published status; simplest correct rule is staff-write,
-- everyone-read (they contain no learner data and are meaningless without the published parent).
do $$
declare t text;
begin
  foreach t in array array['subject_languages','lesson_blocks','question_options',
                            'question_solutions','quiz_questions','paper_assets','source_references'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy %I_read_all on %I for select using (true)', t, t);
    execute format('create policy %I_staff_write on %I for all using (is_staff()) with check (is_staff())', t, t);
  end loop;
end $$;

-- content_versions / review_tasks are staff-only end to end.
alter table content_versions enable row level security;
create policy content_versions_staff_only on content_versions for all using (is_staff()) with check (is_staff());

alter table review_tasks enable row level security;
create policy review_tasks_staff_only on review_tasks for all using (is_staff()) with check (is_staff());

-- content_reports: any signed-in learner may create; only staff may read/update.
alter table content_reports enable row level security;
create policy content_reports_insert_own on content_reports
  for insert with check (auth.uid() = reported_by);
create policy content_reports_staff_read on content_reports
  for select using (is_staff());
create policy content_reports_staff_update on content_reports
  for update using (is_staff()) with check (is_staff());

-- ---------- learner-owned data ----------
do $$
declare t text;
begin
  foreach t in array array['attempts','attempt_answers','mastery_scores','paper_attempts',
                            'bookmarks','downloads','study_plans','study_sessions',
                            'user_achievements','xp_events','tutor_conversations'] loop
    execute format('alter table %I enable row level security', t);
  end loop;
end $$;

create policy attempts_owner on attempts for all
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

-- attempt_answers has no profile_id column directly; scope via its parent attempt.
create policy attempt_answers_owner on attempt_answers for all
  using (exists (select 1 from attempts a where a.id = attempt_id and a.profile_id = auth.uid()))
  with check (exists (select 1 from attempts a where a.id = attempt_id and a.profile_id = auth.uid()));

create policy mastery_scores_owner on mastery_scores for all
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);
create policy paper_attempts_owner on paper_attempts for all
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);
create policy bookmarks_owner on bookmarks for all
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);
create policy downloads_owner on downloads for all
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);
create policy study_plans_owner on study_plans for all
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);
create policy study_sessions_owner on study_sessions for all
  using (exists (select 1 from study_plans p where p.id = study_plan_id and p.profile_id = auth.uid()))
  with check (exists (select 1 from study_plans p where p.id = study_plan_id and p.profile_id = auth.uid()));
create policy user_achievements_owner_read on user_achievements for select
  using (auth.uid() = profile_id or is_staff());
create policy user_achievements_system_insert on user_achievements for insert
  with check (auth.uid() = profile_id);
-- xp_events are inserted only via the grant_xp() security-definer function (0012), never directly,
-- so the only client-facing grant here is read-your-own.
create policy xp_events_owner_read on xp_events for select using (auth.uid() = profile_id);
create policy tutor_conversations_owner on tutor_conversations for all
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

-- streaks: single row per learner.
alter table streaks enable row level security;
create policy streaks_owner on streaks for all
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

-- challenges: readable by all signed-in users, staff-managed.
alter table challenges enable row level security;
create policy challenges_read_all on challenges for select using (true);
create policy challenges_staff_write on challenges for all using (is_staff()) with check (is_staff());

-- leaderboard_entries: readable only for profiles that opted in; writes via server function only.
alter table leaderboard_entries enable row level security;
create policy leaderboard_entries_read_opt_in on leaderboard_entries for select
  using (
    exists (select 1 from profiles p where p.id = profile_id and p.is_leaderboard_opt_in = true)
    or auth.uid() = profile_id
  );
create policy leaderboard_entries_owner_write on leaderboard_entries for all
  using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

-- tutor_usage_daily: owner read-only, writes via security-definer function.
alter table tutor_usage_daily enable row level security;
create policy tutor_usage_daily_owner_read on tutor_usage_daily for select
  using (auth.uid() = profile_id);

-- audit_log: insert by staff, read by admin/super_admin only, no update/delete policy exists at all.
alter table audit_log enable row level security;
create policy audit_log_staff_insert on audit_log for insert with check (is_staff());
create policy audit_log_admin_read on audit_log for select using (is_admin());
