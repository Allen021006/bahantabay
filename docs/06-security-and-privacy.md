# Security and privacy

This repository is public. This document records the current security and privacy practices used by Bahantabay and will be updated as the backend and deployment are completed.

**Documentation reviewed:** 2026-09-30. Live verification below is based on the project owner's recorded checks, not a new backend audit performed during this documentation update.

**Privacy correction applied and verified by the project owner:** The client selects only public report fields and does not store fetched reporter IDs. The owner manually applied `supabase/migrations/20260923000000_restrict_flood_report_public_columns.sql`, inspected effective privileges, and verified public reads and authenticated submission afterward. Both client roles are restricted from selecting reporter IDs. The earlier dated status below is retained as a historical snapshot.

## What this app stores

| Data | Where it lives | Who can see it |
| --- | --- | --- |
| User authentication account and session | Supabase Authentication | The authenticated user; authentication is managed by Supabase |
| Saved routes | Supabase PostgreSQL; client fetch/insert/update/delete implemented | Authenticated owner, enforced by RLS |
| Route start and destination coordinates | Supabase PostgreSQL | Same owner-only access as the saved route |
| Community flood reports | Supabase PostgreSQL; Phase 10 client fetch/insert implemented | Public reads and authenticated owner inserts, enforced by RLS |
| Flood location coordinates | Supabase PostgreSQL; shown in Home entries and map markers | Publicly readable with the associated report |
| Flood depth, road status, optional notes, and report time | Supabase PostgreSQL; shown through FloodReportEntry | Publicly readable with the associated report |
| Guest demo routes | Application source code, labelled as demo | Anyone viewing the repository or app; fictional/sample data |

Flood-report photos are a stretch goal and are **not currently stored**. If implemented later, they will require a separate privacy and Supabase Storage access review before being enabled.

Bahantabay does not require real names, student numbers, university credentials, private messages, or similar personal information as part of its normal flood-monitoring workflow.

## Secrets

- Values supplied at build time:
  - `SUPABASE_URL`
  - `SUPABASE_PUBLISHABLE_KEY`
- Where they live locally: `.env`, which is git-ignored.
- `.env.example` is committed with placeholder values only.
- Where the deploy workflow gets them: repository secrets under **Settings > Secrets and variables > Actions**. The workflow passes compile-time `--dart-define` values into the Flutter web build and rejects either missing/empty value before compilation without printing it. Local runs use `--dart-define-from-file=.env`; Flutter does not load `.env` dynamically.
- Anything my deployed web build carries that a visitor could read, and why that is acceptable: the Supabase URL and publishable client key are present in the deployed web application because a browser client needs them to communicate with Supabase. These values are client configuration rather than a `service_role` secret. Database access must therefore be protected by Supabase Row Level Security rather than by attempting to hide the client key.

No Supabase `service_role` key, database password, service-account file, or other privileged backend credential should be stored in the Flutter application or committed to this repository.

## What protects the data on the service side

Bahantabay uses **Supabase Authentication** for user authentication.

Supabase Row Level Security is defined in the Phase 8 migration for saved routes and community flood reports. The project owner confirms the migration was applied and RLS verification passed before Phase 9.

**Historical snapshot (2026-09-17):** The project owner has manually verified Phase 9 against real Supabase: route creation, immediate Home refresh, persistence across browser refresh, map coordinates, session restoration, account switching, owner isolation between two accounts, and guest restrictions all passed. Phase 10 adds authenticated flood-report inserts and public reads through the same client. Its automated tests use injected fakes and a loopback HTTP backend; live Phase 10 submission is not yet manually verified. No schema changes were needed. Route Details and route-status calculation remain unfinished.

