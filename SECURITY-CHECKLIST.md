# Security checklist

**Last updated: October 7, 2026**

This checklist records the security and privacy checks completed for Bahantabay. Final workflow-log, build-artifact, repository, media, asset-credit, and visibility checks were completed by the project owner before this update. All presentation files have been submitted.

## Secrets and credentials

| # | Check | Yes / No / Not applicable | Evidence |
| --- | --- | --- | --- |
| 1 | No API key, token or password is hardcoded in `lib/`, including in comments and commented-out code | Yes | The source review found environment-variable references and authentication logic rather than hardcoded credential values. |
| 2 | Anything private is in a gitignored config or passed with `--dart-define`, with an example file committed | Yes | `.env` is gitignored, `.env.example` contains placeholders, and client configuration is supplied through Dart definitions; privileged credentials are excluded from the client. |
| 3 | No keystore, `key.properties` or signing credential is in the repository | Yes | Tracked-file and history checks found no committed keystore, `key.properties`, or signing credential. |
| 4 | Git history is clean: I searched `git log -p` for password, secret, api key and token | Yes | The recorded reachable-history scan found expected documentation/code matches, no high-confidence privileged-key or private-key patterns, and no `.env` commits; this was a limited pattern scan. |
| 5 | Any credential that was ever committed has been rotated | Not applicable | No exposed credential requiring rotation was identified in the recorded checks. |

## GitHub Actions

