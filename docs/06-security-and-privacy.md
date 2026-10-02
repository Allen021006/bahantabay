# Security and privacy

Bahantabay is a public repository containing a community flood monitoring and route warning application. This document explains its data handling, access controls, completed verification, and remaining security and privacy checks.

**Documentation updated:** October 2, 2026.

Live verification statements are based on the project owner’s recorded checks. This documentation update does not represent a new independent audit of the deployed application or database.

## What the application stores

| Data | Where it lives | Access |
| --- | --- | --- |
| Authentication accounts | Supabase Auth | Managed by Supabase Auth; accessible through authorized account operations and project administration, not the public report API |
| Authentication session | Client-side session storage managed by Supabase Auth | Used by the signed-in browser; session tokens must not be shared or displayed |
| Saved routes, names, and endpoint coordinates | Supabase PostgreSQL | Authenticated owner through the application, enforced by RLS |
| Community flood-report location, depth, road status, notes, and creation time | Supabase PostgreSQL | Intentionally readable by Guest and authenticated clients |
| Internal flood-report `reporter_id` | Supabase PostgreSQL | Used for ownership enforcement; excluded from Guest and authenticated SELECT access |
| Guest demonstration routes | Application source code | Public, labelled demonstration data |
| Route-status assessment | Calculated in the application | Derived from loaded reports; not stored as a separate database field |

Project administrators have privileged backend access. Owner-only and public-read descriptions above refer to ordinary application clients, not administrative access.

Flood-report photos are **not implemented or stored**. Adding them would require a separate storage, privacy, and moderation review.

The application uses email/password authentication but does not require real names, student numbers, university credentials, private messages, or phone numbers for its flood-monitoring features.

## Public and private information

Saved routes are private because their names and endpoints may describe personal travel patterns.

Community flood reports are intentionally public. Their coordinates, road conditions, notes, and timestamps may be read by anyone using the public API, including people who are not signed in.

Public notes must not contain names, email addresses, phone numbers, home addresses, or other private information. The reporting form displays a reminder, but the application does not automatically detect or redact personal information.

The public flood-report API does not expose authentication email addresses or profile details. The signed-in account interface may display the current user’s email, so account menus and login screens need particular care during recording.

Using an email address for a private test account does not itself publish that address in the repository. Test-account credentials and sessions must remain private, and personal emails should be excluded or redacted from submitted media.

## Client configuration and secrets

