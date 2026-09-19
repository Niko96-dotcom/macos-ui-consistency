# Window adaptation (macOS)

Resizing envelope first, spacing polish second. A resizable Mac window
must never clip primary controls at its narrowest supported size.
Official sources are linked inline below; this reference is
self-contained when installed.

## macOS vs iPad — do not conflate

- **macOS (this file):** freely resizable windows; split-view dividers;
  optional hide/reveal panes; `minSize` /
  `contentMinSize` enforcement
  ([HIG Windows](https://developer.apple.com/design/human-interface-guidelines/windows),
  [HIG Split views](https://developer.apple.com/design/human-interface-guidelines/split-views),
  [HIG Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars),
  [NSWindow minSize](https://developer.apple.com/documentation/appkit/nswindow/minsize) /
  [contentMinSize](https://developer.apple.com/documentation/appkit/nswindow/contentminsize)).
  No size-class-driven automatic sidebar swap. No Apple numeric window
  minimum. No automatic-collapse mandate.
- **iOS/iPadOS only:** horizontal/vertical size classes (compact/regular)
  describe available space; `sidebarAdaptable` tab style auto-responds to
  rotation/resize ([HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)).
  Do not apply to macOS audits.
- **visionOS min/max example** (1280×720 default in HIG Windows) is
  visionOS-only; never cite as a Mac requirement.

## Policy

1. **Task hierarchy.** Prioritize the declared primary task pane per app
    task priority (an inspector may be the essential editor; a side pane
    may be primary). Lower-priority panes yield only via declared compact
    composition, never by clipping primary controls.
2. **Width budget.** For each visible-pane configuration, the visible
    panes fit the content width at that configuration's threshold.
    At the smallest supported width only the remaining visible panes
    count; hidden or collapsed panes carry no budget. App-calibrated,
    never a universal number.
3. **Optional panes collapse/reveal — only where declared.** Where the app
   declares a pane optional/collapsible, it is user-collapsible and
   restorable via a persistent accessible fallback appropriate to app
   capabilities (do not universally require button + menu + shortcut).
   Never strand functionality in a hidden pane without such fallback.
   Do not assume every sidebar or inspector is optional; essential
   editors and primary side panes stay.
4. **Navigation fallback.** Where a pane is declared hidden/collapsible,
   keep navigation reachable by an app-declared mechanism. Hidden is a
   state with intent, not invisible-but-required. Do not require overflow
   menus or disclosures for every app.
5. **State intent vs constrained visibility.** Distinguish user-hidden
   (intent) from system-squeezed (constraint). Constraint must trigger
   the declared compact variant, not overlap or truncate.
6. **Supported minimum width AND height — where resizable.** Declare and
   test both. macOS Layout warns against bottom-edge reliance (windows
   moved offscreen; bottom bars hideable). Height must keep header,
   controls, and body reachable via scroll, not fixed overflow.
   Declared fixed-size utilities record no-resize with justification and
   N/A for the resize matrix.
7. **Content vs frame coords.** `minSize` = frame incl. title bar;
   `contentMinSize` = content view in base coords and takes precedence.
   Audit in pane-local/content-local points; points × scale = pixels.
   Never compare cross-scale pixels or screen-space frames directly.
   `XCUIElement.frame` is screen-space presence only.
8. **Fit transitions both directions.** Content-measured fit (for example
   `ViewThatFits` or equivalent), tested wide→narrow AND narrow→wide
   with applicable panes open/closed. One-way-only fallbacks fail.
9. **Keylines.** Define relational label/control/action columns where
   appropriate, separately from content/table internal gutters. Whether
   differing internals are intentional is decided by the declared semantic
   contract, never exempted by type alone; only drift of the declared
   shared column fails. Do not require one equal width across unrelated
   controls; do not mechanically align labels to button text glyphs — use
   native alignment geometry and group semantics. Equal frames can still
   misalign text: use baselines
   and `alignmentRectInsets` reasoning, not frame equality. Native
   ornament (segmented indent, menu chevron) never justifies an
   app-owned per-screen offset.
10. **Platform metrics vs app values.** Apple supplies control/type
    idiom (Mac push/square/help/image buttons; pop-up menus as
    space-efficient selectors; SF Pro conventions); the app supplies every
    inset, gap, and breakpoint. Never ship universal dimensions from
    this skill.
11. **Accessibility / keyboard / localization.** Preserve focus order,
    VoiceOver labels/identifiers, Return/Escape behavior, tooltips, and
    RTL reading order at every size. macOS has no Dynamic Type; test
    larger app text, longer locales, and keyboard-only reachability in
    the compact variant. Never use arbitrary visual scaling to hide a fit
   failure; native small/mini control sizes in their documented contexts
   remain allowed.
12. **Envelope before polish.** Establish and runtime-TEST the usable
    sizing envelope (minimum usable, compact threshold, default) before
    auditing 1pt spacing. Spacing verdicts below the envelope are
    invalid. Current-size observations can still be reported with their captured
    conditions while resize coverage remains explicitly unverified.

## What Apple does and does not require

- Apple **strongly recommends**: windows adapt fluidly
  ([Windows / Best practices](https://developer.apple.com/design/human-interface-guidelines/windows));
  layouts adapt gracefully
  ([Layout / Adaptability](https://developer.apple.com/design/human-interface-guidelines/layout)).
  Strong recommendation, still app-calibrated — not a legal requirement.
- Apple **suggests** (weak "Consider"): automatically hide or reveal the
  sidebar on resize
  ([Sidebars / macOS](https://developer.apple.com/design/human-interface-guidelines/sidebars));
  hide panes to reduce distraction
  ([Split views / macOS](https://developer.apple.com/design/human-interface-guidelines/split-views));
  pop-up button when space is limited
  ([Pop-up buttons](https://developer.apple.com/design/human-interface-guidelines/pop-up-buttons)).
  Optional — never cite as an automatic-collapse mandate.
- Comparison-app screenshots are inspiration only, never requirements.
- Do not label every differing edge "inconsistent". Only a declared
  relational contract violation fails. Distinct edges visible in a
  screenshot are a confirmed observation; whether the relation is
  undesired is an app/user decision against the declared control
  column, and needs runtime geometry — without it, mark unverified
  and claim no exact geometry.

## Audit procedure (summary; norm in verification.md)

Normal + compact + narrowest drag-beyond-minimum states where resizable;
applicable pane combinations; both resize directions; both navigation
orders (fixed-size utilities record N/A with justification).
Startup-compact alone never proves the boundary. Source declaration
alone never passes. Source-only work is useful for candidates but never
a runtime pass.
