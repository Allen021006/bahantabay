# Weekly Increment Report

> **Project timeline note:** Development of Bahantabay started before Finals Week 1. The project foundation, design system, authentication flow, Home screen, and initial Add Route work were developed during the earlier project period beginning in late August 2026. This report specifically covers the work completed during **Finals Week 1, September 14–20, 2026**. Earlier work is referenced only when necessary to explain the current implementation and progress.

### Relevant development evidence

The following major Git commits support the completed work described in this report:

- `7be1770` — `feat: add Supabase schema and RLS` — September 15, 2026
- `3a913c8` — `feat: persist saved routes with Supabase` — September 17, 2026
- `1bc688d` — `feat: add community flood reporting` — September 19, 2026

## Week of: September 14–20, 2026

## What changed this week

- Added and applied the initial Supabase PostgreSQL database schema for Bahantabay. The database now contains the structures required for saved routes and community flood reports, including UUID identifiers, coordinate constraints, database-generated timestamps, and the fields required by the current MVP. This database work is backed by commit `7be1770` (`feat: add Supabase schema and RLS`).

- Implemented Row Level Security (RLS) policies to separate private and public application data. Saved routes are restricted to their authenticated owners, while flood reports are publicly readable by authenticated users and guests. Flood-report creation is restricted to authenticated users. These policies were introduced as part of commit `7be1770`.

- Added SQL-based RLS verification for important access-control cases, including route ownership, cross-account restrictions, guest restrictions, public flood-report reads, coordinate constraints, and prohibited flood-report modifications. The corresponding migration and security-testing files are included in commit `7be1770`.

- Connected the previously implemented Add Route interface to real Supabase persistence. Instead of keeping newly created routes only in temporary Flutter state, authenticated users can now save them to the database. This transition from UI-only route creation to persistent storage is backed by commit `3a913c8` (`feat: persist saved routes with Supabase`).

- Added typed route models and a dedicated route service to separate Flutter presentation logic from Supabase data operations. This made database reads and writes more structured and easier to test. These architecture changes are also part of commit `3a913c8`.

- Updated Home so authenticated users load their own saved routes from Supabase. A successfully saved route appears after returning to Home and remains available after refreshing the application. The database-backed Home integration is contained in commit `3a913c8`.

- Improved authentication and application-state handling when switching between users. Route data and navigation state are associated with the current account so that private route information from one session is not left visible after another user signs in. The implementation for this account-scoped state handling and stale-data protection is included in commit `3a913c8`.

- Manually verified the route-persistence implementation using two different authenticated accounts and Guest mode. Account A and Account B were each able to create and view only their own routes. After switching accounts, private route data from the previous account did not remain visible. Guest mode also remained read-only. These were live verification checks against the actual Supabase project rather than only automated widget tests.

- Verified that persisted routes were actually written to the Supabase `routes` table, survived a browser refresh, and continued to display their saved coordinates on the Home Map. These checks confirmed that the work introduced in `3a913c8` was functioning beyond the local interface.

- Completed the community Report Flood integration. Signed-in users can select a location on the map, choose a flood-depth level, indicate whether the road is passable, add optional notes, and submit the report to Supabase. Home now retrieves public flood reports and displays them in the application and as markers on the Home Map. This completed increment is backed by commit `1bc688d` (`feat: add community flood reporting`).

- Manually verified the Report Flood workflow against the live Supabase backend. Account A successfully submitted a flood report, and the report appeared on Home and as a marker on the Home Map. The corresponding database row contained the expected report data and authenticated ownership information, and the report remained available after refreshing the application.

- Verified the public/private behavior of flood reports across different user states. Account B could read Account A's public flood report while Account A's private saved route remained isolated. Guest mode could also read public flood reports but could not submit a new report. No raw Supabase or database errors were exposed to the user during the verified flow.

- Added automated tests around the flood-report implementation, including model mapping, service behavior, form validation, loading states, failure behavior, public reads, and Home refresh behavior. Together with the existing route and authentication tests, the latest completed full test run passed **43 tests**, with `flutter analyze` reporting no issues.

## Why

