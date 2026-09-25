# Bahantabay
[![Made with AI](https://img.shields.io/badge/Made_with-AI_assistance-blue)](AI-USAGE.md)

## Overview

Bahantabay is a community-based flood monitoring and route warning application for commuters in Angeles City and nearby areas. It supports private saved routes, public community flood reports, and route-specific status assessment using currently loaded reports. Route persistence and authenticated reporting have been manually verified against live Supabase.

## Project links

**Public project repository:** https://github.com/Allen021006/bahantabay

**Live site:** https://allen021006.github.io/bahantabay/ (final production/authentication verification pending)

**Demo video:** Coming soon

## Setup and installation

### 1. Install the tools

Use **Flutter 3.44.2 stable**, including **Dart 3.12.2**, plus Git and a modern browser. These are the previously recorded development SDK versions. Add Flutter's `bin` directory to PATH; check the installation with `flutter --version` and `flutter doctor`.

`pubspec.yaml` declares Dart `^3.8.0`, but the current lockfile requires **Dart >=3.12.0 <4.0.0 and Flutter >=3.44.0**. The broader manifest constraint is not the tested development environment; use the versions above to reproduce it.

### 2. Clone and install dependencies

```sh
git clone https://github.com/Allen021006/bahantabay.git
cd bahantabay
flutter pub get
```

The stack uses Material 3, simple widget state, Supabase Auth/PostgreSQL, `flutter_map`, OpenStreetMap, `latlong2` and `device_preview`. Exact package versions are in [pubspec.lock](pubspec.lock).

### 3. Configure Supabase

Create or use a Supabase project with email/password authentication enabled. For a **new database**, follow the preflight, ordered migrations and RLS tests in [database setup](supabase/README.md), including the public-column privacy restriction. The existing project database has both migrations applied and manually verified: **do not rerun its initial migration**.

The schema contains private `routes` and publicly readable `flood_reports`. RLS restricts routes to their owners and report creation to the authenticated reporter. Client report updates/deletes are prohibited. Supabase anonymous sign-in is not used and should remain disabled. If sign-up returns no active session, the app asks the user to confirm their email before signing in.

### 4. Configure the local app

Copy [.env.example](.env.example) to `.env`:

- PowerShell: `Copy-Item .env.example .env`
- macOS/Linux: `cp .env.example .env`

Replace the placeholders locally using your Supabase dashboard:

```dotenv
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

| Variable | Purpose | Source |
| --- | --- | --- |
| `SUPABASE_URL` | Project API URL | Supabase project dashboard |
| `SUPABASE_PUBLISHABLE_KEY` | Client-safe publishable key | Supabase API Keys settings |

`.env` is ignored by Git. `--dart-define-from-file=.env` passes **compile-time definitions** read by `String.fromEnvironment`; the app does not dynamically load `.env`. Stop and rerun after changing configuration.

Never supply a secret/service-role key, database password or private account credentials. The publishable key is visible in a web build; **RLS enforces authorization**, not secrecy of client configuration.

## How to run it

From the repository directory, after configuring `.env`:

```sh
flutter run -d web-server --web-port 8080 --dart-define-from-file=.env
```

Open **http://localhost:8080**. After the animated startup splash, expect Sign In / Guest Entry inside DevicePreview, or Home if an authenticated session is restored. Keep the terminal running. Guest entry creates no Supabase account, but real public report reads still require valid backend configuration and connectivity.

Development checks:

```sh
flutter analyze
flutter test
```

The last recorded validation after route-status integration reported **78 passing tests**, no issues from `flutter analyze`, and a passing `git diff --check`. Automated tests use test doubles/local fixtures without live Supabase credentials and do not replace manual backend verification.

## Features and usage

The locked MVP contains exactly five functional screens. Home List/Map are two states of **one Home screen**, Sign Up is an authentication mode, and the account menu is an overlay. The animated startup splash is a transient presentation state, not a sixth screen.

| Screen | Current use |
| --- | --- |
| **1. Sign In / Guest Entry** | Sign in with email/password, switch to Sign Up on the same screen, or continue as Guest. |
| **2. Home** | View private saved routes with calculated status after reports successfully load; switch List/Map and open Route Details. Both states use the same assessment. The account menu supports logout, account switching, or leaving Guest mode to sign in. Guests see labelled demo routes with separate hard-coded statuses and cannot save routes or report floods. |
| **3. Add Route** | Signed-in users enter a name, select start/destination points on the map, and save. Success returns to Home and refreshes routes. Supabase preserves each owner's private routes. |
| **4. Route Details** | Open a real saved route from Home List or Home Map's View action. Inspect its name, start/destination coordinates, map and supplied status. Back preserves the expected Home state. Status is a nullable snapshot from Home, with no independent report fetch or recalculation. |
| **5. Report Flood** | Signed-in users select a map location, Ankle/Knee/Waist/Chest depth, Passable/Not passable, and optional notes. Successful submission returns to Home and reloads reports. Live Supabase verification is complete. |

Reporting validates required inputs, prevents duplicate presses while submitting, and preserves the draft on failure. Notes are public, have a 1,000-character client limit, and must not contain personal information. Home displays coordinates, depth, passability, notes and time without displaying reporter identities.

Home loads the **latest 100 public reports globally**, newest first, with loading, empty, error/retry and refresh states. The report fetch is not geographically filtered. Route assessment then checks those loaded reports against each real saved route.

### Route status

A report is relevant when its location is within **200 meters of the bounded straight-line segment** between the saved start and destination.

- **SAFE:** the report collection loaded successfully and no relevant severity-raising report was found.
- **WARNING:** a relevant report marks the location as passable.
- **NOT PASSABLE:** a relevant report marks the location as not passable. This takes precedence over WARNING.

Loading or failed retrieval remains **“Status not assessed”**, never SAFE. Refreshing reports or successfully submitting a report causes Home to derive status again from the updated collection. An open Route Details screen retains its navigation-time snapshot. Status is not stored as a separate database field.

**SAFE is not a guarantee of real-world road safety.** Assessment is limited to currently loaded community reports and straight-line proximity; it is not a real-time road-safety prediction. Flood depth does not independently change severity, and there is no report expiry/resolution rule.

## Project structure

```text
lib/main.dart                 Supabase initialization and DevicePreview
lib/app/                      Application widget and theme wiring
lib/core/                     Configuration, theme, spacing and shared widgets
lib/features/authentication/  Auth service, session gate and Sign In/Sign Up UI
lib/features/home/            Single Home screen with List and Map states
lib/features/routes/          Models/service, calculator, Add Route and Route Details
lib/features/flood_reports/   Models/service, Report Flood and entry widget
lib/features/splash/          Startup presentation, animation and transition gate
supabase/                     SQL migrations, RLS tests and setup guide
test/                         Model, service and widget tests; test helpers
docs/                         Proposal, mockups, design and progress records
docs/assets/                  Design assets, mockups and current runtime captures
.github/workflows/            GitHub Pages build/deployment
```

## Screenshots

### Runtime screenshots

These earlier runtime captures show four application screens, including both presentation states of Home. They predate Route Details and calculated route status, so they are historical runtime UI evidence rather than a complete view of the current application or proof of backend operations. Updated Home/status and Route Details captures are still needed.

#### Sign In / Guest Entry

![Sign In / Guest Entry runtime screenshot](docs/assets/runtime-sign-in.png)

#### Home

| List | Map |
| --- | --- |
| ![Home List runtime screenshot](docs/assets/runtime-home-list.png) | ![Home Map runtime screenshot](docs/assets/runtime-home-map.png) |

#### Add Route

![Add Route runtime screenshot](docs/assets/runtime-add-route.png)

#### Report Flood

![Report Flood runtime screenshot](docs/assets/runtime-report-flood.png)

Report Flood is implemented and manually verified against live Supabase. This capture shows the form; backend verification was performed separately.

Route Details is implemented and manually verified, but its runtime screenshot has not yet been captured here. The existing `Route Details.png` below is an approved mockup, not runtime evidence.

### Approved design mockups — not runtime evidence

| Sign In / Guest Entry | Home — List | Home — Map |
| --- | --- | --- |
| ![Sign In mockup](docs/assets/Sign%20In%20_%20Guest%20Entry.png) | ![Home List mockup](docs/assets/Home%20-%20List%20View.png) | ![Home Map mockup](docs/assets/Home%20-%20Map%20View.png) |

Additional mockups: [Add Route](docs/assets/Add%20Route.png), [Route Details](docs/assets/Route%20Details.png), and [Report Flood](docs/assets/Report%20Flood.png). These show design intent, not proof that all features work.

## Known issues and next steps

- Routes use a straight two-point line, not road-following geometry or navigation.
- Assessment uses only currently loaded reports. The 200-meter rule is an MVP heuristic, with coordinate conversion approximated for short local routes rather than global/geodesic routing.
- Loading/error remains unassessed. There is no report expiry/resolution system, and flood depth does not independently determine route severity.
- No geocoding or device-location integration exists; select locations manually.
- No photo upload or Supabase Storage exists.
- Home reads only the latest 100 public reports globally, newest first, without geographic filtering of the fetch, pagination or automatic realtime updates. Route proximity is assessed locally within that collection.
- Clients cannot edit/delete reports. Public notes must not contain personal information; internal reporter IDs are excluded from client SELECT access.
- If connectivity drops during submission, check Home before retrying to avoid a duplicate.
- Final production integration/deployment and authentication verification remain pending, along with updated runtime screenshots and presentation materials.

**Next steps:** verify the complete application on GitHub Pages and Supabase; finish UI/UX polish, updated screenshots, documentation, demo video and the final security/privacy review.

**Possible post-MVP improvements:** road-following geometry, advanced map/location controls, and optional report photos with a separate storage/privacy review. No road-routing API was added to the MVP.

## Deployment and privacy

Supabase RLS separates private saved routes from public community flood reports. The owner manually verified RLS and Guest/private/public behavior. Guests can read public reports but cannot submit reports or access private saved routes; authenticated users can submit reports tied to their own identity.

The privacy correction limits anon/authenticated report SELECT access to `id`, `latitude`, `longitude`, `flood_depth`, `road_status`, `notes`, and `created_at`. `reporterId` was removed from the public `FloodReport` model. The internal `reporter_id` remains stored for INSERT ownership but cannot be selected by either client role, and reporter identities are not displayed. The owner manually applied [the privacy migration](supabase/migrations/20260923000000_restrict_flood_report_public_columns.sql) and checked effective privileges and application behavior afterward.

The [Pages workflow](.github/workflows/deploy-web.yml) runs on pushes to `main` or manual dispatch. Its external actions are pinned to verified full commit SHAs rather than movable tags. Set Pages to **GitHub Actions** and add repository secrets `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`. The workflow supplies `--dart-define` values and the repository base path; it uploads `build/web`, not `.env`.

Analysis/test failures currently do not block deployment. Verify the build, configuration and Supabase production authentication URL settings before treating the demo as verified. DevicePreview remains enabled in deployed builds.

Do not commit `.env`, privileged keys, passwords, personal information or private user data. See [Security and privacy](docs/06-security-and-privacy.md) for access rules and outstanding checks.

## Project documentation

| Document | Purpose |
| --- | --- |
| [Proposal](docs/01-proposal.md) | Problem, users and approved scope |
| [Mockup and wireframes](docs/02-mockup.md) | Five-screen design and planned flow |
| [Design system](docs/03-design-system.md) | Colors, typography, spacing and components |
| [Weekly reports](docs/04-weekly-reports.md) | Recorded development progress |
| [Demo video](docs/05-demo-video.md) | Recording plan; final video pending |
| [Security and privacy](docs/06-security-and-privacy.md) | Data access and verification checklist |
| [Database setup](supabase/README.md) | Apply-once migration and RLS verification |

## Credits and AI use

Built with Flutter, Supabase, `supabase_flutter`, `flutter_map`, OpenStreetMap, `latlong2` and `device_preview`. Versions are recorded in [pubspec.yaml](pubspec.yaml) and [pubspec.lock](pubspec.lock). Project logos, mockups and design assets are in `docs/assets/`; maps display OpenStreetMap contributor attribution.

AI assistance included **ChatGPT, Claude, and Codex**, with the amount of assistance varying by feature. AI was used for planning, architecture, implementation assistance, debugging, explanations, testing and documentation; substantial AI-generated code is disclosed rather than presented as independently written.

See **[AI-USAGE.md](AI-USAGE.md)** for the detailed development record, corrections to AI-generated output, commit evidence, and authorship breakdown.

## Licence

MIT; see [LICENSE](LICENSE).