The application requires:

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
```

For local development:

- `.env` contains the local values and is ignored by Git.
- `.env.example` contains placeholders.
- `--dart-define-from-file=.env` supplies compile-time definitions.
- The application reads those definitions through `String.fromEnvironment`; it does not dynamically load `.env`.

For deployment, the workflow reads the values from GitHub Actions repository secrets and passes them into the Flutter web build. It rejects missing or empty values before compilation without printing them.

The Supabase URL and publishable key are client configuration and can be recovered from the deployed application. Their presence in a browser build is expected. Authorization depends on database policies and privileges, not on hiding these values.

The Flutter application must never contain a Supabase secret/service-role key, database password, signing credential, private session token, or other privileged credential.

## Backend access controls

Bahantabay uses Supabase Auth and PostgreSQL Row Level Security.

The initial schema and the later public-column privacy migration have been applied to the project database. Already-applied migrations must not be rerun.

### Saved routes

- Authenticated users can create routes associated with their own user ID.
- Users can read, update, and delete only their own routes through the application API.
- Guests cannot read private routes or create, edit, or delete saved routes.
- Updates are limited to the route name and endpoint coordinates.
- Client writes cannot transfer ownership or override database-generated IDs and creation timestamps.
- The route service checks the active session and filters operations by owner ID.
- Update and delete operations also filter by route ID and require one returned ID to confirm success.
- RLS remains the authorization boundary even if client-side checks are bypassed.

The edit/delete flow reuses the existing ownership policies and grants. It did not require a new migration.

Deletion requires confirmation. Pending mutations disable submission actions, failures keep the editor open, and successful changes return to Home to reload routes.

Account switching or logout discards the previous account’s Home state, private Details screen, and open route editor. Stale asynchronous results cannot populate a new account’s route list.

### Community flood reports

Guest and authenticated clients can select only:

```text
id
latitude
longitude
flood_depth
road_status
notes
created_at
```

The privacy migration restricts SELECT privileges to these columns. Removing `reporter_id` from the interface alone would not have been sufficient; database privileges also deny access to it.

Report creation:

- Requires an authenticated, non-anonymous application session.
- Associates the report with the current authenticated user.
- Is checked by the submission service and enforced by the database INSERT policy.
- Leaves the report ID and creation timestamp to database defaults.

Neither `anon` nor `authenticated` has client UPDATE or DELETE permission for flood reports, including reports submitted by the same user.

The internal reporter UUID remains in the database and authenticated INSERT payload for ownership enforcement. It is excluded from the public Flutter report model and SELECT projection.

Guest mode uses unauthenticated access rather than Supabase anonymous sign-in. Supabase anonymous sign-in is not used and should remain disabled.

### Account deletion and retention

Both application tables reference Auth users through ownership foreign keys with `ON DELETE CASCADE`. Deleting an Auth account therefore removes its associated routes and reports.

The application does not currently provide a self-service account-deletion screen. Administrative account deletion is separate from logging out.

There is no automatic report expiry or resolution process. Limiting Home to the latest 100 reports does not delete older database records.

## Input validation and submission behavior

Report Flood requires:

- A valid manually selected map coordinate.
- A flood-depth value of `ankle`, `knee`, `waist`, or `chest`.
- A road-status value of `passable` or `not_passable`.
- Optional notes within the 1,000-character client limit.

The form and service validate input before submission. Database constraints provide additional checks for required values and valid data.

The notes column does not currently have a matching database length constraint. The client-side limit must therefore not be treated as a server-enforced restriction.

While report submission is pending, the form disables repeated submission and blocks Back navigation. On success, it returns to Home and triggers a report reload. On failure, it preserves the draft and displays a safe error message.

This prevents repeated taps during an active request but does not guarantee server-side deduplication. If the connection drops after the server accepts a report, the user should check Home before retrying.

Account changes discard open report drafts through account-scoped navigation. Public reports may appear across accounts by design; private routes remain isolated.

## Maps and route assessments

The application requests map tiles from OpenStreetMap. These requests go to an external service and can reveal ordinary connection information and the map area being viewed.

The application displays OpenStreetMap contributor attribution. It does not currently use device GPS, camera access, photo uploads, or Supabase Storage.

Home loads the latest 100 public reports globally, newest first. It then evaluates their proximity to each saved route locally.

A report affects a route when it is within 200 meters of the bounded straight-line segment:

- A relevant passable report produces WARNING.
- A relevant not-passable report produces NOT PASSABLE, which takes priority.
- No relevant severity-raising report produces SAFE after a successful load.

Loading and retrieval failures remain **Status not assessed**.

**SAFE is not a guarantee of real-world road safety.** Assessments use limited community observations and approximate straight-line geometry. They do not account for all roads, all reports, report expiry, or independently verified conditions.

## Deployment controls

The GitHub Pages workflow:

- Uses Flutter 3.44.2.
- Pins external GitHub Actions to full commit SHAs.
- Runs analysis and tests before building.
- Blocks deployment when required checks fail.
- Rejects missing or empty Supabase configuration.
- Uploads `build/web`, not the local `.env` file.

The configured analyzer permits informational diagnostics to remain nonfatal.

Workflow source inspection and a successful deployment do not by themselves establish that every log or uploaded artifact is free of private information. Final log and artifact inspection are tracked separately below.

## Completed verification

### Database and API checks

The project owner ran the complete updated rollback-only SQL verification and received its final PASS result. Test fixtures were rolled back, and no already-applied migration was rerun.

The owner also performed direct REST checks:

| Request | Guest client | Authenticated client |
| --- | --- | --- |
| Select the seven approved public report columns | Allowed | Allowed |
| Select `reporter_id` | Denied | Denied |
| Select wildcard `*` | Denied | Denied |

These checks used client-safe configuration and an ordinary authenticated session. No secret or service-role key was used.

### Application checks

The owner manually verified:

- Authentication and restored sessions.
- Saved-route creation and persistence.
- Account switching and owner isolation.
- Guest restrictions.
- Saved-route selection, editing, and deletion.
- Public report reads and authenticated submission.
- Report refresh and persistence.
- Pending-submission Back protection after the audit fix.
- Phone and compact desktop preview behavior.

These manual checks are distinct from automated tests.

### Automated checks and deployment history

The audit-remediation work in `8920448` passed analysis, all 99 tests, and a release web build. The owner subsequently confirmed successful deployment and live application checks.

The later Guest-interface change in `ece0817` removed the Report Flood button. Its initial CI run failed because an AuthGate test still expected the old disabled button.

Commit `bc6b05f` corrected that assertion to expect the button’s absence. Successful deployment of this follow-up and the newest live Guest view still require a recorded confirmation.

### Repository checks

The recorded reachable-history scan found:

- Expected generic security-related terms in source and documentation.
- No high-confidence privileged-key or private-key pattern matches.
- No committed `.env` file.

GitHub Secret Protection and Push Protection were previously confirmed by the owner.

These findings describe the scope and time of the recorded checks. They do not prove that all possible credential formats or future commits are safe.

## Verification checklist

### Completed

- [x] RLS enabled for `routes` and `flood_reports`.
- [x] Initial schema and public-column privacy migration applied.
- [x] Effective public-column privileges inspected by the owner.
- [x] Complete rollback-only SQL verification returned PASS.
- [x] Direct REST checks allowed public fields and denied `reporter_id` and wildcard selection for both client roles.
- [x] Live route ownership and account-isolation checks completed.
- [x] Live public reads, authenticated submission, and persistence checked.
- [x] Saved-route editing and deletion manually verified.
- [x] Pending-submission Back protection implemented, regression-tested, and manually checked after deployment.
- [x] Guest Report Flood action removed from the application.
- [x] Home and AuthGate assertions updated for the absent Guest action.
- [x] `.env` excluded from Git and `.env.example` uses placeholders.
- [x] Flutter client configured to use a publishable key rather than a privileged key.
- [x] Recorded history scan found no high-confidence privileged credentials or committed `.env`.
- [x] GitHub Secret Protection and Push Protection previously confirmed.
- [x] External Actions pinned to full commit SHAs.
- [x] Analysis and tests required before deployment.

### Remaining final checks
- [ ] Review a complete recent workflow log for unintended credential or private-data output.
- [ ] Inspect the final uploaded Pages artifact for key files, `.env`, privileged credentials, or unintended configuration.
- [ ] Review final screenshots, slides, PDF, video, and promotional image for personal or private information.
- [ ] Confirm that course credentials, university credentials, student numbers, and unnecessary personal contact information are absent from public files and commit messages.
- [ ] Review final sample records and media for real people’s private information.
- [ ] Verify ownership, licensing, and attribution for final presentation and promotional assets.
- [ ] Recheck repository visibility and submission-link access after the final push.
- [ ] Complete the final security and privacy review immediately before submission.

Completing the presentation files does not automatically complete their privacy review. Mark these items only after the relevant check has actually been performed.

## If a credential or private information is exposed

No exposed privileged credential has been identified in the recorded checks, so no credential rotation is claimed here.

If a privileged credential is discovered, revoke or rotate it promptly, remove it from current files, review its exposure and use, and document the correction. Removing a value from the latest file does not remove it from Git history.

If public notes or media contain private information, remove or redact the affected material using authorized administrative access and review any copies already published.

## Related documentation

- [Database setup and verification](../supabase/README.md)
- [Rollback-only SQL verification](../supabase/tests/phase_8_rls.sql)
- [Public-column privacy migration](../supabase/migrations/20260923000000_restrict_flood_report_public_columns.sql)
- [Final application audit](07-final-audit.md)
- [AI usage and authorship](../AI-USAGE.md)

## Review scope

This document records implemented controls, reported verification, and outstanding checks. It is not a guarantee of exhaustive security.

Git author metadata is public; repository history has not been rewritten. Review new code, documentation, and media before publishing, and update this checklist when verification is completed.
