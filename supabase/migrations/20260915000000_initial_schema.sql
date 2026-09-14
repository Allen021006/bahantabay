-- Phase 8: apply once to the intended Supabase project through SQL Editor.
-- Deliberately fail if these tables already exist; do not hide schema drift.
begin;

create table public.routes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null check (name ~ '[^[:space:]]'),
  start_latitude double precision not null check (start_latitude between -90 and 90),
  start_longitude double precision not null check (start_longitude between -180 and 180),
  destination_latitude double precision not null check (destination_latitude between -90 and 90),
  destination_longitude double precision not null check (destination_longitude between -180 and 180),
  created_at timestamptz not null default now(),
  constraint routes_distinct_points check (
    start_latitude <> destination_latitude or start_longitude <> destination_longitude
  )
);

create table public.flood_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  flood_depth text not null check (flood_depth in ('ankle', 'knee', 'waist', 'chest')),
  road_status text not null check (road_status in ('passable', 'not_passable')),
  notes text,
  created_at timestamptz not null default now()
);

create index routes_user_created_idx on public.routes (user_id, created_at desc);
create index flood_reports_reporter_idx on public.flood_reports (reporter_id);
create index flood_reports_created_idx on public.flood_reports (created_at desc);

alter table public.routes enable row level security;
alter table public.flood_reports enable row level security;

-- Reset inherited/default client grants before granting only needed operations.
revoke all on public.routes, public.flood_reports from public, anon, authenticated;
grant usage on schema public to anon, authenticated;
grant select, delete on public.routes to authenticated;
grant insert (user_id, name, start_latitude, start_longitude,
  destination_latitude, destination_longitude) on public.routes to authenticated;
grant update (name, start_latitude, start_longitude,
  destination_latitude, destination_longitude) on public.routes to authenticated;

-- Reports are public community observations. They are append-only for clients.
-- Database-generated IDs/timestamps cannot be supplied or changed by clients.
grant select on public.flood_reports to anon, authenticated;
grant insert (reporter_id, latitude, longitude, flood_depth, road_status, notes)
  on public.flood_reports to authenticated;

create policy routes_select_own on public.routes
  for select to authenticated using ((select auth.uid()) = user_id);
create policy routes_insert_own on public.routes
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy routes_update_own on public.routes
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy routes_delete_own on public.routes
  for delete to authenticated using ((select auth.uid()) = user_id);

create policy flood_reports_public_read on public.flood_reports
  for select to anon, authenticated using (true);
create policy flood_reports_insert_own on public.flood_reports
  for insert to authenticated with check ((select auth.uid()) = reporter_id);

comment on table public.routes is
  'Private two-point routes. Account deletion removes owned routes.';
comment on table public.flood_reports is
  'Public observations, including reporter UUID and notes; no private information. Account deletion removes reports.';
comment on column public.flood_reports.flood_depth is
  'Depth codes: ankle, knee, waist, chest. Route SAFE/WARNING/NOT PASSABLE is derived later, not stored here.';

commit;
