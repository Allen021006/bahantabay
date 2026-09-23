-- Run the entire file in Supabase SQL Editor AFTER applying both migrations.
-- Requires two existing non-anonymous test accounts (create through app Sign Up).
-- Uses their UUIDs internally, never prints them or changes auth.users.
-- All fixture data and temporary functions are rolled back.
begin;

create function pg_temp.assert_true(ok boolean, message text) returns void
language plpgsql as $$
begin
  if ok is distinct from true then raise exception 'FAIL: %', message; end if;
end;
$$;

create function pg_temp.expect_error(statement text, expected_state text)
returns void language plpgsql as $$
begin
  begin
    execute statement;
  exception when others then
    if sqlstate = expected_state then return; end if;
    raise;
  end;
  raise exception 'FAIL: expected SQLSTATE %', expected_state;
end;
$$;

do $$
declare users uuid[];
begin
  select array_agg(id) into users from (
    select id from auth.users where is_anonymous is false order by id limit 2
  ) candidates;
  if coalesce(array_length(users, 1), 0) < 2 then
    raise exception 'Create two test accounts through Sign Up before running this verification.';
  end if;
  perform set_config('test.user_a', users[1]::text, true);
  perform set_config('test.user_b', users[2]::text, true);
end;
$$;

select pg_temp.assert_true(
  (select count(*) = 2 from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relname in ('routes', 'flood_reports')
   and c.relrowsecurity), 'RLS enabled on both tables');

set local role authenticated;
do $$
begin
  perform set_config('request.jwt.claim.sub', current_setting('test.user_a'), true);
  perform set_config('request.jwt.claims', json_build_object(
    'sub', current_setting('test.user_a'), 'role', 'authenticated',
    'is_anonymous', false)::text, true);
end;
$$;

-- User A can insert their own route/report; defaults supply ownership and time.
-- Match the Flutter payload too: explicit own reporter_id needs INSERT, not SELECT.
insert into public.flood_reports
  (reporter_id, latitude, longitude, flood_depth, road_status, notes)
values (auth.uid(), 15.14, 120.58, 'ankle', 'passable', 'Privacy verification');
do $$
declare route_id uuid; report_id uuid;
begin
  insert into public.routes (name, start_latitude, start_longitude,
    destination_latitude, destination_longitude)
  values ('Phase 8 verification', 15.14, 120.58, 15.15, 120.59)
  returning id into route_id;
  insert into public.flood_reports (latitude, longitude, flood_depth, road_status)
  values (15.14, 120.58, 'knee', 'not_passable')
  returning id into report_id;
  perform set_config('test.route', route_id::text, true);
  perform set_config('test.report', report_id::text, true);
end;
$$;
select pg_temp.assert_true(
  (select count(*) = 1 from public.routes where id = current_setting('test.route')::uuid
    and user_id = auth.uid() and created_at is not null), 'owner SELECT and defaults');
update public.routes set name = 'Updated draft' where id = current_setting('test.route')::uuid;
select pg_temp.assert_true(
  (select name = 'Updated draft' from public.routes where id = current_setting('test.route')::uuid),
  'owner UPDATE');

