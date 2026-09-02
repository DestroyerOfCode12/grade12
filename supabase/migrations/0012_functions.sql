-- MatricQuest SA — 0012: idempotent RPC functions
-- Both functions are SECURITY DEFINER so RLS on xp_events/streaks doesn't need a client-writable
-- insert policy; the mobile app calls these via supabase.rpc(...), never inserts xp_events directly.

create or replace function grant_xp(
  p_profile_id uuid,
  p_amount int,
  p_reason text,
  p_source_entity_type text,
  p_source_entity_id uuid,
  p_idempotency_key text
) returns table (granted boolean, total_xp bigint) language plpgsql security definer as $$
declare
  v_existing_id uuid;
begin
  if p_profile_id <> auth.uid() then
    raise exception 'grant_xp: profile mismatch';
  end if;

  select id into v_existing_id from xp_events
    where profile_id = p_profile_id and idempotency_key = p_idempotency_key;

  if v_existing_id is null then
    insert into xp_events (profile_id, amount, reason, source_entity_type, source_entity_id, idempotency_key)
    values (p_profile_id, p_amount, p_reason, p_source_entity_type, p_source_entity_id, p_idempotency_key);
  end if;

  return query
    select (v_existing_id is null),
           coalesce((select sum(amount) from xp_events where profile_id = p_profile_id), 0);
end;
$$;

revoke all on function grant_xp(uuid, int, text, text, uuid, text) from public;
grant execute on function grant_xp(uuid, int, text, text, uuid, text) to authenticated;

-- Records a streak "check-in" for today (in the learner's own timezone), idempotently.
-- Safe to call multiple times per day: only the first call in a new local day advances the streak.
create or replace function record_daily_activity(p_profile_id uuid)
returns table (current_streak_days int, longest_streak_days int) language plpgsql security definer as $$
declare
  v_tz text;
  v_today date;
  v_row streaks;
begin
  if p_profile_id <> auth.uid() then
    raise exception 'record_daily_activity: profile mismatch';
  end if;

  select timezone into v_tz from profiles where id = p_profile_id;
  v_tz := coalesce(v_tz, 'Africa/Johannesburg');
  v_today := (now() at time zone v_tz)::date;

  insert into streaks (profile_id, current_streak_days, longest_streak_days, last_active_local_date, timezone)
  values (p_profile_id, 1, 1, v_today, v_tz)
  on conflict (profile_id) do nothing;

  select * into v_row from streaks where profile_id = p_profile_id;

  if v_row.last_active_local_date is null or v_row.last_active_local_date < v_today then
    if v_row.last_active_local_date = v_today - interval '1 day' then
      update streaks set current_streak_days = current_streak_days + 1,
                          longest_streak_days = greatest(longest_streak_days, current_streak_days + 1),
                          last_active_local_date = v_today, timezone = v_tz
        where profile_id = p_profile_id;
    elsif v_row.last_active_local_date is distinct from v_today then
      -- gap of 1+ days: streak lapsed unless a freeze token covers exactly one missed day.
      if v_row.last_active_local_date = v_today - interval '2 days' and v_row.freeze_tokens > 0 then
        update streaks set current_streak_days = current_streak_days + 1,
                            longest_streak_days = greatest(longest_streak_days, current_streak_days + 1),
                            last_active_local_date = v_today, timezone = v_tz,
                            freeze_tokens = freeze_tokens - 1
          where profile_id = p_profile_id;
      else
        update streaks set current_streak_days = 1, last_active_local_date = v_today, timezone = v_tz
          where profile_id = p_profile_id;
      end if;
    end if;
  end if;

  return query select s.current_streak_days, s.longest_streak_days from streaks s where s.profile_id = p_profile_id;
end;
$$;

revoke all on function record_daily_activity(uuid) from public;
grant execute on function record_daily_activity(uuid) to authenticated;

-- Idempotent attempt submission: safe to retry on flaky mobile connections.
create or replace function submit_attempt(
  p_attempt_id uuid,
  p_marks_earned numeric,
  p_marks_available numeric
) returns attempts language plpgsql security definer as $$
declare
  v_row attempts;
begin
  select * into v_row from attempts where id = p_attempt_id;
  if v_row.profile_id is distinct from auth.uid() then
    raise exception 'submit_attempt: not the owner';
  end if;

  if v_row.submitted_at is null then
    update attempts set submitted_at = now(), marks_earned = p_marks_earned,
                         marks_available = p_marks_available, synced_at = now()
      where id = p_attempt_id
      returning * into v_row;
  end if;

  return v_row;
end;
$$;

revoke all on function submit_attempt(uuid, numeric, numeric) from public;
grant execute on function submit_attempt(uuid, numeric, numeric) to authenticated;
