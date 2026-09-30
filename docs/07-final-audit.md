# Final audit — September 30, 2026

Baseline: `0162836` (`chore: finalize demo preview and web presentation`).
Reviewer: Codex. This report records review and verification, not new feature
implementation or independently student-written code. No application, dependency,
workflow or database changes were made during this audit.

## Result

The existing automated checks pass, but final submission still has open items.
One submission/navigation bug was reproduced. Documentation needs reconciliation,
the release build still reports a missing icon font, and some backend verification
evidence remains outstanding. Passing tests do not establish that every flow is
bug-free or that the live database matches the migration files.

## Findings

### 1. Fix Back navigation during a pending flood submission

**Priority: P2 — functional bug, reproduced.**

`lib/features/flood_reports/presentation/screens/report_flood_screen.dart`
starts the request in `_submit`, but its Scaffold has no pending-operation
navigation guard. The mounted check prevents UI work after disposal; it does
not cancel the request. Home's `_openReportFlood` refreshes only when the screen
returns `true`.

Reproduction with a delayed fake service:

1. Open Report Flood from signed-in Home and fill all required fields.
2. Submit, leaving the request pending, then press the app-bar Back button.
3. Home appears before submission completes.
4. Resolve the pending submission successfully.

The service contains the new report, but Home has performed only its initial
fetch and does not show that report. Its route assessment can also remain stale
until a manual refresh. There is no completion feedback; retrying can create a
duplicate observation.

Suggested correction: use the same pending-operation navigation protection as
Add Route, while preserving account-change disposal. Add an integration test
that attempts Back during submission, resolves the request, and confirms Home
refreshes once. Also retain failure/draft-preservation coverage. An alternative
is an explicit background-submission design with completion notification and
refresh, but that is a larger behavior change.

A temporary widget test confirmed the current behavior and was removed after
the audit. It was a diagnostic assertion of the bug, not a passing regression
test of the desired behavior.

### 2. Resolve the missing Cupertino icon font warning

**Priority: P3 — build/presentation follow-up.**

The release build succeeds but reports:

```text
Expected to find fonts for (MaterialIcons,
packages/cupertino_icons/CupertinoIcons), but found (MaterialIcons).
```

`pubspec.yaml` does not declare `cupertino_icons`; the generated FontManifest
contains only MaterialIcons. No direct CupertinoIcons reference was found in
the application or inspected preview/map package sources. Flutter includes
adaptive Cupertino controls, so absence of direct application references does
not establish that the warning is harmless. A specific visibly broken control
was not reproduced during this audit.

Declare the required font package if retaining those controls, rebuild, and
check the iPhone preview's editing/selection controls. Do not disable icon
tree-shaking simply to hide the warning.

### 3. Make the tested SDK configuration reproducible

**Priority: P3 — maintenance.**

The Pages workflow pins its external actions, but selects the moving Flutter
`stable` channel without a Flutter version. The lockfile requires Flutter
`>=3.44.0` and Dart `>=3.12.0`, while the application advertises Dart `^3.8.0`.
Align the declared supported SDK with the actual dependency floor and pin a
tested Flutter version in CI. This is not a current build failure, and does not
justify upgrading dependencies as part of the audit.

## Verification performed

