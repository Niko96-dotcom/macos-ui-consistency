# Validation scope

This is a skill and deterministic helper, not a benchmarked UI repair engine.

## Relational guidance update (2026-09-19)

- Added scoped guidance for paired view-switch slots, outer/inner content
  bounds, populated growth containment, and appearance-state review.
- Muse produced the documentation from retrieved owner feedback and the current
  app contract. A Grok review exercised three separate synthetic holdouts:
  a paired editor toggle with intentional unequal panes, inner-versus-outer
  form caps with valid nested scrolling, and fixed-size populated overflow.
  It identified the intended defects, preserved intentional differences and
  native focus, and withheld optical and missing-appearance verification.
- Review found discovery and fixed-size N/A wording ambiguities. Integration
  moved the reference into the general workflow, clarified that only resize
  checks are N/A for fixed windows, and put system-material exclusions first.
- The [new transfer scenarios](../evals/relational-transfer.md) remain unexecuted
  runtime scenarios. The holdout exercise was text-only reasoning, not an app
  run, visual acceptance, or a measured improvement benchmark.
- This update changes documentation only; comparator behavior and schema are
  unchanged. The existing 53 Python tests pass, and skill structure, local
  links, and whitespace checks pass. No product rebuild is needed for this delta.

## Whole-window upgrade (2026-09-18)

- The local Python suite passes 53 tests. New regression cases exercise explicit
  window/component targets across families, absent targets, requested-variant
  gaps, unrelated/system/intentional exclusions, evidence and environment gates,
  malformed selectors, deterministic ordering, and report generation with gaps.
- Legacy synthetic comparison output remains byte-identical, including when
  represented as a version 2 family contract. Explicit scopes require version 2;
  older CLI versions reject that contract version.
- Workflow guidance now separates geometry, transition stability, and optical
  composition, and preserves app-specific design decisions outside the skill.
- A read-only independent agent exercise against supplied multi-pane evidence
  identified label drift, a moving primary action, and a resting-field affordance
  issue; preserved an intentional wider inspector and visible system focus;
  withheld complete verification for missing build/resize evidence. Its feedback
  clarified evidence labels and audit-only reporting scope. This was a synthetic
  reasoning exercise, not a runtime trial or measured improvement benchmark.
- The native fixture builds locally after this upgrade.
- This upgrade does not establish new live-app visual or repair-success results.
  Historical fixture results below retain their original scope.

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

## Eval scoring — first scored runs (2026-09-16, this host)

All runs driven live against the fixtures on this Mac (Dark appearance,
2x Retina) via scripted UI drive (Quartz sidebar clicks with AX
verification, AX button clicks, keystrokes, osascript resizes) plus
screenshots and the instrumented `--dump-geometry` probe. Evidence:
`docs/images/eval-*`; run inputs/outputs: `.audit/eval-*` (gitignored
working material; verdicts below are the record). Headless-unfriendly
states got deterministic launch flags (`--inspector-open`,
`--content-width/height`); these reach the same states as taps/resizes.

- **S1 audit-only: PASS.** True in-app nav Tracks→Albums→Playlists,
  per-page screenshots, instrumented titles 24.0/24.0/32.0 → compare
  exit 1 (pass, pass, fail). Zero app files modified. Method note:
  screenshot ink-edge measurement is confounded by glyph bearings
  (T/A/P first-glyph ink differs ~9px at large-title size), so numbers
  use instrumented frames and screenshots are state evidence.
- **S2 explicit fix: PASS.** One-line fix in a `/tmp` fixture copy
  (playlists `titleLeading` → shared), diff-proven single change;
  before 32.00 → after 24.00 with before/after screenshots; compare
  exit 0, 3 pass. No `--aligned` output used as proof.
- **S3 source-only: PASS.** Assessment restricted to source facts
  (shared 24 at main.swift:80, +8 suspect at :122/:449), verdict
  UNVERIFIED throughout, no pixels or coverage claimed. Blinding caveat:
  assessor had prior runtime knowledge; artifact content is source-only.
- **S4 blocked sheet: PASS.** Info sheet opened on Tracks via real AX
  click, captured, Escape-dismissed; Albums sheet recorded blocked +
  reason (simulated gate) → compare yields unverified, never pass, no
  substituted evidence.
- **S5 intended variants: PASS.** Fixed copy keeps two-line Albums copy
  and compact inspector with own spacing (both captured); only (a)
  fixed; chrome untouched.
- **S6 header envelope: PASS.** Controls row y362-409 and divider
  y434-435 pixel-identical across T/A/P at 1000 closed, both nav orders
  (forward + reverse, order-independent), 1000 inspector-open (uniform
  +32px envelope re-resolve on all pages), 700 closed (compact band,
  pixel-identical incl. disclosure/divider), and live resize
  1000→700→1000 (branch flips both ways, anchors return, no stale
  height). No hardcoded heights, no truncation, copy intact. Body-top
  note: table-header-top vs list-first-row-top differ structurally with
  no declared cross-type contract, so observed + excluded per the
  skill's own uncontracted-relation rule; candidate for a future
  body-start contract.
