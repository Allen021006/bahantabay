# Proposal

Bahantabay is a community-based flood monitoring and route warning application designed to help commuters make safer travel decisions during flooding. This document contains the revised project proposal and reflects the current MVP scope, backend choice, screen structure, data model, implementation decisions, and risks.

## The problem, in one sentence

Commuters in flood-prone areas of the Philippines often discover that a specific road, underpass, or intersection is impassable only after they have already started traveling, because general weather applications provide citywide rainfall forecasts rather than real-time, route-specific information about whether the exact streets they use are passable.

## Who it is for

Bahantabay is primarily intended for daily commuters in Angeles City and nearby flood-prone areas who repeatedly use the same routes during the rainy season.

The main intended users are:

- students commuting to and from school;
- office workers traveling to work;
- motorcycle riders and delivery riders;
- other commuters who need to know whether their usual route is affected by flooding before leaving.

At present, these users commonly check general weather applications, ask for updates in Facebook groups or community chats, search local community pages, or simply travel and discover the flooded road themselves.

These methods can provide useful information, but they usually do not give a clear, route-specific indication of whether a particular road is currently passable. Bahantabay is intended to address this gap by combining saved routes with community-submitted flood reports.

## Core features

Bahantabay has five core MVP features. These features were revised after completing earlier Flutter activities involving state, forms, lists, navigation, validation, and reusable components.

### 1. Authentication and guest access

Users can:

- sign in using email and password;
- create an account;
- continue as a guest;
- sign out;
- switch accounts.

Authentication is handled through Supabase Auth.

The Sign In and Sign Up modes are contained in the same **Sign In / Guest Entry** screen rather than being separated into different screens.

The Home screen also contains an account menu. This is a Material popup overlay and is not treated as a separate screen.

### 2. Home: saved routes and nearby flood reports

The Home screen serves as the main dashboard of the application.

It has two presentation states:

- **List View**
- **Map View**

These are two states of the same Home screen and are not separate screens.

The Home screen can display:

- saved routes;
- route status indicators;
- nearby flood reports;
- map markers for routes and reports;
- an account menu;
- actions for adding a route or reporting a flood.

The Map View uses `flutter_map` with OpenStreetMap tiles.

### 3. Save a route

Users can create a route using the **Add Route** screen.

For the MVP, a route consists of:

- a route name;
- a starting point;
- a destination point.

The user selects the start and destination coordinates directly on the map.

The MVP intentionally does not use Google Directions, OSRM, OpenRouteService, or another road-routing API to generate real road geometry.

Instead, the route is represented by a simplified straight geographic line between the selected start and destination coordinates.

This decision keeps the route feature achievable while still allowing Bahantabay to demonstrate route-based flood checking.

### 4. Report a flood

Users can submit community flood reports through the **Report Flood** screen.

A flood report includes:

- geographic location;
- flood depth;
- road status;
- optional notes;
- timestamp;
- reporter information when submitted by an authenticated user.

Location can be selected manually using the map.

Current-location detection through `geolocator` may also be used as a supporting enhancement, but the application must remain usable when location permission is denied or unavailable.

Manual map selection therefore remains the fallback.

### 5. Route flood status

The **Route Details** screen checks a saved route against nearby flood reports.

The application uses three user-facing route statuses:

- **SAFE**
- **WARNING**
- **NOT PASSABLE**

For the MVP, route matching is based on the simplified geographic line segment between the route's start and destination coordinates.

A custom point-to-line-segment distance calculation is used to determine whether a flood report is sufficiently close to the route to affect its status.

This is intentionally simpler than checking reports against hundreds of coordinates from a road-following route polyline.

### MVP implementation estimate

The revised implementation estimates were:

| Feature | Estimated effort |
| --- | ---: |
| Authentication / guest access | 7 hours |
| Home: saved routes + nearby flood reports | 9 hours |
| Save a route | 9 hours |
| Report a flood | 9 hours |
| Route flood status / Route Details | 7 hours |
| **Total MVP feature estimate** | **41 hours** |

An additional approximately 4 hours was estimated for initial Supabase, PostgreSQL, authentication, database schema, and Row Level Security setup.

This gave an estimated core implementation effort of approximately **45 hours**, excluding stretch goals.

These estimates were planning estimates based on earlier coursework experience rather than measured development totals.

## Out of scope, and why

The following features are intentionally outside the MVP.

They may only be implemented after the five core features are complete and stable.

### 1. Real road-following route geometry

A future version could use a routing service such as OSRM or OpenRouteService to generate an actual road-following path between the selected starting point and destination.

This would make route-to-flood matching more geographically accurate.

It is excluded from the MVP because it would introduce:

- an additional external service;
- network dependency;
- response parsing;
- routing API availability concerns;
- additional error handling;
- possible rate limits.

The simplified straight-line representation is sufficient for demonstrating the intended route-warning concept in the MVP.

### 2. Push notifications

A future version could notify users when a newly submitted flood report affects one of their saved routes.

This would require additional notification services, background processing, and event-handling logic beyond the current MVP.

### 3. Flood-severity visualization

