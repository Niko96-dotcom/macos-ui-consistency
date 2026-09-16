# Consistency Fixture

Small real native macOS SwiftUI fixtures for the macOS UI consistency skill.
SwiftUI + AppKit only, no packages. Deterministic local in-memory data only —
no accounts, files, or network.

Two targets share one package:

- `ConsistencyFixture` — browser family (Tracks / Albums / Playlists sidebar
  + detail pane). See below.
- `SettingsFixture` — settings family (single form, Grid label/control
  columns, no sidebar/inspector/envelope). See [Settings fixture](#settings-fixture-second-family-probe).

## Sources (relative paths)

- `fixture/Package.swift` — SwiftPM manifest (tools 5.9, macOS 13, executable `ConsistencyFixture`).
- `fixture/Sources/ConsistencyFixture/main.swift` — app: `NSApplication` delegate +
  `NSHostingView`, sidebar (Tracks / Albums / Playlists), detail pane with
  app-owned content header titles, compact inspector, Info sheet.
- `fixture/README.md` — this file.
- `evals/scenarios.md` — audit/fix challenge prompts (not yet run).

## Build and run (exact commands)

Run from the repository root:

```sh
swift build --package-path fixture
swift run --package-path fixture ConsistencyFixture
```

Launch on a specific page (default `tracks`):

```sh
swift run --package-path fixture ConsistencyFixture --page albums
swift run --package-path fixture ConsistencyFixture --page playlists
```

Reference mode (seeded defect removed, screenshots only):

```sh
swift run --package-path fixture ConsistencyFixture --aligned
swift run --package-path fixture ConsistencyFixture --page playlists --aligned
```

Compact startup (minimum content size, for verification without resizing):

```sh
swift run --package-path fixture ConsistencyFixture --compact
swift run --package-path fixture ConsistencyFixture --page tracks --compact
```

Deterministic state entry points (test-only; same states as the
equivalent taps/resizes, no behavior change):

```sh
swift run --package-path fixture ConsistencyFixture --inspector-open
swift run --package-path fixture ConsistencyFixture --content-width 860 --inspector-open
swift run --package-path fixture ConsistencyFixture --content-width 700
```

`--inspector-open` starts with the inspector shown.
`--content-width=N` / `--content-height=N` start at a custom content size
(clamped to the policy minimum). Useful widths: 860 with inspector (compact
band), 700 with sidebar (compact band), 560 (collapsed minimum).

Instrumented geometry (fixture test tooling, not skill support):

```sh
swift run --package-path fixture ConsistencyFixture --page playlists --dump-geometry
swift run --package-path fixture ConsistencyFixture --content-width 860 --inspector-open --dump-geometry
swift run --package-path fixture SettingsFixture --dump-geometry
```

`--dump-geometry` prints layout frames (`geometry <id> x=.. y=.. w=.. h=..`,
detail-pane points for the browser fixture, grid points for settings) after
a 1.0s settle, then exits. Background readers never affect layout; the
unscrolled initial state is dumped. Tagged: `page-title-*`,
`compact-shuffle/sort/more-*`, `settings-control-*`,
`settings-help-default-view`. Precision is exact layout values; use 0.1pt
reporting uncertainty to cover pixel rounding. This does not replace
screenshots: it verifies the source-to-layout chain, not rendered pixels.

Layout diagnostics (window sizes only, no private data, for coordinator checks):

```sh
swift run --package-path fixture ConsistencyFixture --layout-diagnostics
swift run --package-path fixture ConsistencyFixture --compact --layout-diagnostics
```

With `--layout-diagnostics`, startup prints `layout-diagnostics` (content/frame,
`contentMinSize`/`minSize`, policy content/frame minima, thresholds), a
`post-makeKey` line re-checks host/toolbar overwrites once (re-asserts if below
policy, no loop), and every interactive resize prints a `layout-resize` line
with proposed/clamped, current frame/content, `minSize`/`contentMinSize`, and
policy/robust minima for coordinator stdout collection.

Window: titled `Consistency Fixture`, initial content 1000×650 (or 560×450
with `--compact`), minimum content 560×450 enforced after host install via
`contentMinSize` (content semantics, takes precedence) plus derived frame
`minSize` (frame including titlebar) **plus `windowWillResize` delegate clamp
of the proposed frame** (`frameRect(contentMin)` vs currently reported
`minSize`/`contentMinSize`, max wins, return-only, no `setFrame` loop), so a
real interactive drag cannot shrink below 560×450 content. Resizable, no frame persistence
(no autosave/restoration), with app + View (Toggle Sidebar) menus including Quit.
Content stays within that size: nothing raises the minimum or enlarges
the window to fit. `minSize`/`contentMinSize` declaration alone before/after
`contentView` is not enforcement (host/toolbar layout can overwrite after
`makeKey`; overwrite ordering alone is not claimed as proven root cause).
Width budget (content): sidebar 150 + detail compact-min 320 (=471) and
+ inspector 180 (=652); inspector defers below 860, sidebar collapses below
700 to preserve content first, hard stop 560 sits below collapse so the
collapsed state is seen before the minimum. Height minimum 450 fits header +
controls + 220 list with outer scroll. Visibility is derived live (no resize
loop); widening restores per user preference. Drag-test the hard stop manually;
source scans cannot prove it.

## Layout / viewport policy (compact 560×450 stays reachable)

- Detail page scrolls vertically as one unit, so header, subtitle,
  description, controls, and list remain reachable at 560×450 with deferred
  inspector (inspector defers below 860 rather than squeezing content).
  A known limitation on macOS 26: long description
  text can truncate with the inspector open at wider widths where it is still
  shown. This is
  not a clean text-wrapping negative control; record it separately in audits.
- Each Table/List keeps an explicitly bounded 220pt-tall viewport and
  scrolls internally; the fixed height never forces the outer row beyond
  host bounds (previous `minHeight(220)` did).
- Deliberate compact fallback (fit-driven by measured control-row width, no device checks):
  wide row first, compact group second. Compact uses a `Grid` with aligned
  label/control columns (no arbitrary offsets), native readable sizes (no
  scaling/shrinking), `Picker(.menu)` for Sort (no segmented indent), and a
  labeled `More` menu (`menu-more-*`) in its own `GridRow` with an empty label
  cell so Sort popup and More control leading edges align with the Shuffle
  control column (native internal title/glyph padding may differ; no offsets).
  It holds Show Inspector / Info with the same identifiers. Shared
  Toggle/Picker/Button pieces are reused in both branches (no duplicated giant
  layouts). Shuffle/sort state lives in
  `ContentView` so page changes, resizes, and branch switches never reset it.
- Sidebar is constrained to 150–180pt (ideal 170); inspector is 180pt and
  vertically scrollable. Outer `HStack` is bounded to host bounds. Adaptive
  policy: inspector defers below 860pt content width (requested narrow shows
  the same inspector in a native `inspector-sheet` with shared Volume state,
  restores as pane on widen; Show/Hide stays in regular row and compact
  More menu, no silently disappearing toggle), sidebar auto-collapses below
  700pt (retains user preference in
  `SidebarPreference`, restores on widen; `button-toggle-sidebar` toolbar and
  View menu Toggle Sidebar (Ctrl-Cmd-S) share one effective-visibility toggle:
  Hide only when effectively visible, otherwise Show with widen-to-reveal when
  narrow, and `nav-page-picker` menu picker keeps nav
  reachable whenever sidebar is not visible by intent or constraint). Hard-stop content minimum is 560×450, below the
  collapse point. Test default `swift run --package-path fixture
  ConsistencyFixture` and minimum `swift run --package-path fixture
  ConsistencyFixture --compact` plus a manual drag to the hard stop.

## Header envelope (vertical stability across sibling pages)

- Detail header uses a shared width-dependent, content-derived
  `DescriptionEnvelope` over all sibling descriptions (visible copy plus
  hidden accessibility-excluded sizing references, same font/wrapping).
  Envelope height is the live max at the current width, so the short Tracks
  copy (one line) reserves the same space as longer Albums/Playlists copy
  (two lines) at that width. Controls baseline, divider, and body start stay
  stable across Tracks/Albums/Playlists at the same width.
- Envelope applies to the regular variant only (wide row). The compact
  variant intentionally does not reserve envelope space above controls:
  controls sit directly below the subtitle (controls top stable, no huge
  blank), and the full description moves to the shared below-controls
  `DisclosureGroup("About this view")` (`disclosure-about-*`, content keeps
  `page-description-*`, wrapped, not truncated). Collapsed height is stable
  across siblings; expanded height is user-initiated and documented. Full
  text remains discoverable without blanket-hiding.
- No hardcoded header height/line count, no truncation, no shortened copy, no
  per-page offsets, no historical max cache. Narrow widths and inspector-open
  re-resolve live; no stale height on resize.
- Wrapped copy length itself remains intentional; only downstream drift of
  shared shell anchors (controls/divider/body top) is treated as a defect.
- Deliberate +8pt Playlists title seed is preserved here (coordinator's
  runnable copy removes it separately). Table-vs-List internal differences and
  system chrome are preserved.

## Seeded vs aligned

- **Seeded (default):** the Playlists content title uses 32pt leading
  (shared 24pt inset + deliberate 8pt extra via `ContentLayout.playlistTitleExtraLeading`).
  Tracks and Albums titles use the shared 24pt inset. This is the **one genuine
  main defect**.
- **Aligned (`--aligned`):** the flag sets that shared policy value's extra to 0,
  so all three titles read 24pt. It exists only to produce reference screenshots.
  It is **not** proof that a skill auto-repaired anything; a real fix must edit
  the source and re-verify.

## What counts as the keyline

- The measured keyline is the **app-owned content header title inside the detail
  pane** (the large `Tracks` / `Albums` / `Playlists` text), identified by
  `page-title-tracks|albums|playlists`.
- The **system window title** (`Consistency Fixture` in the titlebar) is native
  chrome and is **NOT** the content keyline. Never reposition the native
  titlebar/toolbar or claim it as an alignment fix.
- System chrome is untouched by this fixture.

## Intended variants (do not "fix")

- Long / wrapping descriptions and different content text lengths per page
  (see the compact-width limitation above).
- Deliberate compact composition (control-fit fallback): `Grid`-aligned
  Shuffle/Sort columns with `More` in its own `GridRow` (empty label cell),
  native menu Sort picker, `More` menu for secondary
  actions, and below-controls `About this view` disclosure holding the full
  description. Cramped mixed stacks (misaligned labels, indented segmented
  label, buttons crammed below a blank) are not this variant; the declared
  variant above is the pass target at 560×450 (inspector deferred) and at
  wider widths with the 180pt inspector where still shown.
- Compact inspector (`inspector-pane`): tighter spacing, smaller type, different
  family — excluded from any content-title contract. It scrolls vertically
  if needed at short heights.
- Clean native controls (Toggle, segmented Picker in regular / menu Picker in
  compact, Slider, Table/List) and modest SF Symbols. No decorative
  cards/pills. No scaling/shrinking of controls, no arbitrary offsets to align
  native labels, no globally forced equal heights, no native chrome moves.
  Narrow widths use the declared compact composition above; that deliberate
  reflow is expected, not a defect.

## Accessibility identifiers (stable, no runtime exporter)

Page titles (`page-title-*`), subtitles, descriptions (`page-description-*` in
regular envelope or compact disclosure), bodies (`page-body-*`),
page buttons (`page-button-*`), `button-toggle-sidebar`, `nav-page-picker`
(whenever sidebar is not visible), `button-toggle-inspector`, `button-show-info`,
compact `menu-more-*` and `disclosure-about-*`,
`button-close-info`, `info-sheet`, `inspector-pane`, `inspector-sheet` and
`button-close-inspector-sheet` (narrow deferred sheet sharing inspector Volume). There is no runtime
measure exporter and no fabricated geometric evidence in this fixture.

## Static tests note

No automated UI tests are bundled with this fixture and no test results are
claimed here. Static/source-only scans supplied separately cannot prove
runtime geometry. Passing a source scan is not a visual pass. Any alignment
claim requires captured screenshots (or manual measurement) mapped to a
declared contract before/after the change.

## Settings fixture (second-family probe)

A minimal settings form proving the skill transfers beyond the browser
family. No sidebar, no inspector, no header envelope, no divider/body
anchors — the shared contract is Grid label/control columns only.

- `fixture/Sources/SettingsFixture/main.swift` — app: `NSApplication`
  delegate + `NSHostingView`, one `Grid` form (Theme / Default view /
  Show notifications / Cache size), help text locked to the control
  column, long-locale copy variant.
- Declared contract (app-decision, `settings/regular`, pane-local):
  every control leading == 162pt (`labelColumnWidth` 150 + `columnGap`
  12) ± 0.5.
- **Seeded (default):** the notifications Toggle adds +12pt extra leading
  (`SettingsLayout.notificationsExtraLeading`), so it reads 174pt
  against the 162pt contract. This is the **one genuine defect**.
- **Aligned (`--aligned`):** the extra is 0; all four controls read 162pt.
  Reference mode only, not repair proof.
- **Long locale (`--long-locale`):** longer label/help copy. Wrapping and
  row-height growth are expected intentional variants; columns must hold.
- **Contract print (`--print-contract`):** prints declared values and
  exits before launching any UI. Declared inputs only, never measured
  geometry.

```sh
swift build --package-path fixture
swift run --package-path fixture SettingsFixture
swift run --package-path fixture SettingsFixture --aligned
swift run --package-path fixture SettingsFixture --long-locale
swift run --package-path fixture SettingsFixture --print-contract
swift run --package-path fixture SettingsFixture --layout-diagnostics
swift run --package-path fixture SettingsFixture --dump-geometry
```

Window: titled `Settings Fixture`, initial content 480×360, minimum
content 400×300. Intended variants (do not "fix"): long-locale wrapping,
row-height growth, help-text length. There is no runtime measure
exporter and no fabricated geometric evidence in this fixture.

Accessibility identifiers: `settings-label-*`, `settings-control-*`
(`theme`, `default-view`, `notifications`, `cache`), plus
`settings-help-default-view`.
