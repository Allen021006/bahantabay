# Security and privacy

This repository is public. This document records the current security and privacy practices used by Bahantabay and will be updated as the backend and deployment are completed.

**Last checked:** 2026-09-04

## What this app stores

| Data | Where it lives | Who can see it |
| --- | --- | --- |
| User authentication account and session | Supabase Authentication | The authenticated user; authentication is managed by Supabase |
| Saved routes | Supabase PostgreSQL *(planned — database tables not yet implemented)* | Intended to be readable by their owner; access will be enforced through RLS |
| Route start and destination coordinates | Supabase PostgreSQL *(planned — database tables not yet implemented)* | Intended to follow the access rules of the saved route |
| Community flood reports | Supabase PostgreSQL *(planned — database tables not yet implemented)* | Intended to be readable by users and guests because the reports provide community flood information; creation will require an authenticated user |
| Flood location coordinates | Supabase PostgreSQL *(planned — database tables not yet implemented)* | Intended to be readable with the associated community flood report |
| Flood depth, road status, optional notes, and report time | Supabase PostgreSQL *(planned — database tables not yet implemented)* | Intended to be readable with the associated community flood report |
| Current demo routes and flood reports | Application source code | Anyone viewing the public repository or running the current demo; all entries are fictional/sample data |

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

Supabase Row Level Security will protect the PostgreSQL tables used for saved routes and community flood reports.

**Current status as of 2026-09-04:** Supabase Authentication has been integrated, but the application database tables and final RLS policies have not yet been created. The application is therefore still using demo route and flood-report data.

The planned access model is:

### Saved routes

- A signed-in user can create a route associated with their own authenticated user ID.
- A user can read their own saved routes.
- A user cannot create a saved route on behalf of another user.
- A user cannot modify or delete another user's saved routes.
- Guest users cannot create or modify saved routes.

### Community flood reports

- Flood reports are intended to be readable by signed-in users and guests so that community flood information remains useful without requiring an account.
- Only authenticated users can create flood reports.
- A submitted report must be associated with the authenticated user's ID rather than allowing the client to impersonate another user.
- Update/delete permissions will be restricted so that users cannot arbitrarily modify reports belonging to other users.

These rules describe the intended policy and **are not being marked as implemented or tested yet**.

The exact RLS policies will be added to this document after the Supabase schema and policies are implemented and tested during the backend phase.

## Checklist

- [x] `.env` is in `.gitignore`.
- [x] `.env.example` exists for documenting the required environment-variable names without storing their real values.
- [x] No `service_role` key is intentionally used by the Flutter client.
- [x] Current route and flood-report demo data is fictional/sample data.
- [ ] Run and record the final repository-history secret scan: `git log -p | grep -i "api_key\|secret\|password\|token"` and verify that it finds no real secret.
- [ ] Supabase RLS policies written and tested, not left open.
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