The main goal this week was to move Bahantabay beyond interface prototypes and make its Supabase-backed features actually work with real users and persistent data.

The first major step toward that goal was commit `7be1770`, which established the database schema and RLS rules. This was important because the application needed more than a Flutter interface that simply hid or showed information. The database itself needed to enforce which records a user was allowed to access.

The second major step was commit `3a913c8`, which connected the existing Add Route workflow to Supabase and allowed authenticated users to save and retrieve real route records. This made route data persistent instead of temporary and also required additional account-state handling so each user's private data remained isolated.

Persistent routes are necessary because an authenticated user's saved routes should remain available between application sessions instead of disappearing after refresh. RLS is equally important because hiding another user's routes in Flutter alone would not be sufficient protection if the backend still allowed unauthorized access.

For this reason, I treated testing with separate accounts as part of the implementation rather than only checking whether the screens looked correct. The manual verification helped confirm that Account A and Account B remained isolated while Guest access continued to follow the intended read-only restrictions.

The third major step was completing the Report Flood workflow in commit `1bc688d`. This replaced demonstration-only flood information with a working community-reporting flow backed by Supabase. Reports can now be submitted by authenticated users, persisted in the database, retrieved publicly, and displayed through both the Home list and map interfaces.

I also tested the reporting flow using different account states because Bahantabay intentionally treats saved routes and community flood reports differently. Saved routes are private to their owners, while flood reports are community information that other users and guests need to be able to view. Verifying both behaviors together helped confirm that the application and RLS rules were following the intended privacy model.

## What broke or what I got stuck on

Supabase authentication was more complicated than I originally expected. I initially thought mainly in terms of making sign-in and sign-out function correctly, but the implementation showed that authentication also affects application state, navigation, database ownership, RLS, and what should happen to previously loaded information after the active user changes.

One of the most time-consuming parts of the work introduced around commit `3a913c8` was making sure Account A, Account B, and Guest mode did not retain stale state from one another. It was not enough to simply change the logged-in user in the interface. Previously loaded private route information also had to be discarded correctly.

This required several manual verification loops after the implementation was completed. I repeatedly signed in as Account A, created and checked database records, signed out, switched to Account B, verified ownership restrictions, returned to Account A, and then checked Guest behavior. This process took more time than testing a single-user application, but it was necessary because the privacy of saved routes depends on authentication state, application state, and database RLS working together.

The Report Flood integration added another layer to this testing because flood reports are intentionally public while saved routes remain private. I needed to verify not only that a report could be submitted successfully, but also that another authenticated account and Guest mode could read the report without exposing private route data. This increased the amount of manual testing needed, but it helped confirm that the public and private data rules were behaving differently as intended.

Another challenge was keeping the project within its planned MVP. It would be easy to add more advanced map functionality before the core workflow is complete, but doing so would increase development risk. Features such as road-following route geometry, geocoding, photo uploads, and other map improvements are therefore still intentionally deferred.

One area I can improve is the automated testing strategy around authentication and account-state transitions. The project already contains automated coverage for these behaviors, but stronger widget or integration testing with controlled Supabase test environments could reduce the amount of repetitive manual switching between Account A, Account B, and Guest mode in future development.

## What is left

- Finish the Route Details screen.
- Implement the route-status calculation that will determine whether a saved route is **Safe**, **Warning**, or **Not Passable** based on relevant flood reports.
- Complete end-to-end integration testing across authentication, saved routes, flood reports, Route Details, and route-warning states.
- Verify the production GitHub Pages deployment and Supabase production authentication configuration.
- Keep the public README, runtime screenshots, and project documentation updated as the remaining MVP features are completed.
- Add a current runtime screenshot of Route Details after the screen is implemented.
- Complete the final security and privacy review.
- Prepare the final demonstration video, presentation slides, and 1080 × 1080 project image.
- Perform final UI/UX polishing only after the required MVP works end to end.

After the required MVP is complete, one of my main future improvements would be replacing the current two-point straight-line route representation with actual road-following route geometry. I would also like to add a startup splash screen in the future to give Bahantabay a more polished and engaging entry experience, even though that feature was not part of the original MVP proposal.