**Current status (owner confirmation, 2026-09-30):** The project owner confirmed the deployment and live application checks on GitHub Pages for `f02925f`, including authentication, Guest access, saved-route selection, editing/deletion and flood reporting. The owner then ran the complete updated rollback-only SQL verification and received its final PASS result. Direct REST checks confirmed that Guest and authenticated clients can request the seven public report columns but cannot request `reporter_id` or `*`. No migration was rerun and no secret/service-role key was used. Later local application and build changes still require deployment verification.

The applied migrations define the following access model:

### Saved routes

- A signed-in user can create a route associated with their own authenticated user ID.
- A user can read their own saved routes.
- The edit/delete flow (`9c837fd`) reuses existing owner-only RLS and column grants. Updates change only the name and four endpoint coordinates. Both update/delete requests filter by route ID and owner ID, check the active session before and after the request, and require one returned ID to confirm success. Raw backend errors are not shown.
- Deletion requires confirmation. Pending mutations disable submission actions; failures keep the editor open. Successful changes return to Home and reload routes for reassessment. Guests have no edit/delete flow.
- A user cannot create a saved route on behalf of another user.
- A user cannot modify or delete another user's saved routes.
- Guest users cannot create or modify saved routes.
- The route service checks the active session ID, filters reads by owner ID, and supplies that same ID on inserts for RLS validation. IDs and creation timestamps are left to database defaults.
- Switching accounts/signing out discards the old Home state and open Add Route/Edit route draft. Old asynchronous results cannot populate a new account's route list.
- Guest Home keeps read-only demo routes and does not fetch private routes. Real saved routes are assessed from successfully loaded reports within 200 meters of the bounded straight-line route: passable means WARNING, not passable means NOT PASSABLE (highest severity), and no relevant severity-raising report means SAFE. Loading/error remains “Status not assessed”. SAFE is not a guarantee of real-world safety. Route Details receives Home's assessment snapshot; no status is stored in the database.

### Community flood reports

- Flood reports are intended to be readable by signed-in users and guests so that community flood information remains useful without requiring an account.
- Only authenticated users can create flood reports.
- A submitted report must be associated with the authenticated user's ID rather than allowing the client to impersonate another user.
- Flood reports are append-only for clients: neither `anon` nor `authenticated` has UPDATE or DELETE permissions, even for their own reports.
- Public client reads select only `id`, `latitude`, `longitude`, `flood_depth`, `road_status`, `notes`, and `created_at`. The applied privacy migration restricts both anon and authenticated SELECT to these columns, with effective privileges checked by the project owner. Notes remain public and must not contain private/personal information. No Auth email or profile information is included.
- The app's guest flow uses `anon`, not Supabase anonymous sign-in; guests cannot submit reports. Supabase anonymous sign-in is not used and should remain disabled.
- Phase 10 Home fetches the latest 100 public reports, newest first, for both guests and authenticated users. It replaces demo flood entries/markers, provides refresh/retry actions, and does not geographically filter the fetch. Home then assesses straight-line proximity against this loaded collection for real saved routes; it is not a global road-safety assessment.
- Report Flood requires a manually selected valid map coordinate, one of `ankle/knee/waist/chest`, and `passable/not_passable`. Notes are optional, with a 1,000-character client limit and a reminder that notes are public. The existing SQL text column has no added length constraint.
- The submission service checks the active authenticated user and pins `reporter_id` to that user; RLS enforces ownership. IDs and timestamps remain database-generated. Pending submissions disable the form, failures preserve the draft, and successful submissions return to Home and reload reports.
- Reporter UUIDs remain in the database and authenticated INSERT payload for ownership, but are removed from the public Flutter model and SELECT projection. The migration removes table-level and reporter-column SELECT grants without changing existing INSERT permissions or RLS policies, and checks effective privileges to detect inherited access. The UI does not display reporter UUIDs, emails, names, or Auth details. No client report UPDATE/DELETE methods, photo upload, or Supabase Storage were added.
- Account changes discard any open Report Flood draft with the existing account-scoped navigation. Public reports can appear across accounts by design; private route isolation is unchanged.

