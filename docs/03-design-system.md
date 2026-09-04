# Design system

Bahantabay uses a focused Material 3 design system built around Flood Blue, clear flood-status communication, simple typography, consistent 8dp-based spacing, and reusable Flutter components.

The application is light-only for the MVP. Colors, typography, and spacing are centralized so that individual screens and widgets do not need to define their own visual rules.

**This document needs a visual, not just this text.** The complete visual design system is available here:

[Design system (PDF)](assets/M7A3-Final-Project-Design-System.pdf)

The PDF shows the palette, type scale, spacing system, reusable components, and their visual treatment in one place.

## Palette

Bahantabay does not generate its primary palette using `ColorScheme.fromSeed()`. The main colors were selected manually because they communicate different meanings within the application.

Flood Blue represents the Bahantabay brand and primary actions, Warning Amber communicates caution, and Flood Red communicates danger. Keeping these colors distinct is important for the flood-monitoring context.

### Core palette

| Color | Hex | Purpose |
| --- | --- | --- |
| Flood Blue | `#1B4F72` | Brand identity, primary actions, Sign In hero background, and Home Map View |
| Warning Amber | `#E8A33D` | Warning states, highlighted alerts, and caution indicators |
| Flood Red | `#D64545` | NOT PASSABLE status and danger states |
| Alice Blue | `#E6F1FB` | Embedded map panels |
| White | `#FFFFFF` | Cards, sheets, dialogs, and text/icons over appropriate dark colors |
| Mist Grey | `#F4F6FB` | Default application background |
| Ink Navy | `#1B2340` | Main text and dark foreground content |
| Error Text | `#C23C3C` | Small error messages |
| Muted Text | `#555555` | Captions, timestamps, and secondary information |

### Material ColorScheme roles

| Role | Value | Used for |
| --- | --- | --- |
| `primary` | `#1B4F72` | App branding, primary buttons, active controls, Home Map background |
| `onPrimary` | `#FFFFFF` | Text and icons displayed over Flood Blue |
| `secondary` | `#E8A33D` | Warning and secondary emphasis |
| `onSecondary` | `#1B2340` | Text/icons displayed over Warning Amber |
| `surface` | `#FFFFFF` | Cards, sheets, and dialogs |
| `onSurface` | `#1B2340` | Main text |
| `error` | `#D64545` | Danger and NOT PASSABLE states |
| `onError` | `#FFFFFF` | Large/bold text and icons displayed over Flood Red |

The Flutter color scheme is represented as:

```dart
final appColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF1B4F72),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFFE8A33D),
  onSecondary: Color(0xFF1B2340),
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF1B2340),
  error: Color(0xFFD64545),
  onError: Color(0xFFFFFFFF),
);
```

### Bahantabay semantic colors

Colors that have application-specific meaning but do not need their own standard Material `ColorScheme` role are defined separately.

```dart
class AppColors {
  static const warning = Color(0xFFE8A33D);
  static const errorText = Color(0xFFC23C3C);
  static const scaffoldBackground = Color(0xFFF4F6FB);
  static const mapSurface = Color(0xFFE6F1FB);
  static const mutedText = Color(0xFF555555);
}
```

`warning` uses the same hex value as `ColorScheme.secondary`, but the semantic name makes its flood-monitoring purpose explicit when it is used by widgets such as `StatusBadge` and `FloodReportEntry`.

`errorText` provides a darker red for smaller error messages.

`scaffoldBackground` represents Mist Grey and is used as the default functional-screen background.

`mapSurface` represents Alice Blue and is reserved for embedded map panels.

`mutedText` is used for timestamps, captions, hints, and secondary information.

### Screen background rules

Bahantabay deliberately uses different treatments depending on the purpose of the screen.

**Default functional screens:** Mist Grey (`#F4F6FB`) is the normal application background.

**Sign In / Guest Entry:** Flood Blue (`#1B4F72`) is used as a full-screen branded hero treatment. Decorative translucent elements are derived from Flood Blue and White using transparency and do not introduce new palette colors.

**Home — List View:** Uses the standard Mist Grey background.

**Home — Map View:** Uses Flood Blue as an immersive full-screen map treatment. No additional Home Map color token is necessary because this view reuses the existing primary color.

**Add Route, Route Details, and Report Flood:** Embedded map panels use Alice Blue (`#E6F1FB`).

### Contrast and accessibility

Important status information does not depend on color alone. Route statuses always include readable text labels such as:

- SAFE
- WARNING
- NOT PASSABLE

The StatusBadge remains the primary readable status indicator. Any additional status-color dot is only a secondary visual cue.

The design-system contrast checks established the following:

| Combination | Contrast | Use |
| --- | ---: | --- |
| Ink Navy on Mist Grey | 14.3:1 | Normal body text |
| Ink Navy on White | 15.4:1 | Normal body text on cards |
| Error Text on Mist Grey | 4.85:1 | Small error messages |
| White on Flood Red | 4.38:1 | Large/bold text and icons only |

