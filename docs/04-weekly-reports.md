# Weekly reports

One entry per week, newest at the top, written **during** that week. These reports record the actual progress of Bahantabay throughout development.

---
## Week 2 — (September 7 to September 13, 2026)

### Work Completed

This week focused on moving Bahantabay beyond its initial interface and prototype state toward a functional application backed by real data and authentication.

The Add Route flow was completed as the next major user-facing feature. Authenticated users can enter a route name, select a start point and destination directly from an interactive map, and preview the route using two endpoint markers connected by a straight dashed line. The form validates that a route has a name and two distinct coordinates before it can proceed. The route representation intentionally remains a simple two-point line for the MVP rather than using a road-following routing API.

The Home screen was also integrated with the Add Route flow while preserving the existing List and Map presentation states. Guest users remain read-only, while authenticated users are given access to route-creation functionality.

The project backend was then expanded using Supabase PostgreSQL. An initial database migration was created for the `routes` and `flood_reports` tables. The schema uses UUID identifiers, database-generated timestamps, coordinate constraints, authentication-based ownership, and supporting indexes. The flood-report schema also defines controlled values for flood depth and road passability.

Row Level Security (RLS) policies were implemented as part of the database design. Saved routes are private to their authenticated owners, while flood reports are designed to be publicly readable for community flood awareness. Only authenticated users are permitted to create flood reports, and arbitrary client-side updating or deletion of reports is prohibited. Guest users remain unable to create or modify routes and flood reports.

A dedicated SQL verification script was also prepared to test the security rules using two different authenticated users and the anonymous role. The tests cover route ownership, cross-account access restrictions, guest restrictions, public flood-report visibility, invalid values, coordinate constraints, and prohibited flood-report modifications. Test fixtures are rolled back after verification to avoid leaving unnecessary records in the database.

Work also began on connecting the completed Add Route interface to the real Supabase backend. A typed saved-route model and route data service were introduced so route information can be converted cleanly between Flutter and the PostgreSQL schema. The architecture was kept minimal and testable rather than introducing unnecessary CRUD functionality or additional dependencies.

Authentication and navigation handling were strengthened to support account-specific route data. This includes ensuring that changing accounts does not retain another user's private route state. The existing Supabase publishable-key configuration and RLS-based security model were preserved without introducing privileged credentials into the Flutter client.

### Testing and Validation

The Flutter project continued to be checked using `flutter analyze`, `flutter test`, formatting tools, and `git diff --check` as features were added.

Automated tests were expanded for the Add Route flow, route model and service behavior, Home integration, authentication state changes, guest restrictions, validation, loading behavior, and error handling.

The Supabase schema and RLS policies were also tested separately using SQL-based security checks. These checks were designed to confirm that one authenticated account cannot access another account's private routes, while community flood reports remain publicly readable according to the intended MVP security model.

### Challenges and Decisions

One important design decision was to keep route geometry intentionally simple for the MVP. Routes currently consist of a selected start point and destination connected by a straight dashed line. Road-following services such as OSRM or OpenRouteService remain outside the current MVP scope.

Another major focus was maintaining a clear separation between public and private data. Saved routes are treated as account-specific information, while flood reports are community information intended to be visible to both authenticated users and guests. Supabase RLS is used as the database-level enforcement mechanism rather than relying only on Flutter interface restrictions.

The implementation also continued to avoid unnecessary scope expansion. Photo uploads, Supabase Storage, geocoding, advanced routing, and automatic route-status calculations were intentionally deferred so development could remain focused on the required MVP.

### Current Project Status

By the end of the week, Bahantabay had progressed from its initial authenticated Home interface into an application with a functional Add Route workflow, an established Supabase database schema, and a defined RLS security model.

The five-screen MVP structure remains unchanged:

1. Sign In / Guest Entry
2. Home
3. Add Route
4. Route Details
5. Report Flood

The next development work will focus on completing and validating persistent saved routes through Supabase before proceeding to community flood-report submission and the remaining MVP screens.
______________________________________________
## Week 1 (August 31 to September 6, 2026)

## **Done this week**

- Set up the Bahantabay Flutter project and organized the initial project structure.
- Connected the project to its public GitHub repository.
- Created the application's centralized Material 3 theme, color palette, typography, and spacing system based on the approved design system.
- Implemented the initial reusable UI components:
  - RouteCard
  - StatusBadge
  - FloodReportEntry
  - PrimaryButton
  - EmptyState
  - RouteWarningBanner
- Built the Sign In / Guest Entry screen.
- Connected Supabase to the Flutter project using environment-based configuration.
- Implemented the initial authentication flow for sign in, sign up, sign out, guest access, and session restoration.
- Built the Home screen shell and List View using temporary demo data.
- Built the Home Map View using `flutter_map`, OpenStreetMap tiles, and the simplified two-point route representation planned for the MVP.
- Added the account menu and List/Map switching behavior to Home.
- Added tests for the implemented foundation, components, authentication flow, and Home views.
- Ran `flutter analyze` and the test suite to check the current implementation.
- Updated the repository README with the project's description, setup instructions, current status, documentation links, and planned features.
- Organized the Proposal, Mockup and Wireframes, and Design System documentation in the `docs/` folder so they match the final-project repository structure.

## **In progress**

- Preparing the Add Route screen as the next application feature.
- Preparing the Supabase PostgreSQL database structure for saved routes and flood reports.
- Reviewing the repository structure and documentation against the final-project requirements before continuing with the remaining features.
- Preparing the GitHub Pages deployment configuration so the web build can eventually use the required Supabase environment values.

## **Blocked or stuck on**

No major blocker is preventing development at the moment.

The main unfinished backend work is the database schema and Row Level Security policies. Supabase Authentication is already connected, but the application is still using demo route and flood-report data because the database tables have not been created yet.

The deployed version will also need the Supabase configuration to be supplied securely through the GitHub Actions build before authentication can work on the live site.

## **Decisions made, and why**

- I chose **Supabase** for authentication and database storage because it provides both authentication and PostgreSQL in one backend and supports Row Level Security for protecting user-owned data.
- I kept **guest access** so users can view flood information without creating an account, while actions that modify data will require authentication.
- I chose **flutter_map with OpenStreetMap** for the MVP map implementation instead of using a paid or more complicated map service.
- I kept the MVP route model to **two selected points: start and destination**. Routes are currently represented using a simple line instead of implementing road-following navigation. This keeps the project achievable within the remaining development time.
- I kept **Home List View and Home Map View as two states of one Home screen**, rather than treating them as separate screens. This preserves the five-screen MVP defined in the proposal.
- I used a standard Material popup menu for account actions instead of creating another Profile screen. This provides sign-out and account-switching behavior without increasing the MVP screen count.
- I kept photos as a **stretch goal** for flood reports so that the core reporting workflow can be completed before adding file storage.
- I decided to complete a repository and documentation review before starting the next feature so that the implementation, proposal, mockup, design system, and final-project requirements remain consistent.

**Hours spent, roughly:** 10–12 hours

## **Next week I will:**

- Complete the Add Route screen and its map-based start/destination selection.
- Create the required Supabase database tables.
- Add Row Level Security policies for user-owned data and public/guest-readable information where appropriate.
- Connect saved routes to Supabase instead of relying only on demo data.
- Begin implementing the Report Flood workflow.
- Continue running `flutter analyze` and tests as new features are added.
- Add the next weekly report during development rather than waiting until the end of the project.