A future version could display a heatmap or severity layer based on recent community flood reports.

This is useful but is not required for the main workflow of saving routes, viewing reports, and receiving route warnings.

### 4. Trusted reporter indicators

A future version could identify reporters whose submissions are frequently supported by other reports.

This would require additional reputation or verification logic and is therefore outside the MVP.

### 5. Advanced map interaction

Possible future enhancements include:

- address or place search;
- draggable markers;
- automatic route generation;
- turn-by-turn navigation;
- more advanced location-selection controls.

The MVP only requires map display, simple marker placement, start/destination selection, route visualization, and flood-report markers.

### 6. Flood-report photo attachment

Users may eventually be allowed to attach photos to flood reports using `image_picker` and Supabase Storage.

Photo uploading is excluded from the MVP because a useful flood report can already be submitted using:

- location;
- flood depth;
- road status;
- notes;
- timestamp.

Photo storage would also introduce file upload, storage rules, file-size handling, and additional privacy considerations.

If implemented later, the file itself would be stored in Supabase Storage while its URL could be referenced from the corresponding flood report.

## Data the app remembers, and where it is saved

Bahantabay requires shared data.

If one user submits a flood report, another user on another device must be able to see that report. For this reason, local-only storage such as `shared_preferences`, Hive, Drift, or `sqflite` is not suitable as the application's primary shared data store.

Saved routes are different because they belong to individual users and should not be visible to other accounts.

### Chosen backend: Supabase

Bahantabay uses Supabase as its backend.

Supabase provides:

- Supabase Auth;
- PostgreSQL;
- Row Level Security;
- client libraries for Flutter;
- optional Supabase Storage for future file uploads.

Supabase was selected because Bahantabay has a naturally relational data model.

The application contains relationships between:

- authenticated users;
- user-owned routes;
- community flood reports.

PostgreSQL provides a good fit for this structure.

Firebase was considered as a valid alternative, but Supabase was selected because the relational PostgreSQL model matches the project's planned data structure and allows the project to use tables, relationships, SQL queries, and Row Level Security.

### Authentication

Authentication credentials are managed by Supabase Auth.

The application does not create or store its own password field in the `profiles` table.

Supabase Auth handles:

- account creation;
- sign-in;
- sign-out;
- authentication sessions.

### Planned application data

#### `profiles`

| Field | Purpose |
| --- | --- |
| `id` | identifies the user profile |
| `display_name` | optional user-facing name |
| `created_at` | profile creation timestamp |

This table stores basic application profile information.

Authentication credentials remain in Supabase Auth.

#### `routes`

| Field | Purpose |
| --- | --- |
| `id` | route identifier |
| `user_id` | owner of the route |
| `name` | user-defined route name |
| `start_latitude` | starting-point latitude |
| `start_longitude` | starting-point longitude |
| `destination_latitude` | destination latitude |
| `destination_longitude` | destination longitude |
| `created_at` | creation timestamp |

Saved routes are private to the user who created them.

Row Level Security will be used so that authenticated users can only access the routes they are allowed to access.

#### `flood_reports`

| Field | Purpose |
| --- | --- |
| `id` | flood-report identifier |
| `reporter_id` | user who submitted the report |
| `latitude` | flood location latitude |
| `longitude` | flood location longitude |
| `flood_depth` | reported flood-depth category |
| `road_status` | reported condition of the road |
| `notes` | optional additional information |
| `created_at` | submission timestamp |

Flood reports are community data and are intended to be visible to users who need nearby flood information.

### Storage decision

The MVP does not require Supabase Storage because flood-report photos are outside the core scope.

If photo attachment is implemented later:

- image files will be stored through Supabase Storage;
- a file reference or URL may be stored with the flood report.

### Shared-data behavior

Bahantabay therefore uses two different data-access patterns:

- **routes** are user-specific;
- **flood reports** are shared community information.

This distinction will be enforced through Supabase Row Level Security policies.

### Public repository configuration

Local Supabase configuration is provided through a git-ignored `.env` file.

The Flutter application reads:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

The Supabase publishable key is intended for use by client applications and does not replace database security.

The Supabase secret/service-role key must never be placed in:

- Flutter source code;
- `.env` used by the client application;
- GitHub commits;
- the deployed web application.

Database protection is handled through Row Level Security.

For the deployed GitHub Pages build, the required client-safe values are provided through GitHub repository secrets during the build process.

## Risks

### Risk 1: Route and flood-report matching

The main application-specific technical risk is deciding when a flood report is close enough to a saved route to affect the route's status.

The original proposal considered a real road-following polyline containing many points.

The revised MVP uses only the route's start and destination coordinates, which reduces the route to a single geographic line segment.

This significantly reduces the implementation complexity, but it does not eliminate the matching problem.

A threshold that is too small could fail to identify a relevant flood report.

A threshold that is too large could incorrectly associate a report from a nearby but unrelated road with the saved route.

GPS and manually selected coordinates can also contain positional inaccuracies.

The planned approach is to test several candidate thresholds, such as:

- 50 meters;
- 100 meters;
- 150 meters.