| # | Check | Yes / No / Not applicable | Evidence |
| --- | --- | --- | --- |
| 6 | No secret value is written literally in any workflow YAML file | Yes | The reviewed deployment workflow references GitHub Actions secrets rather than embedding credential values. |
| 7 | Secrets are stored in repository Actions secrets and read with `${{ secrets.NAME }}` | Yes | The deployment workflow reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` through repository Actions secret references. |
| 8 | No workflow step echoes, dumps or debug-prints a secret, and I opened a recent run’s log to confirm | Yes | I reviewed a complete recent Actions log and found no accidental credential output, secret printing, or private-data dump. |
| 9 | If I build a signed APK: the keystore is a base64 secret decoded to a file at build time, never printed | Not applicable | The deployment builds Flutter web for GitHub Pages rather than a signed APK. |
| 10 | Uploaded build artifacts contain no key file, keystore or generated config | Yes | I inspected the final build artifact and found no unintended key files, keystores, `.env` files, or private generated configuration. |
| 11 | Third-party actions are pinned to a commit SHA, not a movable tag | Yes | The reviewed external action references use full verified commit SHAs with readable version comments. |
| 12 | Secret scanning and push protection are enabled on the repository | Yes | I confirmed GitHub Secret Protection and Push Protection, as recorded in `AI-USAGE.md`. |

## Backend and security rules

| # | Check | Yes / No / Not applicable | Evidence |
| --- | --- | --- | --- |
| 13 | Firestore and Storage rules are not left open to anyone; they require an authenticated user | Not applicable | Bahantabay uses Supabase PostgreSQL and Auth; Firestore and file Storage are not implemented. |
| 14 | Rules restrict a user to their own documents where that makes sense | Yes | Separate-account checks and SQL verification confirmed owner-only saved routes; flood-report observation fields are intentionally public. |
| 15 | If Supabase: Row Level Security is on for every table | Yes | Both application tables, `routes` and `flood_reports`, have RLS enabled and were checked in live Supabase. |
| 16 | Firebase and Google API keys are restricted in the Google Cloud console to the APIs and app they are for | Not applicable | The application does not use Firebase or Google API keys. |
| 17 | I opened the app signed out and confirmed I could not read or write data I should not | Yes | My Guest checks confirmed public-report reads while private-route access and write actions were blocked; direct REST checks also denied reporter-column access. |
| 18 | Seed and sample data is invented, not real people’s data | Yes | Repository Guest demonstrations and automated fixtures use labelled sample data; my real authentication test accounts are separate from these fixtures. |

## Input and app surface

| # | Check | Yes / No / Not applicable | Evidence |
| --- | --- | --- | --- |
| 19 | Input is validated before it is written, not only styled as valid in the UI | Yes | Forms and services validate input before submission, with database constraints and RLS providing additional checks; the 1,000-character notes limit is client-enforced. |
| 20 | Nothing secret is recoverable from the built app, since a shipped binary can be unpacked | Yes | I inspected the final build for unintended secret files and privileged credentials and found none; the Supabase URL and publishable key are intentional public client configuration. |

The Supabase URL and publishable key are expected to be recoverable from the web application. They are not privileged secrets. Database authorization depends on RLS and column privileges.

## Repository and privacy

| # | Check | Yes / No / Not applicable | Evidence |
| --- | --- | --- | --- |
| 21 | No student number, personal email, phone number or home address is in the repository or in commit messages | Yes | I completed the repository-content and final-media privacy review and found no prohibited personal information; Git author metadata is excluded under the professor’s clarification. |
| 22 | No classmate’s personal data is in the repository | Yes | I reviewed repository content and final presentation materials and found no classmate personal data. |
| 23 | Dependencies come from pub.dev, and `build/` and `.dart_tool/` are gitignored | Yes | Lockfile checks show non-SDK dependencies resolving through pub.dev, and `.gitignore` excludes both generated directories. |
| 24 | Images, fonts and other assets are mine, licensed, or credited | Yes | I checked asset licences and credits, including the Canva template, fonts, project visuals, map attribution, and AI-generated graphics. |
| 25 | Repository visibility is deliberate, and I checked it after my last push | Yes | I checked repository visibility after the latest push and confirmed that Bahantabay is intentionally public. |

## Additional database verification

I ran the complete updated rollback-only SQL verification against the intended live database. It returned its final PASS result and rolled back its test fixtures.

I did not rerun already-applied migrations.

I also performed direct REST checks:

| Request | Guest result | Authenticated result |
| --- | --- | --- |
| Select the seven approved public flood-report columns | Allowed | Allowed |
| Select `reporter_id` | Denied | Denied |
| Select wildcard `*` | Denied | Denied |

These checks used the publishable client configuration and an ordinary authenticated session. No secret/service-role key or database password was used.

## Anything I found and fixed

### Public reporter-column exposure

The privacy review found that public flood-report SELECT access exposed the internal `reporter_id`, even though Flutter did not display it.

The client now selects only the seven intended public fields. A separate migration restricts Guest and authenticated SELECT privileges while preserving authenticated INSERT ownership and RLS.

I manually applied and verified the migration, then completed the SQL and REST checks described above.

### Pending report submission

The application audit found that Back navigation could close the report form before a pending request completed, preventing Home from receiving the success result needed to refresh.

Codex added Back-navigation protection and a regression test at my request. I subsequently confirmed the protected submission flow on the deployed application.

### Deployment dependencies

External GitHub Actions were pinned to verified commit SHAs, and the workflow was pinned to Flutter 3.44.2.

The missing Cupertino icon-font warning was resolved by declaring the required dependency. The recorded release build included both Material and Cupertino icon fonts.

### Guest reporting action

The unavailable Report Flood button was removed from Guest mode in `ece0817`.

A later CI failure identified an AuthGate assertion that still expected the old disabled button. Codex corrected that assertion in `bc6b05f`.

This interface change improves clarity. Database access rules remain responsible for preventing unauthorized submissions, independently of whether the interface displays an action.

## Final presentation privacy and submission

The presentation slides, demonstration video, and corrected 1080 × 1080 square image are completed and submitted.

I reviewed the final materials for personal information and classmates’ data and checked their asset licences and credits.

My name is intentionally included in the presentation and square image because the assignment requires it.

My authentication test accounts use email addresses I control. These accounts are separate from public sample fixtures. The final materials do not expose their passwords, session tokens, personal email addresses, or private dashboard information.

AI assistance with the script, slide mockups, and generated graphics is disclosed separately from my Canva assembly, spoken delivery, recording, and final presentation preparation.

## Final review status

All applicable checklist rows are answered Yes based on the recorded checks and my final confirmations. Rows marked Not applicable identify technologies or deployment features that Bahantabay does not use.

The final review included:

- A complete recent GitHub Actions log.
- The final build and uploaded artifact.
- Repository content and final presentation media.
- Personal-information and classmate-data checks.
- Asset licences and credits.
- Repository visibility after the latest push.

## Scope of this checklist

This checklist records the checks performed and their results. It is not a guarantee of exhaustive security.

The history scan was limited to the patterns and reachable history inspected. Future application changes, dependency updates, commits, and newly published media require review before release.

If an exposed privileged credential is later discovered, it must be revoked or rotated promptly. Removing it from the latest file alone does not remove it from Git history.
