BAHANTABAY
High-Level Mockup
Community-Based Flood Monitoring and Route Warning App
The following mockups present the five MVP screens established in the Bahantabay proposal
and preliminary wireframes, now rendered in full colour using the finalized M7A3 design
system. The layouts remain based on the existing wireframes; this mockup stage applies the
actual typography, spacing, colours, components, icons, and realistic example content that
will guide the Flutter implementation.
All mockups use approximately 390 × 844 phone proportions. Home is shown in both List
View and Map View, but these are two visual states of the same Home screen rather than
separate MVP screens. This preserves the five-screen structure defined in M7A1.
Main user journey
Sign In / Guest Entry → Home
From Home, the user can open Add Route, Route Details, or Report Flood. Route Details can
also lead directly to Report Flood.
1. Sign In / Guest Entry
Prelim Requirement
3
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
Figure 1. Sign In / Guest Entry
Prelim Requirement
4
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
What the user does here:
The user enters an email and password to sign in, continues as a guest for read-only access,
or switches the same authentication screen into sign-up mode if they do not yet have an
account.
Where the tappable elements go:
Sign In → Home
Continue as Guest → Home (read-only session)
Sign Up → Sign-up mode on the same Sign In / Guest Entry screen
The Sign In / Guest Entry mockup uses Bahantabay's Flood Blue as a full-screen branded
hero treatment before the user enters the functional Mist Grey screens. This auth-specific use
of Flood Blue is documented in the finalized M7A3 design system.
2. Home
Prelim Requirement
5
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
Figure 2A. Home — List View
Figure 2B. Home — Map View
Figures 2A and 2B represent two states of the same Home screen, controlled by the List ↔
Map toggle.
Home supports two presentation states, switched by a centered segmented List ↔ Map
control positioned directly below the app bar. The app bar itself contains Bahantabay
branding on the left and the profile/account icon on the right. Both List and Map states
belong to the same Home screen and share the same navigation and account controls.
Prelim Requirement
6
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
List View
● Mist Grey application background.
● Saved routes displayed as RouteCards with status badge, leading status-color dot, and
distance/time.
● Nearby reports displayed as FloodReportEntry rows.
● Optimized for quickly scanning several routes and reports.
Map View
● Full Flood Blue map canvas for an immersive geographic presentation.
● Simplified two-point route representation shown as a straight/dashed line between
saved start and destination points.
● Flood-report markers displayed relative to the route.
● Floating white warning summary card for the selected route, with a View action
leading to Route Details.
● Report Flood floating action remains available.
● Optimized for understanding geographic context rather than scanning multiple list
items.
What the user does here:
The user checks saved routes and current flood conditions, scans nearby flood reports,
switches between List and Map presentation, opens a saved route, creates a new route, starts
a flood report, or uses the profile icon to access account actions.
Where the tappable elements go:
Profile icon → Account menu overlay
Log out → Sign In / Guest Entry
Switch account → Sign In / Guest Entry
Sign in / Create account (guest mode) → Sign In / Guest Entry
Prelim Requirement
7
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
List ↔ Map → Changes Home presentation only
RouteCard → Route Details
+ Add route → Add Route
Report Flood → Report Flood
The app bar is reserved for global application controls: Bahantabay branding on the left and
account access on the right. The centered List ↔ Map control sits directly below the app bar
because it changes how the Home content itself is presented rather than performing a global
application action.
List View uses the default Mist Grey application background and prioritizes fast scanning of
saved routes and nearby reports.
Map View uses a full Flood Blue map treatment to create a more immersive geographic
presentation. It still follows the simplified MVP route model: a saved route is represented
using its selected start and destination points rather than a road-following Directions API
path.
3. Add Route
Prelim Requirement
8
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
Figure 3. Add Route
Prelim Requirement
9
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
What the user does here:
The user gives the route a name, taps a starting point and destination on the map, confirms
both points, and saves the route.
Where the tappable elements go:
Back arrow → Home without saving
Map → Selects start and destination coordinates
Save route → Home with the route saved
The mockup follows Bahantabay's simplified MVP route model: the route is represented by
the selected start and destination coordinates rather than a road-following Directions API
path, matching the revised proposal. M7A1 defines Add Route as a two-point map-selection
workflow.
4. Route Details
Prelim Requirement
10
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
Figure 4. Route Details
Prelim Requirement
11
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
What the user does here:
The user checks the selected route's current status, views the simplified route and nearby
flood-report marker on the map, reads the report affecting the route, and can submit another
flood report if needed.
Where the tappable elements go:
Back arrow → Home
Report Flood → Report Flood
Route Details is the screen where Bahantabay's core route-warning concept becomes most
visible: the saved route, map information, nearby community report, and resulting
WARNING status are presented together. The amber RouteWarningBanner explains why the
route is currently flagged before the user reaches the detailed flood-report entry.
5. Report Flood
Prelim Requirement
12
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
Figure 5. Report Flood
Prelim Requirement
13
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
What the user does here:
The user selects or confirms the flood location, chooses the flood depth, marks the road as
passable or not passable, optionally enters notes, and submits the community report.
Where the tappable elements go:
Back arrow → Previous screen (Home or Route Details)
Map → Selects report location
Flood depth → Opens depth options
Passable / Not passable → Selects road status
Submit Report → Home with the report saved
The Report Flood screen remains fully usable without GPS because location can always be
selected manually on the map, matching the fallback planned in the proposal. M7A1
specifies location selection, flood depth, road status, optional notes, and a manual map-based
fallback when device location is unavailable.
Bahantabay - User Journey
The five MVP screens below are arranged to show Bahantabay’s main user journey. Home
List View and Home Map View are two states of the same Home screen, not separate
screens.
Prelim Requirement
14
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
Account flow: Home → Profile icon → Account menu → Sign In / Guest Entry (after Log
out, Switch account, or guest Sign in/Create account).
The Home List ↔ Map toggle changes only how Home presents its information and does not
create a separate screen. The account menu is also an overlay rather than a separate screen.
Bahantabay therefore remains a five-screen MVP.
From
Tappable element
Leads to / Result
Sign In / Guest Entry
Sign In
Home
Sign In / Guest Entry
Continue as Guest
Home — read-only session
Sign In / Guest Entry
Sign Up
Sign-up
mode
on
the
same
authentication screen
Home
Profile icon
Opens account menu overlay
Account menu
Log out
Sign In / Guest Entry
Account menu
Switch account
Sign In / Guest Entry
Account menu
Sign in / Create account (guest
mode)
Sign In / Guest Entry
Prelim Requirement
15
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
Home
List ↔ Map toggle
Switches Home presentation only;
remains on Home
Home
RouteCard
Route Details
Home
+ Add route
Add Route
Home
Report Flood
Report Flood
Add Route
Back arrow
Home — changes discarded
Add Route
Save route
Home — route saved
Route Details
Back arrow
Home
Route Details
Report Flood
Report Flood
Report Flood
Back arrow
Previous screen — Home or Route
Details
Report Flood
Map
Selects report location
Report Flood
Flood depth
Opens flood-depth options
Report Flood
Passable / Not passable
Selects road status
Report Flood
Submit Report
Home — report submitted
What Changed, and Why
The wireframes themselves remain unchanged. Painting them into full-colour mockups
revealed a small number of visual-system details that needed to be formally documented in
M7A3 so that the mockups and later Flutter implementation use the same rules.
Screen or
element
The wireframe /
earlier design
system assumed
The mockup
shows
What changed, and why
Prelim Requirement
16
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
Home
navigation
and
view
controls
The
original
Home
treatment
placed
the
List/Map
control
in the app bar and
did not define a
clear way to log
out,
switch
accounts, or leave
guest mode.
The final Home
app bar contains
Bahantabay
branding
and
a
profile icon, while
the
List/Map
segmented control
is centered below
the app bar. The
profile icon opens
account
actions
without
leaving
Home.
Keep this hierarchy in the Flutter
implementation. Account actions
will use a Material overlay rather
than a new screen, preserving
the
five-screen
MVP
while
providing
a
complete
authentication exit path.
Home Map
presentation
The
map
was
treated as another
light
embedded
map
surface
similar to the map
areas
on
the
form/detail
screens.
Home Map View
uses an immersive
Flood Blue map
canvas
while
keeping the same
two-point
route
model
and
warning
information.
Update M7A3 to distinguish the
full-screen Home Map treatment
from the lighter Alice Blue
embedded map panels. No new
color is needed because Home
Map reuses Flood Blue.
Route
Details
warning
message
The
earlier
component system
did not formally
define
a
route-level
warning banner.
A distinct amber
warning message
appears
between
the
map
and
nearby
flood
reports.
Keep
RouteWarningBanner
documented in M7A3 so it
becomes a buildable component
rather
than
undocumented
one-off UI.
Prelim Requirement
17
HOLY ANGEL UNIVERSITY
School of Computing
6ADET
Additional RouteCard refinement: the mockup retains both the text-labelled StatusBadge and the
small leading status-colour dot. M7A3 now documents the dot as a secondary visual cue derived from
the same RouteStatus; the badge remains the primary readable status indicator.