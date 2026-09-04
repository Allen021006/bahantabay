# Bahantabay

Bahantabay is a community-based flood monitoring and route warning app designed to help users check flood conditions, monitor saved routes, and make safer travel decisions during flooding.

**Live demo:** https://allen021006.github.io/bahantabay/  
**Demo video:** Coming soon  
**Course:** Applications Development and Emerging Technologies (6ADET), Holy Angel University  
**Author:** Allen David C. Panganiban

This repository lives in the author's own GitHub account and is public on
purpose. There is no `student.json` here and there should not be one: see
`docs/06-security-and-privacy.md` for what a public repo means for secrets and
personal data.

---

## Screenshots

The screenshots below show the current approved Bahantabay interface and mockup direction.

| Sign In / Guest Entry | Home - List View | Home - Map View |
| --- | --- | --- |
| ![Sign In / Guest Entry](docs/assets/Sign%20In%20_%20Guest%20Entry.png) | ![Home - List View](docs/assets/Home%20-%20List%20View.png) | ![Home - Map View](docs/assets/Home%20-%20Map%20View.png) |

Additional mockup screens are available under `docs/assets/` for Add Route, Route Details, and Report Flood.

A repo without screenshots reads as abandoned, whatever the code says.

## What it does

- Lets users sign in, create an account, or continue as a guest.
- Shows saved routes and nearby flood reports from a single Home screen.
- Provides both List and Map views for route and flood information.
- Lets users create routes using a selected start point and destination point.
- Lets users report flood conditions and view route warnings based on nearby flood reports.

## Built with

| | |
| --- | --- |
| Framework | Flutter (Dart) |
| State | `setState` and simple local widget state |
| Backend | Supabase |
| Authentication | Supabase Auth |
| Database | Supabase PostgreSQL |
| Maps | `flutter_map` with OpenStreetMap |
| Coordinates | `latlong2` |
| UI Preview | `device_preview` |
| Design | Material 3 |

The project intentionally keeps its state management and architecture beginner-friendly and avoids unnecessary frameworks or abstractions.

## Running it yourself

```bash
flutter pub get
cp .env.example .env      
flutter run -d web-server --web-port 8080 --dart-define-from-file=.env
```

Then open http://localhost:8080. Requires Flutter (run `flutter --version` and
put yours here).

### Environment variables

This project reads its local configuration from a .env file that is intentionally excluded from Git.

| Variable | What it is | Where to get one |
| `SUPABASE_URL` | URL of the Supabase project used by the app | Supabase project dashboard |
| `SUPABASE_PUBLISHABLE_KEY` | Client-safe publishable key used by the Flutter app | Supabase API Keys settings |

The application reads these values at build/start time using:
--dart-define-from-file=.env

## Privacy and secrets

- Bahantabay uses Supabase for authentication and backend services. Authentication information is handled by Supabase, while route and flood-report data will be protected using Supabase Row Level Security policies.
- Local configuration is stored in the ignored .env file. The deployed GitHub Pages build receives the client-safe Supabase configuration through GitHub repository secrets.
- The public repository, sample data, screenshots, and demo materials must not contain student numbers, private messages, faces, secret credentials, or other unnecessary personal information.
See docs/06-security-and-privacy.md for the full project checklist.

## Project documentation

| Document | |
| --- | --- |
| [Proposal](docs/01-proposal.md) | the problem, the users, the scope |
| [Mockup and wireframes](docs/02-mockup.md) | what it looks like, and the screen flow |
| [Design system](docs/03-design-system.md) | colors, type, spacing, components |
| [Weekly reports](docs/04-weekly-reports.md) | what happened each week |
| [Demo video](docs/05-demo-video.md) | the recording and what it shows |
| [Start here](START-HERE.md) | how this repo works (delete once you have read it) |
| [Security and privacy](docs/06-security-and-privacy.md) | the checklist, filled in |

## Status and what is next

Bahantabay is currently under active development.

Completed
- Flutter project foundation and repository structure
- Material 3 design system
- reusable UI components
- Sign In / Guest Entry interface
- same-screen Sign Up mode
- Supabase email/password authentication
- authenticated-session restoration
- guest mode
- Home List View
- Home Map View
- OpenStreetMap integration
- demo route and flood markers
- straight two-point route visualization
- automated Flutter widget tests
  
In progress / next
- Add Route screen
- Supabase database schema
- Row Level Security policies
- route persistence
- Report Flood screen
- flood-report persistence
- Route Details screen
- route flood-status calculation
- final loading, error, and empty states
- GitHub Pages production authentication configuration
- final documentation
- final screenshots
- demo video
- final security and privacy review
  
The MVP intentionally does not include road-following navigation, turn-by-turn directions, photo upload, or other stretch features unless they are added after the approved core requirements are complete.

## Credits

Packages and services
- Flutter — application framework
- Supabase — authentication and backend services
- supabase_flutter — Supabase integration for Flutter
- flutter_map — interactive map rendering
- OpenStreetMap — map tile data
- latlong2 — latitude/longitude coordinate support
- device_preview — responsive device preview during development
  
Package versions are listed in pubspec.yaml and pubspec.lock.

Visual assets
Bahantabay's logo, mockups, and design-system assets were created specifically for this project and are stored under docs/assets/.
OpenStreetMap map tiles and geographic data are used according to OpenStreetMap attribution and usage requirements.

## AI use

AI tools, including ChatGPT and Claude, were used during development for planning, code assistance, debugging, explanation, testing support, and implementation guidance.

AI-generated suggestions were reviewed, tested, and adjusted to follow the approved project proposal, mockups, design system, course requirements, and security rules. The project owner remains responsible for understanding and maintaining the submitted code.

## Licence

MIT, see [LICENSE](LICENSE). Change it if you want different terms.
