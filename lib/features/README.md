# Feature structure

Bahantabay will use feature-first folders. Phase 0 retains the course starter
and reserves the following locations without implementing the approved screens:

| Approved screen | Future location |
| --- | --- |
| Sign in / guest entry | `authentication/presentation/screens/` |
| Home (map and list modes) | `home/presentation/screens/` |
| Route details | `routes/presentation/screens/` |
| Add route | `routes/presentation/screens/` |
| Report flood | `flood_reports/presentation/screens/` |

As each feature is implemented, keep its presentation, domain, and data code
inside its feature folder. Put only application-wide concerns under `lib/app/`
or a future `lib/core/` folder.
