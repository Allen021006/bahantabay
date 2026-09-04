# Weekly reports

One entry per week, newest at the top, written **during** that week. These reports record the actual progress of Bahantabay throughout development.

---

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
