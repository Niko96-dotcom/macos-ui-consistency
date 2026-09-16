# Validation scope

This is a v0.1 skill and deterministic helper, not a benchmarked UI repair engine.

## Exercised locally

- Python unit tests cover input validation, numeric comparison, uncertainty,
  excluded and unverified states, lexical candidate discovery, and output safety.
- Synthetic example comparison reproduces the committed expected JSON.
- Native SwiftPM fixture compiles on macOS 26 with Swift 6.3.3.
- Seeded and aligned Playlists reference modes were visually inspected at
  the same default window size. These are separate app modes, **not evidence
  that an agent performed a source repair**.
- Native Info sheet opens and dismisses with Return.
- At compact size, page navigation, inspector controls, and inner/outer
  scrolling were exercised. Long descriptions can truncate with the inspector
  open; see the fixture README. Localization and accessibility behavior have
  not been comprehensively tested.
- One external Muse source-only, audit-only trial identified the seeded title
  discrepancy, preserved app files, and withheld runtime verification. This is
  a limited behavioral smoke test, not a scored benchmark or repair-success rate.
- External Grok review identified output safety and report integrity defects;
  those received regression tests before publication.

## Not yet demonstrated

The full [evaluation scenarios](../evals/scenarios.md), including an actual
agent-driven source repair followed by runtime measurement, are not yet scored.
There is no automated screenshot measurement, XCUI adapter, coverage guarantee,
or universal SwiftUI refactoring engine. Numeric examples are synthetic.

Hosted CI results are visible in the repository's Actions tab. A successful
build or unit test run does not establish visual consistency of a user's app.
