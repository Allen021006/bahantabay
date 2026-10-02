# Demo video

**Status:** Recording completed; hosted link provided below.

**Video:** [Watch the Bahantabay demonstration](https://drive.google.com/file/d/12VzaDGG6WseuExtIJyMyUxdHLjl1ZxWU/view?usp=sharing)

**Length:** [4 minutes 44 seconds]

**Recorded on:** [PC, Windows 11, Zoom Recording]

## About the video

This presentation introduces Bahantabay, a community-based flood monitoring and route warning application for commuters in Angeles City and nearby areas.

It demonstrates the application, explains selected implementation choices, and discusses how AI contributed to development alongside my personally written code.

## What it covers

- The commuter problem and the purpose of Bahantabay.
- Guest access to public flood reports and labelled demonstration routes.
- Authenticated access to private saved routes.
- Home List and Map views, saved-route selection, and Route Details.
- Route creation, editing, deletion, and flood reporting.
- The route-status calculator and its 200-meter proximity rule.
- AI assistance, my own implementation contributions, and development challenges.
- Current limitations and possible future improvements.

The application currently uses manual map selection. Camera access, device GPS, and sensor features are not implemented.

## Code and authorship discussion

The code explanation focuses on:

- `lib/features/routes/domain/route_status_calculator.dart`
- `test/route_status_calculator_test.dart`

I personally wrote the calculator and its 12 focused tests with ChatGPT teaching and guidance. Codex reviewed those files without modifying them and later authored the surrounding integration and widget tests.

The required AI-use segment distinguishes my personally written work, AI-guided learning, and changes implemented directly by Codex. The detailed development record is available in [AI-USAGE.md](../AI-USAGE.md).

## Assessment limitations

Bahantabay assesses currently loaded community reports near a bounded straight-line route. It does not provide road-following navigation.

SAFE means that no relevant severity-raising report was found in the loaded collection. It is not a guarantee of real-world road safety.