- **S7 compact composition: conditional PASS.** Compact alignment
  79.50 on Shuffle/Sort/More across all 3 pages instrumented (9/9 CLI
  pass); native menu Sort shows value; More opened live (Hide
  Inspector + Info reachable); no huge blank; About disclosure present
  and collapsed-stable; shuffle ON survives nav + 860→1000→860
  resizes; no offsets/scaling/chrome moves (fixture code untouched by
  eval). Blocked sub-item: About-expand full-text capture (3 click
  attempts failed on a shared live desktop), so that criterion is
  untested, never passed.
- **S8 sizing envelope: PASS.** Programmatic resize to 200×200 clamps to
  560×502 on all 4 pane combos (later re-proven with true Quartz-driven
  width and height drags: 860→200 clamps 560 wide, 702→202 clamps 502
  frame height, drag-back restores; see follow-ups). Narrowest state
  keeps nav (picker + Show Sidebar), no clipped primary control;
  inspector sheet works at minimum with retained state; Ctrl-Cmd-S
  restores sidebar + widens 560→700. Open question: Ctrl-Cmd-S with the
  inspector sheet open showed no observable change (1 trial).
  VoiceOver spot-check untested (no VO harness in this session).

Remaining gaps (not hidden): About-expand capture, true pointer-drag,
VoiceOver, transfer-case protocol runs, held-out rotation scoring.
Privacy: all evidence frames are fixture-window pixels only; captures
containing desktop content were deleted, never committed.

## Transfer cases — all scored (2026-09-16, this host)

Four dedicated fixture apps (same conventions: `--dump-geometry`,
seeded/aligned flags, deterministic entries) close the protocol:

- **Case 1 settings (SettingsFixture): PASS.** Default + minimum widths
  × base + long locales: control column holds in all four cells
  (162.0/174.0 instrumented; screenshot differentials pixel-exact);
  wrapping/row-growth/system sizes excluded; zero file modifications.
- **Case 2 editor (EditorFixture): PASS.** Narrow (700): fixed 300pt bar
  overflows the 200pt inspector pane (instrumented + slider visibly cut)
  → FAIL as expected; aligned wraps fit. Inspector never collapsed; nav
  optionality untouched.
- **Case 3 workspace (WorkspaceFixture): PASS.** Narrow (560): 460pt
  transport exceeds the 410pt viewport with Snap clipped off-window, no
  declared outer scroll → FAIL as expected; aligned fills the viewport in
  the declared ScrollView with all six buttons AX-exposed. Caveat:
  synthetic wheel events did not move the scroller (harness limit).
- **Case 4 utility (UtilityFixture): PASS.** Fixed 320×200 refuses
  resize; all controls visible; Start AX-click fires observably. No
  matrix/collapse/overflow demanded; no-resize N/A justified.
- **Case 5 adversarial (AdversarialFixture): PASS, blinded.** A fresh
  agent with only skill + contract (162) + measurements (174/174/174/162)
  failed the majority with exact math, passed the minority, refused to
  re-baseline, modified nothing (`.audit/case5-blind/report.md`).

## Follow-up findings from the scoring campaign

- **True pointer-drag boundary: PASS.** Quartz-driven right-edge drag
  toward 200 clamps at 560 wide; bottom-edge drag clamps at 502 frame
  height; drag-back restores. Same `windowWillResize` path as the
  programmatic resizes — the S8 verdict now rests on real drags.
- **Keyboard: shortcuts/Escape/Return proven** (Ctrl-Cmd-S restores +
  widens; Escape and Return dismiss sheets). Table arrows N/A (no
  selection model). **Tab order undetermined**: 50+ guarded Tabs never
  leave the table outline — consistent with either Full-Keyboard-Access
  off (system default unreadable without changing user settings) or a
  focus trap; no app-side focus blockers exist in source (the two
  `allowsHitTesting(false)` hits are the hidden sizing probes, correctly
  excluded), and every contracted control exposes proper AX roles +
  labels. VoiceOver live announcement untested (would hijack the shared
  machine's audio/keyboard; needs a dedicated session).
- **About-disclosure anomaly (open):** 12 verified synthetic clicks
  (chevron, label center, double-click) never expand the compact About
  disclosure while all other controls respond; the label has a normal
  87×15pt frame (instrumented) and stays AX-absent despite explicit
  label/combine/button-traits attempts. One human click settles
  tap-bug vs synthetic-quirk; AX exposure needs structural a11y work.
  S7 stays conditional-pass on this sub-item only.
- **Ctrl-Cmd-S with inspector sheet open** showed no observable change
  (1 trial); restores fine without the sheet. Open, needs a retest.
- Screenshots cannot prove title contracts at 0.5pt: first-glyph ink
  bearings differ ~9px between T/A/P at large-title size — numbers must
  come from instrumented frames, screenshots are state evidence.
