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

## Shared-header correction

A user found vertical controls/divider drift missed by the earlier title-only
demonstration. The fixture now derives a shared description height from sibling
copy at the offered width. Muse implemented the change and Grok reviewed it.
Swift build passed. Manual captures checked all three pages at default width,
shortest/longest descriptions at narrow width with inspector closed/open, and
resizing back to wide. Controls/divider stayed aligned. Albums description
truncation at minimum width remains a known limitation. This is focused visual
verification, not a completed or scored full evaluation suite.

## Compact composition correction

Replaced the cramped fallback with aligned label/control columns, a native Sort
menu picker, More actions, and an expandable About description. Manual checks
covered narrow/wide switching in both directions, Shuffle/Sort retention across
resize/navigation, inspector access, full Playlists description disclosure, and
Info sheet open/Return dismissal. The final sizing probe uses disabled hidden
controls with constant bindings, no actions affecting state, and no identifiers;
AX snapshots show one visible Shuffle/Sort control in each variant. Full VoiceOver
and keyboard-navigation certification is not claimed. Swift build passes.

## Window policy and boundary verification

Refreshed Apple HIG and AppKit sources are summarized in
[window adaptation research](WINDOW-ADAPTATION-RESEARCH.md). The previous
constraints-only patch failed a real drag below the declared minimum. The
revised native resize delegate passed repeated attempts to shrink to roughly
200×200: the captured window stopped at 560×502, matching 560×450 content plus
native chrome. Sidebar collapse precedes the stop; the Navigate picker remains
available for both automatic collapse and manual hiding. Widening restores the
requested sidebar; manual hiding stays hidden. Ctrl-Command-S restores an
automatically collapsed sidebar and widens just enough to show it. Compact
startup was inspected. Narrow Inspector sheet access and retained Volume on
wide reopen were tested. Sort and More share the same control-column edge.

These dimensions are fixture decisions. Full localization, VoiceOver, and all
window-management modes remain untested; screenshots alone do not certify them.

## Settings second-family probe (portability check, measured)

A second fixture (`SettingsFixture`: settings form, Grid label/control
columns, no sidebar/inspector/envelope/divider) was built to test whether
the skill transfers beyond the browser family. Swift build passes. The app
launches and stays running; `--layout-diagnostics` reports live
`contentSize=480x360`, minimum `400x300`, `controlColumnLeading=162`,
seeded `defectExtra=12`. `--print-contract` reports declared values and
exits before any UI (declared inputs, never measured geometry).

Screenshot pass on 2026-09-16 (this host, Dark appearance, 2x Retina;
evidence `docs/images/settings-seeded.png`, `settings-aligned.png`,
`settings-longlocale.png`):

- Declared contract `settings-control-column` (`settings/regular`,
  `settingsControl/leading`, 162 ± 0.5pt pane-local, app-decision).
- Method: window-frame edge detection (razor-sharp 1pt border both
  sides), origin at true content-left (40px @2x; visible-bg-start story
  at 42px differs by a 1pt systematic, folded into uncertainty), scale 2
  verified from frame geometry, Grid padding 20pt exact from source.
  Control leadings pixel-stable across every scanline: seeded
  theme/default-view/cache 404px, notifications 428px; aligned all 404px;
  long-locale same as seeded with wrapped label rows grown taller.
  Pane-local: (px−40)/2−20 → 162.0pt good rows, 174.0pt defective row
  (+24px = +12.0pt differential, origin-independent). Uncertainty 1.0pt
  (random ≈ 0, dominated by the 1pt origin systematic; the absolute-162
  plus differential-+12 double match constrains it).
- CLI `compare` verdicts: seeded exits 1 with notifications FAIL
  (measured, delta 12.0) + 3 unverified (uncertainty overlap — the 0.5pt
  tolerance is below screenshot proof threshold, so consistent rows
  honestly stay unverified, never pass); aligned exits 3 with 4
  unverified (defect gone, consistent-but-unproven); long-locale exits 1
  with the same fail + wrapped label bands and help text holding the
  columns by observation.
- Discovery note: CLI `scan` yields 0 candidates on the new sources
  (lexical scan does not match AppKit-direct `NSWindow` creation), so
  manual triage carried discovery — exactly the v1 bound the skill
  declares. No scanner change made.
- Portability verdict: the pass invoked only label/control columns. No
  browser anchor (title/subtitle, divider, body start) and no header
  envelope were required or referenced. The long-locale wrapping
  exclusion held by declaration.

Not yet run: narrow-width resize matrix, keyboard/VoiceOver spot-check,
and the full transfer-case protocol (`evals/transfer-cases.md` remains
not-run); instrumented measurement that could prove the 0.5pt passes.