Both tables use required Auth ownership foreign keys with `ON DELETE CASCADE`: deleting an Auth account removes its routes and reports. Client writes cannot override database-generated IDs/timestamps or transfer route ownership. No optional `profiles` table is needed for current functionality.

See [database setup and verification](../supabase/README.md) for the Phase 8 setup instructions, grants, constraints, and rollback-only role tests in `supabase/tests/phase_8_rls.sql`. Do not rerun already-applied migrations on the deployed tables.

## Checklist

- [x] Public flood-report projection/model and column-privacy migration prepared.
- [x] Privacy migration manually applied and effective privileges checked by the project owner.
- [x] Full updated rollback-only SQL verification passed after both migrations (owner confirmation, 2026-09-30); fixtures rolled back.
- [x] Guest/authenticated public reads and authenticated submit/refresh verified by the project owner after the privacy correction.
- [x] Direct REST checks allowed the seven-field public projection and denied `reporter_id` and wildcard requests for both Guest and authenticated roles (owner confirmation, 2026-09-30).

- [x] `.env` is in `.gitignore`.
- [x] `.env.example` exists for documenting the required environment-variable names without storing their real values.
- [x] No `service_role` key is intentionally used by the Flutter client.
- [x] Guest demo routes and automated report fixtures are fictional/sample data; Home flood data comes from Supabase.
- [x] Recorded repository/history audit found no actual secrets; `.env` had no history. GitHub Secret Protection and Push Protection were confirmed by the project owner.
- [x] Final reachable-history scan completed on 2026-09-30. Generic security terms produced expected documentation/code matches; high-confidence privileged-key/private-key patterns produced zero matches, and `.env` has no commits.
- [x] Supabase table definitions and RLS policies written in the Phase 8 migration.
- [x] Migration applied to the intended Supabase project (confirmed by project owner before Phase 9).
- [x] Supabase RLS role tests run successfully against the database (confirmed by project owner before Phase 9).
- [x] Phase 9 route fetch/insert client integration and offline automated tests implemented.
- [x] Live end-to-end Phase 9 save/reload and account-isolation smoke test recorded (project owner confirmation before Phase 10).
- [x] Phase 10 authenticated report submission, public reads, and offline automated tests implemented.
- [x] Live end-to-end Phase 10 submit/reload/public-read smoke test recorded (project owner confirmation).
- [x] External GitHub Actions pinned to verified full commit SHAs.
- [x] Analyze/test failures block deployment; missing/empty Supabase build values stop the build. Informational analyzer diagnostics remain nonfatal.
- [x] Deployment for `f02925f` verified by the project owner on the GitHub Pages site (confirmed 2026-09-30).
- [x] Saved-route edit/delete service and widget tests passed, including ownership filters, confirmation/cancellation, failure handling and account-switch editor disposal.
- [x] Saved-route editing/deletion verified on the deployed app by the owner (confirmed 2026-09-30); earlier persistence and owner-isolation checks are recorded above.
- [x] Live production browser/authentication and end-to-end application flows verified by the owner for `f02925f` (confirmed 2026-09-30). Repeat after subsequent release changes.
- [ ] Review all final screenshots for real personal data.
- [ ] Review the final demo video for real personal data.
- [ ] Verify that no course or university credentials appear anywhere in the public repository.
- [ ] Verify that no real person's data is used in final test/sample data without permission.
- [ ] Complete a final security and privacy review immediately before submission.

No key has been recorded here as revoked because no known exposed privileged key has been identified during the project review so far. If a credential is later found in repository history, it will be revoked immediately and this document will be updated to record what was corrected.

## Final review

This document records completed checks and remaining verification, not a guarantee of exhaustive security. Git metadata is expected to be public; history was not rewritten. Avoid unnecessary personal information in public project content.

Review again after final production flow checks, screenshot capture and demo recording, and immediately before submission. Update the documentation review date and checklist only with checks actually completed. The successful deployment does not replace these final application and privacy checks.
