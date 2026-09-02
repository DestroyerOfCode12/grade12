-- MatricQuest SA — 0013: close the role-escalation gap noted in docs/THREAT_MODEL.md.
-- profiles_update_own (0011) lets a learner update their own row, which would otherwise include
-- `role`. RLS has no native column-level granularity, so we enforce it with a trigger instead:
-- a non-staff caller may not change their own role away from what it already was.

create or replace function prevent_role_self_escalation()
returns trigger language plpgsql security definer as $$
begin
  if new.role is distinct from old.role and not is_staff() then
    raise exception 'profiles: role cannot be changed by the account holder';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_prevent_role_self_escalation on profiles;
create trigger trg_prevent_role_self_escalation before update on profiles
  for each row execute function prevent_role_self_escalation();

-- Role changes by staff must go through this function so every change lands in audit_log
-- (section 14). The admin dashboard should call this via RPC rather than updating profiles
-- directly, even though staff technically can (the UPDATE policy still allows it) — this keeps
-- one auditable code path instead of two.
create or replace function admin_set_user_role(p_target_profile_id uuid, p_new_role app_role)
returns profiles language plpgsql security definer as $$
declare
  v_row profiles;
begin
  if not is_admin() then
    raise exception 'admin_set_user_role: caller is not an admin';
  end if;

  update profiles set role = p_new_role where id = p_target_profile_id returning * into v_row;

  insert into audit_log (actor_id, actor_role, action, entity_type, entity_id, metadata)
  values (auth.uid(), current_profile_role(), 'admin.role_change', 'profile', p_target_profile_id,
          jsonb_build_object('new_role', p_new_role));

  return v_row;
end;
$$;

revoke all on function admin_set_user_role(uuid, app_role) from public;
grant execute on function admin_set_user_role(uuid, app_role) to authenticated;
