# Security and privacy

This repository is public. This document records the current security and privacy practices used by Bahantabay and will be updated as the backend and deployment are completed.

**Last checked:** 2026-09-15 (Phase 9 client integration; Phase 8 deployment and RLS verification confirmed by project owner)

## What this app stores

| Data | Where it lives | Who can see it |
| --- | --- | --- |
| User authentication account and session | Supabase Authentication | The authenticated user; authentication is managed by Supabase |
| Saved routes | Supabase PostgreSQL; Phase 9 client fetch/insert implemented | Authenticated owner, enforced by RLS |
| Route start and destination coordinates | Supabase PostgreSQL | Same owner-only access as the saved route |
| Community flood reports | Schema deployed; Flutter report persistence not yet implemented | Database allows public reads and authenticated owner inserts |
| Flood location coordinates | Schema deployed; Flutter still shows demo markers | Publicly readable with the associated report once submitted |
| Flood depth, road status, optional notes, and report time | Schema deployed; Flutter report persistence not yet implemented | Publicly readable with the associated report |
| Guest demo routes and demo flood reports | Application source code | Anyone viewing the repository or app; fictional/sample data |

Flood-report photos are a stretch goal and are **not currently stored**. If implemented later, they will require a separate privacy and Supabase Storage access review before being enabled.

Bahantabay does not require real names, student numbers, university credentials, private messages, or similar personal information as part of its normal flood-monitoring workflow.

## Secrets

- Values my app needs at run time:
  - `SUPABASE_URL`
  - `SUPABASE_PUBLISHABLE_KEY`
- Where they live locally: `.env`, which is git-ignored.
- `.env.example` is committed with placeholder values only.
- Where the deploy workflow gets them: repository secrets under **Settings > Secrets and variables > Actions**. The GitHub Actions workflow will pass the required values into the Flutter web build.
- Anything my deployed web build carries that a visitor could read, and why that is acceptable: the Supabase URL and publishable client key will be present in the deployed web application because a browser client needs them to communicate with Supabase. These values are client configuration rather than a `service_role` secret. Database access must therefore be protected by Supabase Row Level Security rather than by attempting to hide the client key.

No Supabase `service_role` key, database password, service-account file, or other privileged backend credential should be stored in the Flutter application or committed to this repository.

## What protects the data on the service side

Bahantabay uses **Supabase Authentication** for user authentication.

Supabase Row Level Security is defined in the Phase 8 migration for saved routes and community flood reports. The project owner confirms the migration was applied and RLS verification passed before Phase 9.

**Current status as of 2026-09-15:** Flutter Add Route now inserts into `routes` through the existing Supabase client, and signed-in Home fetches that user's saved routes. Tests use injected fake services and do not prove a live end-to-end save. No database changes were needed for Phase 9. Flood reports remain demo data; Route Details and route-status calculation remain unfinished.

The deployed migration defines the following access model:

### Saved routes

- A signed-in user can create a route associated with their own authenticated user ID.
- A user can read their own saved routes.
- A user cannot create a saved route on behalf of another user.
- A user cannot modify or delete another user's saved routes.
- Guest users cannot create or modify saved routes.
- The route service checks the active session ID, filters reads by owner ID, and supplies that same ID on inserts for RLS validation. IDs and creation timestamps are left to database defaults.
- Switching accounts/signing out discards the old Home state and open Add Route draft. Old asynchronous results cannot populate a new account's route list.
- Guest Home keeps read-only demo routes and does not fetch private routes. Real saved routes display “Status not assessed”; demo reports/markers are explicitly labelled.

### Community flood reports

- Flood reports are intended to be readable by signed-in users and guests so that community flood information remains useful without requiring an account.
- Only authenticated users can create flood reports.
- A submitted report must be associated with the authenticated user's ID rather than allowing the client to impersonate another user.
- Flood reports are append-only for clients: neither `anon` nor `authenticated` has UPDATE or DELETE permissions, even for their own reports.
- Public reads include reporter UUIDs and notes, but no Auth email or other profile information. Notes must not contain private information.
- The app's guest flow uses `anon`, not Supabase anonymous sign-in; guests cannot submit reports. Supabase anonymous sign-in is not used and should remain disabled.

Both tables use required Auth ownership foreign keys with `ON DELETE CASCADE`: deleting an Auth account removes its routes and reports. Client writes cannot override database-generated IDs/timestamps or transfer route ownership. No optional `profiles` table is needed for current functionality.

See [database setup and verification](../supabase/README.md) for the Phase 8 setup instructions, grants, constraints, and rollback-only role tests in `supabase/tests/phase_8_rls.sql`. Its original preparation status predates the project owner's confirmation; do not rerun the initial migration on the deployed tables.

## Checklist

- [x] `.env` is in `.gitignore`.
- [x] `.env.example` exists for documenting the required environment-variable names without storing their real values.
- [x] No `service_role` key is intentionally used by the Flutter client.
- [x] Current route and flood-report demo data is fictional/sample data.
- [ ] Run and record the final repository-history secret scan: `git log -p | grep -i "api_key\|secret\|password\|token"` and verify that it finds no real secret.
- [x] Supabase table definitions and RLS policies written in the Phase 8 migration.
- [x] Migration applied to the intended Supabase project (confirmed by project owner before Phase 9).
- [x] Supabase RLS role tests run successfully against the database (confirmed by project owner before Phase 9).
- [x] Phase 9 route fetch/insert client integration and offline automated tests implemented.
- [ ] Live end-to-end Phase 9 save/reload and account-isolation smoke test recorded.
- [ ] Review all final screenshots for real personal data.
- [ ] Review the final demo video for real personal data.
- [ ] Verify that no course or university credentials appear anywhere in the public repository.
- [ ] Verify that no real person's data is used in final test/sample data without permission.
- [ ] Complete a final security and privacy review immediately before submission.

No key has been recorded here as revoked because no known exposed privileged key has been identified during the project review so far. If a credential is later found in repository history, it will be revoked immediately and this document will be updated to record what was corrected.

## Final review

This document is intentionally a living security record rather than a claim that unfinished backend work is already secure.

It must be reviewed again after:

1. the Supabase database schema is created;
2. Row Level Security policies are implemented and tested;
3. GitHub Pages deployment is configured with the required build values;
4. final screenshots are captured;
5. the demo video is recorded; and
6. the project is ready for submission.

The **Last checked** date and checklist must then be updated to reflect the final review.
