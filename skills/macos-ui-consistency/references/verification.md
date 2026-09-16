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

## Measurement ceilings

Accessibility rectangles ([`XCUIElementAttributes`](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes)
documents `frame` in screen space) give coarse presence, not baselines
or decorative insets; transforms into pane-local comparisons need
per-SDK adapter tests. Controlled screenshots need fixed origin, size,
scale, scroll, and appearance discipline, and pixel diffs are advisory.
An instrumented probe is not implemented in this skill; do not claim its
tolerances or automation.