| Check | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test --reporter expanded` | All 98 existing tests passed |
| `flutter build web --release --base-href /bahantabay/` | Succeeded; icon-font warning above |
| Temporary delayed-submission diagnostic | Reproduced finding 1 |
| Temporary Home Map checks at 799×375 and 740×375 logical pixels | No Flutter exceptions; not a pixel/overlap or accessibility certification |
| `git diff --check` | Passed before the audit report was added; checked again for the final report |
| Local reachable-history credential-pattern scan | 72 revisions checked; no matching file hits |
| `.env` tracked history | No history returned by `git log --all -- .env` |

The release compilation used no live Supabase defines. It proves compilation,
not authenticated behavior of that local build. Existing service tests use fake
or loopback backends, not the deployed database. The owner separately confirmed
the live deployment and default iPhone 13 Pro Max preview before this audit.

The history scan checked recognizable Supabase secret-key, GitHub-token,
AWS-access-key and private-key-header patterns without printing secret values.
It is a limited pattern scan, not a comprehensive credential scan: arbitrary
passwords, legacy JWT credentials, inaccessible remote history and other token
formats are not ruled out. The broader final security-scan checklist is not
marked complete on the strength of this check.

## Review coverage and limits

| Area | Review/check coverage |
| --- | --- |
| `lib/main.dart`, `lib/app/`, `lib/core/` | Startup/configuration, preview wiring, layout helper, shared theme/widgets |
| Authentication feature | Session handling, account-scoped navigation, form/error/loading behavior |
| Home feature | Route/report loading, stale-result handling, selection, navigation, List/Map transitions and layout |
| Routes feature | Models, CRUD ownership filters, calculator, Add/Edit/Details and route widgets |
| Flood-report feature | Public projection, validation, submission, report model and display |
| Splash and starter features | Startup animation/lifecycle and retained unused starter screen |
| `test/` | All tests executed; coverage and relevant failure-path tests inspected; diagnostic probes added temporarily |
| `supabase/` | Both migration sources, grants/RLS/constraints, rollback test script and setup instructions inspected; no SQL run against live data |
| Package, analysis, web and CI configuration | Dependency/SDK declarations, build result, web metadata, preview default and deployment checks |
| Markdown, licence and example environment files | Current-state and attribution consistency checks; findings above |
| `docs/assets/` PNG/PDF files | Inventoried as existing design/runtime evidence; not re-rendered or comprehensively visually reviewed in this code audit |
| `.gitkeep` files | Repository placeholders only |

Unrelated untracked documents, dependency folders, videos, output and temporary
work were excluded and left untouched. No live database mutation, migration,
GitHub setting change, commit or push was performed. This is a repository-wide
code/configuration audit, not an exhaustive visual review of every binary asset,
a browser/device accessibility certification or a live penetration test.

The source access model is consistent with private owner-only routes and public
reports excluding reporter IDs. This is source-review evidence only; deployed
effective permissions require separate live evidence. Straight-line routes,
200-meter proximity, latest-100 report coverage, manual refresh and no report
expiry remain documented MVP limitations rather than newly discovered defects.

## Completion order

1. Fix and regression-test the pending-submission Back behavior.
2. Resolve the font warning and align/pin the tested SDK configuration.
3. Record the outstanding updated rollback-only SQL run and explicit denied
   reporter/wildcard API requests for both client roles, without rerunning
   already-applied migrations. Complete the broader secret-scan review.
4. Refresh screenshots, record the pending demo video, and recheck the live site
   after the final changes are deployed.

Core MVP flows have automated and owner-reported live evidence. Final submission
should remain open until these items are addressed or explicitly documented as
accepted limitations.

## Remediation update — September 30, 2026

The first three completion items above have now been addressed in local changes
and owner-confirmed live verification:

- Report Flood now prevents Back navigation while submission is pending. A Home
  integration regression test confirms the form stays open, successful completion
  returns to Home, and reports refresh exactly once. The full suite now passes 99
  tests and Flutter analysis reports no issues.
- `cupertino_icons` is now a direct dependency. The release web build succeeds
  without the missing Cupertino font warning. The manifest requires Dart 3.12,
  and the Pages workflow pins the tested Flutter 3.44.2 release.
- The project owner ran the complete rollback-only SQL script and received its
  final PASS result. Direct Guest and authenticated REST checks allowed the seven
  public report columns and denied `reporter_id` and wildcard selection. No
  migration was rerun and no secret/service-role key was used.

These local source/configuration changes still need to be committed, deployed,
and checked on the live site. Final screenshots, presentation review, demo video,
square project image, and final submission review remain open.