Because White on Flood Red falls slightly below the 4.5:1 body-text target, Flood Red is not used behind small normal-weight text. The darker Error Text color is used for small error copy instead.

### Dark mode

Bahantabay is light-only for the MVP.

A second color scheme is outside the current scope. Colors are centralized through the theme and semantic constants so that a future dark theme could be introduced without replacing hardcoded colors throughout individual widgets.

## Type scale

Bahantabay uses a deliberately small type scale because the five-screen MVP does not require a large number of text styles.

The application uses **Roboto**, Flutter and Material's default typeface. No custom font dependency is required.

| Style | Flutter slot | Size | Weight | Used for |
| --- | --- | ---: | --- | --- |
| Heading | `headlineSmall` | 22sp | Bold | Screen titles and major headings |
| Body | `bodyMedium` | 16sp | Regular | Normal application text |
| Caption | `labelSmall` | 12sp | Regular | Timestamps, hints, and secondary information |

The theme representation is:

```dart
textTheme: TextTheme(
  headlineSmall: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: appColorScheme.onSurface,
  ),
  bodyMedium: TextStyle(
    fontSize: 16,
    color: appColorScheme.onSurface,
  ),
  labelSmall: const TextStyle(
    fontSize: 12,
    color: AppColors.mutedText,
  ),
),
```

Typography is referenced through the theme rather than repeatedly defining literal sizes inside screens.

Example:

```dart
Text(
  'Bahantabay',
  style: Theme.of(context).textTheme.headlineSmall,
)
```

The Caption style uses regular font weight with the lighter Muted Text color. "Light" therefore refers to its visual emphasis rather than a separate `FontWeight`.

## Spacing

Bahantabay uses an **8dp base spacing system**.

The primary spacing rules are:

- **8dp** — gap between closely related elements and list items
- **16dp** — gap between sections
- **24dp** — screen-edge padding

A smaller 4dp value is available for tightly grouped elements.

| Token | Value | Typical use |
| --- | ---: | --- |
| `xs` | 4dp | Very small internal gaps |
| `sm` | 8dp | List-item and closely related element spacing |
| `md` | 16dp | Section spacing and standard component padding |
| `lg` | 24dp | Screen-edge padding |

These values are represented in Flutter as:

```dart
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}
```

They are referenced by name where possible instead of repeatedly using unexplained spacing values.

Example:

```dart
padding: const EdgeInsets.all(AppSpacing.md)
```

## Components

Bahantabay currently defines six reusable UI components.

Each component receives the information it needs through constructor parameters. Interactive components expose callbacks to their parent rather than owning screen-level state internally.

Screen state remains the responsibility of the parent screen.

| Component | File | Constructor parameters | Used on |
| --- | --- | --- | --- |
| `RouteCard` | `lib/core/widgets/route_card.dart` | `String routeName`, `String startLabel`, `String endLabel`, `RouteStatus status`, `VoidCallback onTap` | Home, Route Details |
| `StatusBadge` | `lib/core/widgets/status_badge.dart` | `RouteStatus status` | Home, Route Details |
| `FloodReportEntry` | `lib/core/widgets/flood_report_entry.dart` | `String location`, `String floodDepth`, `RoadStatus roadStatus`, `DateTime createdAt`, `VoidCallback? onTap` | Home, Route Details |
| `PrimaryButton` | `lib/core/widgets/primary_button.dart` | `String label`, `VoidCallback? onPressed`, `bool isLoading` | Sign In / Guest Entry, Add Route, Report Flood, Route Details |
| `EmptyState` | `lib/core/widgets/empty_state.dart` | `String message`, `IconData icon` | Home, Route Details |
| `RouteWarningBanner` | `lib/core/widgets/route_warning_banner.dart` | `String message` | Route Details |

### RouteCard

`RouteCard` represents a saved route.

It receives:

```dart
String routeName
String startLabel
String endLabel
RouteStatus status
VoidCallback onTap
```

The route name and start/end labels provide readable route information.

Route status is communicated using two coordinated visual cues derived from the same `RouteStatus`:

1. a text-labelled `StatusBadge`;
2. a small leading status-color dot.

The dot is a secondary visual cue only. It does not replace the readable status label.

### StatusBadge

`StatusBadge` receives:

```dart
RouteStatus status
```

The internal route states are:

```dart
RouteStatus.clear
RouteStatus.warning
RouteStatus.notPassable
```

These are presented to users as:

| Internal state | User-facing label |
| --- | --- |
| `clear` | SAFE |
| `warning` | WARNING |
| `notPassable` | NOT PASSABLE |

The text label always accompanies the status color so the status never depends on color alone.

### FloodReportEntry

`FloodReportEntry` receives:

```dart
String location
String floodDepth
RoadStatus roadStatus
DateTime createdAt
VoidCallback? onTap
```

It presents the main information associated with a community flood report.

`createdAt` is formatted for display as a readable timestamp or relative time.

`onTap` is nullable so the component can still be displayed when no interaction is required.

### PrimaryButton

`PrimaryButton` receives:

```dart
String label
VoidCallback? onPressed
bool isLoading
```