select pg_temp.expect_error(
  format('insert into public.routes (user_id,name,start_latitude,start_longitude,destination_latitude,destination_longitude)
    values (%L, ''Spoof'',15,120,16,121)', current_setting('test.user_b')), '42501');
select pg_temp.expect_error(
  format('insert into public.flood_reports (reporter_id,latitude,longitude,flood_depth,road_status)
    values (%L,15,120,''knee'',''passable'')', current_setting('test.user_b')), '42501');
select pg_temp.expect_error(
  format('update public.routes set user_id = %L where id = %L',
    current_setting('test.user_b'), current_setting('test.route')), '42501');
select pg_temp.expect_error(
  'insert into public.routes (name,start_latitude,start_longitude,destination_latitude,destination_longitude)
    values (''   '',15,120,16,121)', '23514');
select pg_temp.expect_error(
  'insert into public.routes (name,start_latitude,start_longitude,destination_latitude,destination_longitude)
    values (''Invalid'',91,120,16,121)', '23514');
select pg_temp.expect_error(
  'insert into public.routes (name,start_latitude,start_longitude,destination_latitude,destination_longitude)
    values (''Same point'',15,120,15,120)', '23514');
select pg_temp.expect_error(
  'insert into public.flood_reports (latitude,longitude,flood_depth,road_status)
    values (15,181,''knee'',''passable'')', '23514');
select pg_temp.expect_error(
  'insert into public.flood_reports (latitude,longitude,flood_depth,road_status)
    values (15,120,''unknown'',''passable'')', '23514');
select pg_temp.expect_error(
  'insert into public.flood_reports (latitude,longitude,flood_depth,road_status)
    values (15,120,''knee'',''SAFE'')', '23514');
select pg_temp.expect_error(
  'insert into public.flood_reports (latitude,longitude,flood_depth,road_status,created_at)
    values (15,120,''knee'',''passable'',now())', '42501');

-- User B sees public reports, but cannot see or mutate A's route.
do $$
begin
  perform set_config('request.jwt.claim.sub', current_setting('test.user_b'), true);
  perform set_config('request.jwt.claims', json_build_object(
    'sub', current_setting('test.user_b'), 'role', 'authenticated',
    'is_anonymous', false)::text, true);
end;
$$;
select pg_temp.assert_true(
  (select count(*) = 0 from public.routes where id = current_setting('test.route')::uuid),
  'other user cannot SELECT private route');
do $$
declare affected integer;
begin
  update public.routes set name = 'Forbidden' where id = current_setting('test.route')::uuid;
  get diagnostics affected = row_count;
  perform pg_temp.assert_true(affected = 0, 'other user UPDATE affects no rows');
  delete from public.routes where id = current_setting('test.route')::uuid;
  get diagnostics affected = row_count;
  perform pg_temp.assert_true(affected = 0, 'other user DELETE affects no rows');
end;
$$;
select pg_temp.assert_true(
  (select count(*) = 1 from public.flood_reports where id = current_setting('test.report')::uuid),
  'authenticated community read');
do $$
declare report record;
begin
  select id, latitude, longitude, flood_depth, road_status, notes, created_at
    into strict report from public.flood_reports
    where id = current_setting('test.report')::uuid;
  perform pg_temp.assert_true(report.flood_depth = 'knee' and report.created_at is not null,
    'authenticated public projection');
end;
$$;
select pg_temp.assert_true(
  not has_column_privilege(current_user, 'public.flood_reports', 'reporter_id', 'SELECT'),
  'authenticated has no effective reporter SELECT privilege');
select pg_temp.expect_error('select reporter_id from public.flood_reports', '42501');
select pg_temp.expect_error('select * from public.flood_reports', '42501');
select pg_temp.expect_error(
  format('update public.flood_reports set notes = ''Forbidden'' where id = %L',
    current_setting('test.report')), '42501');
select pg_temp.expect_error(
  format('delete from public.flood_reports where id = %L', current_setting('test.report')), '42501');

reset role;
set local role anon;
do $$
begin
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
end;
$$;
select pg_temp.assert_true(auth.uid() is null, 'guest has no authenticated identity');
select pg_temp.assert_true(
  (select count(*) = 1 from public.flood_reports where id = current_setting('test.report')::uuid),
  'guest community read');
do $$
declare report record;
begin
  select id, latitude, longitude, flood_depth, road_status, notes, created_at
    into strict report from public.flood_reports
    where id = current_setting('test.report')::uuid;
  perform pg_temp.assert_true(report.flood_depth = 'knee' and report.created_at is not null,
    'guest public projection');
end;
$$;
select pg_temp.assert_true(
  not has_column_privilege(current_user, 'public.flood_reports', 'reporter_id', 'SELECT'),
  'guest has no effective reporter SELECT privilege');
select pg_temp.expect_error('select reporter_id from public.flood_reports', '42501');
select pg_temp.expect_error('select * from public.flood_reports', '42501');
select pg_temp.expect_error('select * from public.routes', '42501');
select pg_temp.expect_error(
  'insert into public.routes (name,start_latitude,start_longitude,destination_latitude,destination_longitude)
    values (''Guest'',15,120,16,121)', '42501');
select pg_temp.expect_error(
  format('update public.routes set name = ''Guest'' where id = %L', current_setting('test.route')), '42501');
select pg_temp.expect_error(
  format('delete from public.routes where id = %L', current_setting('test.route')), '42501');
select pg_temp.expect_error(
  'insert into public.flood_reports (latitude,longitude,flood_depth,road_status)
    values (15,120,''knee'',''passable'')', '42501');
select pg_temp.expect_error(
  format('update public.flood_reports set notes = ''Guest'' where id = %L', current_setting('test.report')), '42501');
select pg_temp.expect_error(
  format('delete from public.flood_reports where id = %L', current_setting('test.report')), '42501');

reset role;
set local role authenticated;
do $$
declare affected integer;
begin
  perform set_config('request.jwt.claim.sub', current_setting('test.user_a'), true);
  perform set_config('request.jwt.claims', json_build_object(
    'sub', current_setting('test.user_a'), 'role', 'authenticated',
    'is_anonymous', false)::text, true);
  delete from public.routes where id = current_setting('test.route')::uuid;
  get diagnostics affected = row_count;
  perform pg_temp.assert_true(affected = 1, 'owner DELETE');
end;
$$;
-- Even the reporter cannot edit/delete observations through the client.
select pg_temp.expect_error(
  format('update public.flood_reports set notes = ''Edit'' where id = %L', current_setting('test.report')), '42501');
select pg_temp.expect_error(
  format('delete from public.flood_reports where id = %L', current_setting('test.report')), '42501');
reset role;
rollback;
select 'PASS: ownership, guest access, public reads, mutation restrictions and constraints; fixtures rolled back.' as result;
