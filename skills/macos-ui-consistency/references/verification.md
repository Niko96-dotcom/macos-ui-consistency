# Verification, repair eligibility, and convergence

Metrics catch drift; inspection catches hierarchy, optical balance, and
material behavior. Visual review stays mandatory. Normative schemas and
the comparator's pass/fail/unverified math live in
[data-format.md](data-format.md) (tooling-owned); this file states how the
agent works with them.

## Evidence levels

- **Measured:** geometry plus identified source cause.
- **Observed:** screenshot or manual evidence without tight geometry.
- **Inferred:** heuristic or source-only hypothesis.

Record the level separately from severity. Severity applies to issues
only, never to untested areas. Every finding records location, state,
and conditions (window size, appearance, locale, fixture,
sidebar/inspector, scroll, active state) and separates observation from
inference. Values stay null where unknown; never invent precision.

Source-only work is always inferred or observed at best. It may propose
a patch but cannot claim a visually verified fix.

## What the CLI proves (and does not)

- `scan` outputs heuristic candidates with limitations listed. It proves
  nothing about coverage and never edits the app.
- `compare` checks declared numeric metrics in supplied contracts and
  measurements only. It does not judge screenshots, semantics, grouping
  taste, or unlisted surfaces. Empty inputs never report green; missing
  evidence, mismatched units, spaces, or environments, and blocked or
  unvisited surfaces resolve to unverified, and system-owned or
  cross-family pairs are excluded by declaration.
- `report` renders a deterministic human-readable view of a comparison.
  It claims no exhaustive app coverage.

Exit behavior to plan for: clean pass exits 0; any fail exits nonzero as
a failure; unverified without fail is its own non-green outcome; invalid
input or I/O is a usage error, never silent success. Baselines are never
silently approved to quiet a failure.

## Automatic repair eligibility

Default on invocation: audit plus automatically fix eligible clear
inconsistencies within current user authorization when all of these hold —

- an applicable app contract already exists, or the violation is directly
  demonstrated as accidental in an existing shared component;
- the exact app-owned location is known;
- the change alters no semantics, behavior, API, or persistent data;
- all consuming surfaces are known in the registry (dependency closure);
- verification capability suffices (before-evidence exists and
  after-evidence is capturable).

Excluded from automatic repair: heuristic grouping or taste calls,
choosing a new meaning for a control, shell extraction solely to
homogenize, public-API or data-model effects, and cross-family
unification. Those need an explicit user decision on scope and meaning.
Clear existing conventions evident in the app and routine scoped
decisions needed to record and apply them may be derived and recorded
without asking; ask only where material ambiguity about design intent,
semantics, or scope remains. Frequency or majority alone never justifies
a fix. Never infer a heuristic taste call as sufficiently certain just
to fix it. Explicit audit-only, review, or planning requests prohibit
every mutation; never expand an ordinary review request into fixes.

## Repair flow

Candidate → before-evidence → patch → build plus focused behavior and
visual checks → accepted or failed/unverified. Before/after observations
gate fixes, not numeric confidence scores.

- Fix once in the shared shell, component, or value; all pages converge.
- Re-measure every consumer in the same family plus known cross-family
  reusers, at default and narrow widths, and confirm intentional
  differences still pass.
- Preserve keyboard focus, accessibility order, and interaction; preserve
  unrelated work; undo only owned changes when safe, else report the
  exact partial state. A failed repair never counts as fixed.
- Second normalization pass on an unchanged app must yield zero diffs
  (convergence). Repeat runs are deterministic: same fixture, registry,
  and prescription yield the same report, and window moves do not alter
  pane-relative geometry.
- Never silently re-baseline snapshots or references to silence a
  failure. Intentional differences live in the exceptions allowlist with
  scope, expiry, and rationale, and a good-difference suite must fail the
  run if flagged.

## Cross-page validation (coordinator handoff)

Do not declare cross-page alignment from one anchor alone. Inventory and
compare the declared shared shell anchors for that page family at the same
width and environment (for example, a browser family might declare
title/subtitle, header envelope, controls baseline, divider, and body
start; other families declare their own roles). An
explicit narrow-scope report (e.g., title leading only) cannot imply
whole-page verified.

## Window-boundary proof (no source-only pass)

Source declaration never passes. Startup-compact alone never proves the
boundary. Required runtime matrix per sibling page:

- states: normal (default) + compact + narrowest (drag beyond declared
  minimum where the platform permits, then release back); declared
  fixed-size windows record N/A with justification instead of a resize
  matrix;
- applicable pane combinations only (where the app has collapsible
  side/inspector panes, test closed/closed, open/closed, closed/open,
  open/open at app values); do not require panes an app does not have,
  and do not assume every pane is optional/collapsible — an inspector
  may be an essential editor and a side pane may be primary, per
  declared task priority;
- both resize directions (wide→narrow, narrow→wide) and both navigation
  orders (shortest→longest, longest→shortest) with post-resize re-measure
  to catch stale height/branch, where resizing applies;
- keyboard + VoiceOver spot-check in compact (same identifiers/focus,
  reachable overflow actions, visible selection value, no arbitrarily
  scaled controls; native small/mini sizes in context remain allowed).

Unmeasured combinations stay `unverified` with explicit coverage status
(pass/fail/unverified/excluded + reason). Current findings test limits;
a green subset never implies the untested remainder.

## Negative controls and acceptance matrix

Negative controls (must stay excluded when declared intentional, never "fixed"):

- wrapped-copy length differences; internal gutter differences only where
  the semantic contract declares them intentional (never exempt by type
  alone); compact-pane density where declared a separate family; native
  titlebar/toolbar/traffic-light geometry; system text-style sizes.

Acceptance (all measurable, same width/environment unless stated):

- minimum usable (where resizing applies; fixed-size records N/A with
  justification): no clipped primary control, no horizontal outer-page
  scroll except where deliberately declared (for example a timeline
  workspace with constrained panes), no unreachable action at narrowest
  supported width AND height;
- task-priority-first (per declared task priority, never always-detail):
  controls for the declared primary task stay operable as the window
  narrows; any collapse applies only to panes declared optional/
  collapsible and is user-reversible with a persistent accessible
  fallback appropriate to app capabilities (do not universally require
  button + menu + shortcut);
- compact composition (per declared compact contract, no universal
  menu/disclosure mandate): hierarchy preserves meaning unless design
  intent reorders it; shared label/control/action columns hold where
  declared; selection value stays visible; every secondary action stays
  reachable; full secondary copy stays discoverable with wrapping; no
  arbitrary scaling to fit;
- stability: the declared shared-shell anchors match across siblings within
  tolerance at each tested state; selection and control state survives
  resize and navigation.

Coordinator validation needs (no automated tests claimed here): captured
screenshots or manual pane-local measurements per sibling page at the same
width, covering shortest vs longest header at app-declared default and
narrow widths, with applicable pane combinations closed and open, both
navigation orders, plus resize after measurement to prove no stale height.
Map each claim to its evidence and contract; unmeasured combinations stay
unverified.

## Measurement ceilings

Accessibility rectangles ([`XCUIElementAttributes`](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes)
documents `frame` in screen space) give coarse presence, not baselines
or decorative insets; transforms into pane-local comparisons need
per-SDK adapter tests. Controlled screenshots need fixed origin, size,
scale, scroll, and appearance discipline, and pixel diffs are advisory.
An instrumented probe is not implemented in this skill; do not claim its
tolerances or automation.
