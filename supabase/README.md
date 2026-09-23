# Phase 8 database setup

Status: The project owner confirms the initial schema and RLS were applied and live-verified. The new privacy migration `20260923000000_restrict_flood_report_public_columns.sql` is **prepared, pending manual live application and verification**. It has not been run against Supabase by this task.

## Privacy correction for the existing database

1. Deploy the updated Flutter client first. It explicitly selects `id,latitude,longitude,flood_depth,road_status,notes,created_at` and no longer requires a reporter ID in the fetched model.
2. In the intended Supabase project's SQL Editor, manually run the entire `supabase/migrations/20260923000000_restrict_flood_report_public_columns.sql`, including `begin` and `commit`. Do not rerun the initial schema migration.
3. The correction removes table-level SELECT for PUBLIC, anon and authenticated, removes reporter-column SELECT grants, and grants only the seven public columns to both client roles. It preserves authenticated INSERT, ownership enforcement, RLS, and UPDATE/DELETE restrictions. Effective-privilege checks abort the transaction if inherited privileges would still expose reporter IDs or unexpected mutation grants exist. Investigate such drift rather than bypassing the checks; use `rollback;` if the Editor reports an aborted transaction.
4. Run the entire updated `supabase/tests/phase_8_rls.sql` after both migrations. It preserves rollback-only fixtures and tests public projections, denied reporter/wildcard reads, own inserts, spoofing rejection, and existing route/report restrictions.
5. Verify guest and authenticated public reads through the API and app, plus an authenticated submission and Home refresh. Requests explicitly selecting `reporter_id` or `*` must fail for both client roles. Confirm the stored owner through an authorized administrative query, not a client read.

Old cached clients using wildcard SELECT will fail after the privilege change and need refreshing. The new client is compatible with the old grants, so deploy it first. Previously disclosed reporter UUIDs cannot be retracted. Record application and live-test results only after they actually pass. Reconcile manually applied migrations with CLI migration history before any future `db push`.

## Initial setup only — fresh databases

These initial-schema steps are historical setup instructions, not instructions to rerun the initial migration on the live project. On a fresh database, apply the initial migration and then the privacy migration before running the updated verification script.

1. Open the intended project in Supabase Dashboard. Confirm its project name.
2. Open **SQL Editor → New query**. Run this preflight:

   ```sql
   select to_regclass('public.routes') as routes,
          to_regclass('public.flood_reports') as flood_reports;
   ```

   Both results must be null. If either table exists, stop and compare its schema before applying anything. Do not drop it or bypass the check.
3. Open `supabase/migrations/20260915000000_initial_schema.sql` locally. Copy its entire contents into a new SQL Editor query, including `begin` and `commit`, and click **Run** using the Dashboard's default database role. No keys or database password need to be pasted anywhere.
4. The migration is transactional and intended to run once. An existing table causes an error rather than silently skipping differences. If an error occurs, run `rollback;` if the Editor reports an aborted transaction, inspect the error, and do not mark deployment complete.
5. Apply the privacy migration using the section above before running verification. Run the inspection queries below. Then create two fictional test accounts through the existing app Sign Up flow if needed and run the **entire** `supabase/tests/phase_8_rls.sql` file in a new SQL Editor query. It selects two existing non-anonymous Auth account IDs internally and exercises only newly generated fixture rows. It does not modify Auth accounts. Prefer a development Supabase project for this check.
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
- The hardened client SELECT projection includes only `id`, `latitude`, `longitude`, `flood_depth`, `road_status`, `notes`, and `created_at`. `reporter_id` remains stored internally for ownership and authenticated inserts, but is excluded from client reads. Database enforcement for both anon and authenticated is pending application of the new privacy migration; the original grants still expose it until then. Notes remain public and must not contain private/personal information. No email/name profile join is exposed.
- Latitude range is -90..90 and longitude range is -180..180. PostgreSQL range checks also reject nonfinite float values. Ownership/date indexes support private route lists, report ownership lookups, and recent report reads.
- Client inserts omit `id` and `created_at` (column grants prevent overriding them). Ownership defaults to `auth.uid()`; explicit ownership is also checked by RLS. Route updates may change only the name and four coordinates, not identity, ownership, or creation time. No `updated_at` is needed yet.
- Depth codes are `ankle`, `knee`, `waist`, `chest`; map these to labels such as `Knee-deep` later. The repo already demonstrates ankle/knee; it does not enumerate the full chooser, so waist/chest are explicit schema choices to confirm before Report Flood integration. Road codes are `passable` / `not_passable` (map the latter to Flutter's `RoadStatus.notPassable`). SAFE/WARNING/NOT PASSABLE describe derived **route status**, not a stored report severity.
- Guest entry is local, unauthenticated app state using the `anon` database role. Supabase anonymous sign-in is a different feature using `authenticated`; it is not used by this app and should remain disabled. Guest flood reporting is not approved.
- The proposal's optional `profiles` table is deferred: no current feature needs it, and ownership can reference `auth.users` directly. No storage, photo columns, spatial extension, routing service, or frontend persistence is added.

The policies and column grants follow [Supabase RLS documentation](https://supabase.com/docs/guides/database/postgres/row-level-security). RLS tests here are supplied for manual execution, not claimed to have passed locally.
