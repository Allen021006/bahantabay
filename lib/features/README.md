# Feature structure

Bahantabay uses feature-first folders for the five implemented functional MVP screens:

| Approved screen | Location under `lib/features/` |
| --- | --- |
| Sign In / Guest Entry | `authentication/presentation/screens/sign_in_screen.dart` |
| Home (List and Map states) | `home/presentation/screens/home_screen.dart` |
| Route Details | `routes/presentation/screens/route_details_screen.dart` |
| Add Route | `routes/presentation/screens/add_route_screen.dart` |
| Report Flood | `flood_reports/presentation/screens/report_flood_screen.dart` |

Sign Up is a mode of the authentication screen. Home List and Map share one
screen, and the account menu is an overlay. `splash/` provides a transient
animated startup state, not a sixth functional screen. `starter/` retains the
original starter screen but is not the current application entry flow.

Feature folders separate presentation widgets, domain models/helpers, and data
services where needed. Authentication's session gate handles authenticated and
Guest entry. Home loads saved routes and public flood reports, derives route
status with `routes/domain/route_status_calculator.dart`, and passes the selected
route and assessed status to Route Details. Loading/error states stay unassessed.

Application wiring lives under `lib/app/`. Shared configuration, theme, spacing
and reusable widgets live under `lib/core/`. State remains in the existing
widgets and services without a separate state-management package.
