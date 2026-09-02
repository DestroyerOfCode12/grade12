-- MatricQuest SA — pgTAP tests for Row Level Security and idempotency (section 16, item 9 and
-- section 13). Run with the Supabase CLI: `supabase test db` (requires the pgTAP extension,
-- enabled automatically by that command against a local `supabase start` stack).
--
-- These tests are written but NOT executed in this environment (no local Postgres/Supabase CLI
-- available here — see docs/CONTINUATION.md). Run them as part of setting up local Supabase dev
-- per docs/SETUP.md before trusting production RLS policies.

begin;
select plan(8);

create extension if not exists pgtap;

-- Fixture: two learners, one admin.
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'learner-a@example.com'),
  ('22222222-2222-2222-2222-222222222222', 'learner-b@example.com'),
  ('33333333-3333-3333-3333-333333333333', 'admin@example.com');

insert into profiles (id, nickname, role) values
  ('11111111-1111-1111-1111-111111111111', 'LearnerA1', 'learner'),
  ('22222222-2222-2222-2222-222222222222', 'LearnerB1', 'learner'),
  ('33333333-3333-3333-3333-333333333333', 'AdminOne', 'admin');

-- Test 1: an unauthenticated (anon) request cannot read another learner's mastery_scores.
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
insert into subjects (id, code, name, category, content_status) values
  ('99999999-9999-9999-9999-999999999999', 'test_subject', 'Test Subject', 'Test', 'published');
insert into topics (id, subject_id, title) values
  ('88888888-8888-8888-8888-888888888888', '99999999-9999-9999-9999-999999999999', 'Test Topic');
insert into mastery_scores (profile_id, topic_id, mastery_estimate) values
  ('22222222-2222-2222-2222-222222222222', '88888888-8888-8888-8888-888888888888', 70);

select is(
  (select count(*) from mastery_scores where profile_id = '22222222-2222-2222-2222-222222222222'),
  0::bigint,
  'Learner A cannot see Learner B''s mastery_scores row under RLS'
);

-- Test 2: Learner A CAN see their own mastery_scores row.
insert into mastery_scores (profile_id, topic_id, mastery_estimate) values
  ('11111111-1111-1111-1111-111111111111', '88888888-8888-8888-8888-888888888888', 55);

select is(
  (select count(*) from mastery_scores where profile_id = '11111111-1111-1111-1111-111111111111'),
  1::bigint,
  'Learner A can see their own mastery_scores row'
);

-- Test 3: a draft lesson is invisible to a learner (non-staff).
insert into lessons (id, topic_id, title, content_status) values
  ('77777777-7777-7777-7777-777777777777', '88888888-8888-8888-8888-888888888888', 'Draft Lesson', 'draft');

select is(
  (select count(*) from lessons where id = '77777777-7777-7777-7777-777777777777'),
  0::bigint,
  'A draft lesson is not visible to a learner'
);

-- Test 4: switching to the admin role makes the draft lesson visible.
select set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', true);
select is(
  (select count(*) from lessons where id = '77777777-7777-7777-7777-777777777777'),
  1::bigint,
  'A draft lesson IS visible to an admin'
);

-- Test 5: a learner cannot escalate their own role via a direct UPDATE (0013 trigger).
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select throws_ok(
  $$ update profiles set role = 'admin' where id = '11111111-1111-1111-1111-111111111111' $$,
  'P0001',
  'profiles: role cannot be changed by the account holder',
  'A learner cannot self-escalate their role'
);

-- Test 6: grant_xp is idempotent — calling twice with the same idempotency_key only inserts once.
select grant_xp('11111111-1111-1111-1111-111111111111', 15, 'lesson_completed', 'lesson', '77777777-7777-7777-7777-777777777777', 'test-key-001');
select grant_xp('11111111-1111-1111-1111-111111111111', 15, 'lesson_completed', 'lesson', '77777777-7777-7777-7777-777777777777', 'test-key-001');

select is(
  (select count(*) from xp_events where idempotency_key = 'test-key-001'),
  1::bigint,
  'grant_xp with a repeated idempotency_key inserts exactly one xp_events row'
);

-- Test 7: total XP reflects only the single grant, not a double-count.
select is(
  (select coalesce(sum(amount), 0) from xp_events where profile_id = '11111111-1111-1111-1111-111111111111'),
  15::bigint,
  'Total XP is not double-counted after a retried grant_xp call'
);

-- Test 8: a leaderboard row for a non-opted-in learner is not readable by another learner.
insert into leaderboard_entries (profile_id, scope, xp_total, period_start, period_end) values
  ('22222222-2222-2222-2222-222222222222', 'weekly', 100, current_date, current_date + 6);

select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
select is(
  (select count(*) from leaderboard_entries where profile_id = '22222222-2222-2222-2222-222222222222'),
  0::bigint,
  'A non-opted-in learner''s leaderboard row is not visible to another learner'
);

select * from finish();
rollback;
