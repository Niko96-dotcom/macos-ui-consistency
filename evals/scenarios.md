# Evaluation scenarios (not yet run)

These prompts exercise the macOS UI consistency skill against the fixture.
**None of these scenarios have been executed or scored yet; do not claim
results until a run is performed and evidence is recorded.**

Fixture entry: `fixture/Sources/ConsistencyFixture/main.swift`.
Build: `swift run --package-path fixture ConsistencyFixture`.
Reference: `fixture/README.md` for seeded vs aligned semantics.

## 1. Audit-only (no mutations)

**Prompt:** "Audit the fixture for app-owned content-title leading consistency
across Tracks, Albums, and Playlists. Do not modify any files. Report findings
with surface ids, expected vs actual, evidence screenshots, and uncertainty.
Treat the native titlebar as out of scope and the compact inspector as a
different family."

**Setup:** launch default (seeded) build; capture one screenshot per page
(`--page tracks|albums|playlists`); contract expects 24pt pane-local title
leading for family `browser`, variant `regular`.

**Evaluation criteria:**

- Pass: reports Playlists ≈32pt vs 24pt expected (FAIL vs contract) and
  Tracks/Albums ≈24pt (PASS), with per-surface evidence paths, pane-local
  coordinate space, and non-zero or justified uncertainty.
- Fail: edits any file, repositions native chrome, flags wrapped copy length or
  inspector compactness as defects, or claims exhaustive app coverage.
- Audit-only respected: zero file modifications (verify via `git status`).

## 2. Explicit fix with before/after verification

**Prompt:** "Fix the demonstrably accidental Playlists content-title leading so
all three pages share the 24pt app-owned inset. Verify with before/after
screenshots under the same window size and contract."

**Setup:** seeded build first (before screenshots), then agent edits
`fixture/Sources/ConsistencyFixture/main.swift` (the
`playlistTitleExtraLeading` policy), rebuilds, captures after screenshots.

**Evaluation criteria:**

- Pass: single source change removing only the +8pt extra; Tracks/Albums
  untouched; inspector, copy length, and system chrome untouched; before/after
  evidence shows 32→24 on Playlists with unchanged 24 on the others;
  comparison summary has no fail/unverified for the three in-scope surfaces.
- Fail: normalizes intended variants, touches titlebar/toolbar, uses
  `--aligned` output as "proof" without a source fix, or reports without
  re-captured after evidence.

## 3. Source-only (must stay unverified)

**Prompt:** "Given only `fixture/Sources/ConsistencyFixture/main.swift` and no
ability to launch the app or capture screenshots, assess title-leading
consistency."

**Setup:** no app launch, no screenshots; agent may use static scan output only.

**Evaluation criteria:**

- Pass: returns candidate-level findings with status UNVERIFIED, states that
  source-only evidence cannot prove runtime geometry, lists the shared policy
  value and the Playlists extra as the suspect with file/line references.
- Fail: claims PASS/FAIL on runtime geometry from source alone, fabricates
  pixel values or screenshot evidence, or asserts full coverage from regex.

## 4. Inaccessible sheet (blocked evidence)

**Prompt:** "Audit all pages including the Info sheet content. If any surface
cannot be captured (e.g., sheet dismissed, window occluded), record it honestly."

**Setup:** seeded build; attempt Info sheet capture on each page; simulate one
blocked case (e.g., sheet not opened on Albums, or screenshot occluded).

**Evaluation criteria:**

- Pass: captured surfaces carry evidence; the blocked sheet surface is recorded
  with status `blocked` + reason, yielding an UNVERIFIED (not PASS, not FAIL)
  finding for that pair; exit/status rules for unverified are followed.
- Fail: substitutes another page's screenshot, invents evidence paths, marks
  blocked as pass, or silently drops the surface.

## 5. Intended-variant challenge (must not "fix")

**Prompt:** "The report notes three differences: (a) Playlists title inset,
(b) longer wrapping descriptions on Albums/Playlists, (c) compact inspector
with tighter spacing. Align everything that looks inconsistent."

**Setup:** seeded build with contract covering only role `contentTitle`,
metric `leading`, family `browser`, variant `regular`.

**Evaluation criteria:**

- Pass: fixes only (a) as accidental (shared-policy defect); explicitly
  excludes (b) wrapped-copy length and (c) inspector compactness with reasons
  (intended variant / different family); system chrome untouched.
- Fail: rewrites copy to equal lengths, restyles inspector to match detail
  padding, or moves the native titlebar/toolbar. Any of these is an
  over-normalization failure even if (a) was fixed.

## 6. Header-envelope vertical stability (shortest vs longest)

**Prompt:** "Verify Tracks (shortest, one-line description) vs Albums/Playlists
(longest, two-line) keep controls baseline, divider, and body start stable at
the same width. Check default and narrow widths, inspector closed and open,
both navigation orders (Tracks→Albums and Albums→Tracks), plus resize after
measurement to prove no stale height. Do not hardcode heights, truncate,
shorten copy, add per-page offsets, or cache a max."

**Setup:** fixed build with shared width-dependent content-derived description
envelope; capture per-page screenshots (or pane-local manual measures) at same
width/environment for each combination; record window size, inspector state,
navigation order, and post-resize re-measure.

**Evaluation criteria:**

- Pass: controls row, divider, and body top match across siblings within
  tolerance at each width/inspector state, both orders, and after resize;
  copy length and Table-vs-List internals untouched; system chrome untouched.
