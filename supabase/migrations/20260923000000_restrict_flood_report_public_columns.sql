-- Prepared privacy correction; apply after the initial schema migration.
-- Do not rerun or edit the already-applied initial migration.
begin;

-- Table-level SELECT would override a column restriction. PUBLIC applies to
-- every role; also remove any direct column grant on the internal owner ID.
revoke select on table public.flood_reports from public, anon, authenticated;
revoke select (reporter_id) on table public.flood_reports
  from public, anon, authenticated;
grant select (id, latitude, longitude, flood_depth, road_status, notes, created_at)
  on table public.flood_reports to anon, authenticated;

-- Leave INSERT grants, ownership defaults, RLS and mutation restrictions intact.
-- Check effective privileges, including inherited grants. Fail transactionally
-- on unexpected privilege drift rather than silently leaving identity exposed
-- or changing unrelated role memberships/grants.
do $$
declare client_role text; column_name text;
begin
  foreach client_role in array array['anon', 'authenticated'] loop
    if has_table_privilege(client_role, 'public.flood_reports', 'SELECT')
       or has_column_privilege(client_role, 'public.flood_reports', 'reporter_id', 'SELECT') then
      raise exception 'Unexpected effective reporter SELECT access for %; inspect inherited grants', client_role;
    end if;
    foreach column_name in array array[
      'id', 'latitude', 'longitude', 'flood_depth', 'road_status', 'notes', 'created_at'
    ] loop
      if not has_column_privilege(client_role, 'public.flood_reports', column_name, 'SELECT') then
        raise exception 'Missing public SELECT access for % on %', client_role, column_name;
      end if;
    end loop;
    if has_any_column_privilege(client_role, 'public.flood_reports', 'UPDATE')
       or has_table_privilege(client_role, 'public.flood_reports', 'DELETE') then
      raise exception 'Unexpected report mutation privileges for %', client_role;
    end if;
  end loop;
  if has_any_column_privilege('anon', 'public.flood_reports', 'INSERT') then
    raise exception 'Unexpected anonymous report INSERT privileges';
  end if;
  foreach column_name in array array[
    'reporter_id', 'latitude', 'longitude', 'flood_depth', 'road_status', 'notes'
  ] loop
    if not has_column_privilege('authenticated', 'public.flood_reports', column_name, 'INSERT') then
      raise exception 'Missing authenticated INSERT access on %', column_name;
    end if;
  end loop;
end;
$$;

comment on table public.flood_reports is
  'Public observation fields and notes; reporter_id is internal ownership data excluded from anon/authenticated SELECT. Notes must not contain personal information. Account deletion removes reports.';

commit;
