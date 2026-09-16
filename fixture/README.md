# Consistency Fixture

Small real native macOS SwiftUI fixture for the macOS UI consistency skill.
SwiftUI + AppKit only, no packages. Deterministic local in-memory data only —
no accounts, files, or network.

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

Window: titled `Consistency Fixture`, initial content 1000×650 (or 700×450
with `--compact`), minimum 700×450, resizable, no frame persistence
(no autosave/restoration), with a normal app menu including Quit.
Content stays within that size: nothing raises the minimum or enlarges
the window to fit.

## Layout / viewport policy (compact 700×450 stays reachable)

- Detail page scrolls vertically as one unit, so header, subtitle,
  description, controls, and list remain reachable at 700×450 with or
  without the inspector. A known limitation on macOS 26: long description
  text can truncate with the inspector open at minimum width. This is
  not a clean text-wrapping negative control; record it separately in audits.
- Each Table/List keeps an explicitly bounded 220pt-tall viewport and
  scrolls internally; the fixed height never forces the outer row beyond
  host bounds (previous `minHeight(220)` did).
- Narrow-width control fallback stacks Toggle and Picker on separate lines
  (buttons on their own row) so the Shuffle label stays visible.
- Sidebar is constrained to 150–180pt (ideal 170) so the inspector
  (180pt, vertically scrollable) does not squeeze the detail pane
  unusably narrow. Outer `HStack` is bounded to host bounds.

## Header envelope (vertical stability across sibling pages)

- Detail header uses a shared width-dependent, content-derived
  `DescriptionEnvelope` over all sibling descriptions (visible copy plus
  hidden accessibility-excluded sizing references, same font/wrapping).
  Envelope height is the live max at the current width, so the short Tracks
  copy (one line) reserves the same space as longer Albums/Playlists copy
  (two lines) at that width. Controls baseline, divider, and body start stay
  stable across Tracks/Albums/Playlists at the same width.
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
- Compact inspector (`inspector-pane`): tighter spacing, smaller type, different
  family — excluded from any content-title contract. It scrolls vertically
  if needed at short heights.
- Clean native controls (Toggle, segmented Picker, Slider, Table/List) and
  modest SF Symbols. No decorative cards/pills. Narrow widths reflow
  controls vertically; that reflow is expected, not a defect.

## Accessibility identifiers (stable, no runtime exporter)

Page titles (`page-title-*`), subtitles, descriptions, bodies (`page-body-*`),
page buttons (`page-button-*`), `button-toggle-inspector`, `button-show-info`,
`button-close-info`, `info-sheet`, `inspector-pane`. There is no runtime
measure exporter and no fabricated geometric evidence in this fixture.

## Static tests note

No automated UI tests are bundled with this fixture and no test results are
claimed here. Static/source-only scans supplied separately cannot prove
runtime geometry. Passing a source scan is not a visual pass. Any alignment
claim requires captured screenshots (or manual measurement) mapped to a
declared contract before/after the change.