- Fail: only title leading checked, one width or inspector state missing,
  stale height after resize, or any hardcoded height/line count, truncation,
  shortened copy, per-page offset, or cached max.
- Validation is screenshot/manual evidence only; no automated tests claimed.

## 7. Deliberate compact composition (no accidental stacking)

**Prompt:** "Verify the compact variant is deliberate composition, not
accidental stacking. At 560×450 (inspector deferred) and at wider widths
with the inspector where still shown, check
Tracks (shortest) vs Albums/Playlists (longest): controls sit directly below
the subtitle with no huge reserved blank; Shuffle/Sort form an aligned
label/control group (Grid, no arbitrary offsets) with a native menu Sort
picker at readable size; secondary Inspector/Info live in a labeled More
menu; the full description lives in the shared below-controls About disclosure
(wrapped, expandable, not truncated or blanket-hidden). Check both resize
directions, both navigation orders, and that shuffle/sort survive
navigation/resize. Do not move native chrome, force equal heights, shrink
controls, or touch the seeded +8 Playlists title."

**Setup:** `--compact` (560×450, inspector deferred) plus manual resize to 1000×650 and back;
inspector closed and open where applicable; per-page screenshots (or pane-local manual
measures) at each width/inspector state; record navigation order and
post-resize re-measure; keep seeded Playlists +8 intact.

**Evaluation criteria:**

- Pass: regular shows envelope + wide row with stable controls/divider/body
  per width; compact shows Grid-aligned labels, menu Sort with visible
  selection, More menu with both actions reachable (same identifiers/focus),
  Disclosure collapsed stable with full wrapped text on expand, controls top
  stable with no huge blank, state preserved, no offsets/scaling/global
  heights/chrome moves; evidence paths per surface/state recorded.
- Fail: huge blank above compact controls, misaligned/indented Sort label,
  crammed buttons below, truncated or missing description, unreachable action
  or selection, reset state, or any hardcoded height/offset/scale/chrome move.
- Validation is screenshot/manual evidence only; no automated tests claimed
  and no pass without re-captured evidence.

## 8. Sizing envelope and boundary proof (no source-only pass)

**Prompt:** "Establish the usable sizing envelope before judging spacing.
At normal (1000×650), compact (560×450 startup via --compact, policy
minimum), 700pt sidebar-collapse boundary, and narrowest (drag
beyond minimum and release back, both directions), with sidebar ×
inspector (closed/closed, open/closed, closed/open, open/open) and both
navigation orders, prove: no clipped primary control, no horizontal
outer-page scroll, declared primary task stays operable (in this
fixture sidebar yields before detail), compact Sort value and
More alignment hold against the declared control column (not content
leading or table gutters). Do not claim a fix from source declaration.
Note: the fixture sets `minSize` before installing the hosting view in
`main.swift`; rendered tiny-window clipping is confirmed, but that
ordering as cause is hypothesis until runtime-tested. Better fixture
implementation is owned by another worker — do not invent its outcome."

**Setup:** live resize (not startup-compact only); per-page screenshots
or pane-local manual measures at each state/combination/direction/order;
record window content vs frame size, scale, inspector/sidebar state,
scroll, locale.

**Evaluation criteria:**

- Pass: matrix covers normal/compact/narrowest × four sidebar/inspector
  combos × both directions/orders with evidence paths; narrowest shows
  operable controls, reversible collapse with button+menu+shortcut
  fallback, Grid-aligned Sort/More against control column, About holds
  full wrapped text; unmeasured combos marked `unverified`/`blocked`
  with reasons, never pass.
- Fail: startup-compact only, one direction only, missing inspector
  combo, source-declaration claimed as pass, universal window number
  asserted, Apple auto-collapse mandate claimed, comparison-app pixels
  treated as requirements, or every differing edge flagged without
  control-column vs gutter distinction.
- Validation is screenshot/manual evidence only; no automated tests claimed.

## Acceptance matrix (measurable, same width/environment)

- No clipped primary control at narrowest supported width AND height.
- No horizontal outer-page scroll; inner Table/List viewport scrolls.
- Sidebar yields before detail in this fixture's browser family
  (prioritize the declared primary task); any collapse reversible via persistent
  accessible fallback.
- Compact: no huge blank above controls; Sort value visible; More holds
  all secondary actions with same identifiers/focus; state survives
  resize/navigation.
- Controls/divider/body anchors match across siblings within tolerance.

## Negative controls (must stay excluded)

Wrapped-copy length, Table-vs-List internals, inspector compact density,
native titlebar/toolbar/traffic lights, system text-style sizes. Fixing
any of these is an over-normalization failure.

## Held-out strategy

- Keep one page's expected value and one tolerance out of the prompt (e.g.,
  withhold the Playlists 32pt sample and the 0.5pt tolerance) and reveal them
  only at scoring time, so agents must measure rather than recall.
- Rotate which surface is `blocked` in scenario 4 between runs.
- Use a fresh screenshot directory per run; forbid reuse of `--aligned`
  screenshots as before/after proof (timestamp and flag check).
- Score evidence quality separately: screenshot exists, shows the named
  surface, and matches the declared environment (`fixture-regular`).

## Scoring note

Record per-scenario pass/fail plus the comparison-summary counts
(pass/fail/unverified/excluded). An empty contract/measurement set is never a
pass. Uncertainty handling (overlap → unverified) must be checked on at least
one borderline measurement before marking any scenario complete.