The normal state displays the supplied label.

When `isLoading` is true, the component can replace the normal label with a loading indicator.

`onPressed` is nullable so the same component can represent a disabled state.

### EmptyState

`EmptyState` receives:

```dart
String message
IconData icon
```

It displays a centered icon and message when content is unavailable.

Examples include:

- no saved routes;
- no nearby reports;
- no flood reports affecting a selected route.

The component intentionally has no action callback because its approved role is informational.

### RouteWarningBanner

`RouteWarningBanner` receives:

```dart
String message
```

It displays a prominent route-level warning on Route Details.

The amber visual treatment communicates caution, while the supplied written message explains the warning so that meaning does not depend on color alone.

### Standard Material controls

Some repeated interface elements do not need custom reusable widgets because Material already provides the required behavior.

Home's account access uses a standard `IconButton` / `PopupMenuButton`.

The List ↔ Map control uses a Material `SegmentedButton` positioned below the app bar.

These are not included as separate Bahantabay component files because they are standard Material controls.

## Changes since the last version

### August 2026 — Palette formalized as a Material ColorScheme

The preliminary design described the main colors primarily as application constants.

The revised design maps the core palette into a hand-selected Material `ColorScheme` while keeping Bahantabay-specific colors as semantic `AppColors` constants.

This preserves the distinct meanings of Flood Blue, Warning Amber, and Flood Red instead of deriving the complete palette from one seed color.

### August 2026 — Map Surface and Muted Text formally documented

Alice Blue (`#E6F1FB`) is now explicitly defined as `mapSurface`.

Muted Text (`#555555`) is explicitly defined for captions, timestamps, and secondary information.

This removes ambiguity about which colors should be used for embedded map panels and low-emphasis text.

### August 2026 — Authentication background clarified

Sign In / Guest Entry now explicitly uses Flood Blue as its full-screen branded background.

This is an intentional exception to the normal Mist Grey application background and does not introduce an additional palette color.

### August 2026 — Home Map treatment clarified

The design initially treated maps as one general light surface.

The finalized mockup showed that Home Map View benefits from a stronger geographic presentation.

Home Map therefore uses the existing Flood Blue primary color as its full-screen treatment, while Alice Blue remains reserved for embedded map panels on Add Route, Route Details, and Report Flood.

No separate Home Map color token was added.

### August 2026 — Typography mapped to Flutter TextTheme

The original Heading 22 / Body 16 / Caption 12 scale remains unchanged.

The styles are now explicitly mapped to:

- `headlineSmall`;
- `bodyMedium`;
- `labelSmall`.

This makes the typography easier to apply consistently through `Theme.of(context).textTheme`.

### August 2026 — Spacing converted into named constants

The original 8dp-based spacing rhythm remains unchanged.

It is now represented by:

- `AppSpacing.xs`
- `AppSpacing.sm`
- `AppSpacing.md`
- `AppSpacing.lg`

This makes the spacing rules directly usable in Flutter rather than leaving them only as written design guidelines.

### August 2026 — Component contracts formalized

Reusable components now have explicit Flutter files and constructor contracts.

The six approved reusable components are:

1. `RouteCard`
2. `StatusBadge`
3. `FloodReportEntry`
4. `PrimaryButton`
5. `EmptyState`
6. `RouteWarningBanner`

This makes the design system directly usable as an implementation reference.

### August 2026 — RouteWarningBanner added

`RouteWarningBanner` was not formally identified in the preliminary component system.

The full Route Details mockup showed that the relationship between a WARNING status and the flood report affecting the route needed an explicit explanatory element.

It was therefore added as a reusable component.

### August 2026 — RouteCard status cue refined

RouteCard originally relied primarily on StatusBadge.

The final design also uses a small leading status-color dot derived from the same `RouteStatus`.

The StatusBadge remains the primary readable indicator. The dot exists only as an additional at-a-glance cue.

### August 2026 — EmptyState added

`EmptyState` became necessary after the Home and Route Details layouts were developed in more detail.

Both screens require a consistent way to represent situations such as:

- no saved routes;
- no nearby reports;
- no reports affecting the selected route.

It was therefore promoted to a reusable component.

### August 2026 — Unused Auth Prompt Sheet removed

An Auth Prompt Sheet appeared in an earlier component concept but was removed because it is not used by the approved five-screen design.

Guest restrictions are handled through the actual authentication and Home behavior instead of introducing an additional custom sheet.

### August 2026 — Home controls clarified

Home's app bar now contains Bahantabay branding and profile/account access.

The centered Material `SegmentedButton` below the app bar switches between List View and Map View.

These controls use standard Material widgets and therefore do not require additional custom component files.

### September 2026 — Design system implemented in Flutter

The core design system is now represented in the Flutter project through centralized theme, color, and spacing files.

The reusable components have also been implemented and are being used as the common UI building blocks for Bahantabay's screens.

The design system remains the reference for future screens so that Add Route, Route Details, Report Flood, and later integration work continue using the same palette, typography, spacing, and component behavior.
