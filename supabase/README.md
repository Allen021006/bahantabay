# Phase 8 database setup

Status: SQL prepared and reviewed locally; **not applied to Supabase and not database-tested here**. No configured Supabase CLI or local PostgreSQL executable was found. Flutter still uses local/demo route and report data.

## Apply once

1. Open the intended project in Supabase Dashboard. Confirm its project name.
2. Open **SQL Editor → New query**. Run this preflight:

   ```sql
   select to_regclass('public.routes') as routes,
          to_regclass('public.flood_reports') as flood_reports;
   ```

   Both results must be null. If either table exists, stop and compare its schema before applying anything. Do not drop it or bypass the check.
3. Open `supabase/migrations/20260915000000_initial_schema.sql` locally. Copy its entire contents into a new SQL Editor query, including `begin` and `commit`, and click **Run** using the Dashboard's default database role. No keys or database password need to be pasted anywhere.
4. The migration is transactional and intended to run once. An existing table causes an error rather than silently skipping differences. If an error occurs, run `rollback;` if the Editor reports an aborted transaction, inspect the error, and do not mark deployment complete.
5. Run the inspection queries below. Then create two fictional test accounts through the existing app Sign Up flow if needed and run the **entire** `supabase/tests/phase_8_rls.sql` file in a new SQL Editor query. It selects two existing non-anonymous Auth account IDs internally and exercises only newly generated fixture rows. It does not modify Auth accounts. Prefer a development Supabase project for this check.
6. Expect a final `PASS` result and no SQL errors. The script explicitly switches database roles to test RLS, then rolls back every fixture and temporary function. Running ordinary queries as the Dashboard's default role alone does not test RLS. If the script fails, run `rollback;` if needed and investigate before Phase 9.
7. Record the actual application/test date in `docs/06-security-and-privacy.md` only after these steps pass. If later adopting CLI migrations, reconcile this manually applied migration with migration history before using `db push`.

## Inspect the applied schema

```sql
-- Expect both relrowsecurity values to be true.
select c.relname, c.relrowsecurity
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname in ('routes', 'flood_reports');

-- Expect four owner policies for routes, public SELECT and owner INSERT for reports.
select tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and tablename in ('routes', 'flood_reports')
order by tablename, policyname;

-- Inspect both table-level and column-level client privileges.
select table_name, grantee, privilege_type
from information_schema.table_privileges
where table_schema = 'public' and table_name in ('routes', 'flood_reports')
  and grantee in ('anon', 'authenticated')
order by table_name, grantee, privilege_type;
select table_name, column_name, grantee, privilege_type
from information_schema.column_privileges
where table_schema = 'public' and table_name in ('routes', 'flood_reports')
  and grantee in ('anon', 'authenticated')
order by table_name, column_name, grantee, privilege_type;

select conrelid::regclass as table_name, conname, pg_get_constraintdef(oid)
from pg_constraint
where conrelid in ('public.routes'::regclass, 'public.flood_reports'::regclass);
select tablename, indexname, indexdef from pg_indexes
where schemaname = 'public' and tablename in ('routes', 'flood_reports');
```

## Schema and integration decisions

- `routes`: UUID `id`, required `user_id` referencing `auth.users`, nonblank `name`, four required coordinate columns, and database-generated `created_at` (`timestamptz`). Endpoints must differ. Owners can read, create, edit route content, and delete their own routes. Guests have no route access.
- `flood_reports`: UUID `id`, required `reporter_id` referencing `auth.users`, coordinates, `flood_depth`, `road_status`, nullable `notes`, and database-generated `created_at`. Both `anon` and `authenticated` can read all reports. Only authenticated users can insert with their own reporter ID. No client UPDATE or DELETE grant/policy exists, including for the reporter; corrections/removal require a separately authorized administrative workflow outside this phase.
- Deleting an Auth account cascades to its routes and reports. This avoids retaining account-linked data or blocking account removal; it also removes that user's community observations.
- Public report reads include the reporter UUID and notes. Do not put private information in notes. No email/name profile join is exposed.
- Latitude range is -90..90 and longitude range is -180..180. PostgreSQL range checks also reject nonfinite float values. Ownership/date indexes support private route lists, report ownership lookups, and recent report reads.
- Client inserts omit `id` and `created_at` (column grants prevent overriding them). Ownership defaults to `auth.uid()`; explicit ownership is also checked by RLS. Route updates may change only the name and four coordinates, not identity, ownership, or creation time. No `updated_at` is needed yet.
- Depth codes are `ankle`, `knee`, `waist`, `chest`; map these to labels such as `Knee-deep` later. The repo already demonstrates ankle/knee; it does not enumerate the full chooser, so waist/chest are explicit schema choices to confirm before Report Flood integration. Road codes are `passable` / `not_passable` (map the latter to Flutter's `RoadStatus.notPassable`). SAFE/WARNING/NOT PASSABLE describe derived **route status**, not a stored report severity.
- Guest entry is local, unauthenticated app state using the `anon` database role. Supabase anonymous sign-in is a different feature using `authenticated`; it is not used by this app and should remain disabled. Guest flood reporting is not approved.
- The proposal's optional `profiles` table is deferred: no current feature needs it, and ownership can reference `auth.users` directly. No storage, photo columns, spatial extension, routing service, or frontend persistence is added.

The policies and column grants follow [Supabase RLS documentation](https://supabase.com/docs/guides/database/postgres/row-level-security). RLS tests here are supplied for manual execution, not claimed to have passed locally.