The selected distance will be represented as a named constant so that it can be adjusted during testing without rewriting the route-matching algorithm.

The matching logic should also be tested independently before being relied upon by the Route Details screen.

### Risk 2: Supabase and backend integration

Supabase introduces several areas that need careful implementation:

- authentication;
- database relationships;
- asynchronous Flutter queries;
- Row Level Security;
- loading states;
- error states;
- session handling;
- public deployment configuration.

Incorrect Row Level Security policies could either prevent legitimate database operations or expose data that should remain private.

The backend must therefore be tested incrementally rather than being added only after all screens are complete.

Supabase Auth has already been connected to the Flutter application for sign-up, sign-in, sign-out, and session restoration.

The remaining database tables and Row Level Security policies will be added and tested in a dedicated implementation phase before route and flood-report persistence depend on them.

### Risk 3: Browser geolocation

Browser-based location access depends on:

- user permission;
- browser support;
- device capabilities;
- secure hosting requirements.

The application must not depend completely on GPS.

If location access fails or permission is denied, the user will still be able to select the flood-report location manually on the map.

This keeps the complete reporting workflow usable on the web.

### Risk 4: Public repository security and privacy

The final project repository is public.

This creates a risk of accidentally exposing:

- secret credentials;
- service-role keys;
- private user data;
- student information;
- identifying screenshots or sample data.

The application therefore uses a git-ignored `.env` file for local configuration and repository secrets for deployed build configuration.

No Supabase service-role key is used by the Flutter client.

Public sample data, screenshots, documentation, and demo materials must also be reviewed before final submission to ensure that they contain no unnecessary personal information.

## Changes since the last version

### August 2026 — Backend changed from Serverpod to Supabase

The preliminary plan used Serverpod with PostgreSQL and additional backend infrastructure.

The project was revised to use Supabase instead.

Supabase provides:

- hosted PostgreSQL;
- authentication;
- Row Level Security;
- Flutter integration;
- optional Storage.

The change reduces the amount of backend infrastructure that must be built and maintained while preserving the relational database structure required by the project.

### August 2026 — Authentication changed to Supabase Auth

Authentication was originally expected to use the backend's own authentication system.

The revised application uses Supabase Auth for:

- sign-up;
- sign-in;
- sign-out;
- session restoration.

Passwords are not stored in the application's own tables.

### August 2026 — Route creation was simplified

The preliminary proposal expected saved routes to follow real roads using a routing or Directions API.

The revised MVP stores only:

- a selected starting coordinate;
- a selected destination coordinate.

The route is represented visually as a straight geographic line between those two points.

This removes the need for a routing service from the MVP while preserving the core concept of checking whether flood reports affect a saved route.

### August 2026 — Mapping changed to `flutter_map` and OpenStreetMap

The original plan considered Google Maps and related services.

The revised project uses:

- `flutter_map`;
- OpenStreetMap;
- `latlong2`.

This provides the map, marker, polyline, and coordinate functionality required by the MVP without requiring a billing-enabled Google Maps configuration.

### August 2026 — Photo attachment moved to stretch scope

Flood-report photo attachment was moved out of the MVP.

The reporting workflow remains useful through:

- report location;
- flood depth;
- road status;
- notes;
- timestamp.

Removing mandatory photo upload reduces implementation complexity and avoids introducing Supabase Storage before the core application is complete.

### August 2026 — Route status became an explicit implementation feature

Route-status calculation was separated from the Route Details UI because it represents its own application logic.

The MVP now explicitly includes the calculation needed to determine:

- SAFE;
- WARNING;
- NOT PASSABLE.

This makes the project scope and implementation effort clearer.

### August 2026 — Five-screen structure retained

The final MVP still contains exactly five screens:

1. Sign In / Guest Entry
2. Home
3. Add Route
4. Route Details
5. Report Flood

Home's List View and Map View remain two states of the same screen.

The account menu remains an overlay and does not create a sixth screen.

Sign Up also remains a mode inside the Sign In / Guest Entry screen rather than becoming an additional screen.

### September 2026 — Supabase authentication integration completed

The application is now connected to Supabase Auth.

The implemented authentication flow includes:

- email/password sign-in;
- account creation;
- sign-out;
- guest entry;
- authentication-state handling;
- session restoration.

The application reads its Supabase configuration using environment values rather than hardcoded credentials.

### September 2026 — Home List and Map views implemented

The Home screen now includes both planned presentation states.

The List View contains route and flood-report information using reusable Bahantabay components.

The Map View uses `flutter_map` with OpenStreetMap and currently demonstrates:

- route endpoints;
- a dashed straight-line route;
- flood-report markers;
- route warning information.

These are currently integrated with demo data while persistent route and flood-report database functionality is still being developed.

### September 2026 — Database persistence remains the next major backend step

Supabase Auth is already working, but the final application tables and Row Level Security policies for:

- `profiles`;
- `routes`;
- `flood_reports`;

still need to be implemented and connected to the application.

The next development stages will focus on Add Route, database schema and Row Level Security, route persistence, flood reporting, Route Details, and route-status calculation.
