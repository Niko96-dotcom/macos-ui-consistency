# Discovery and bounded inventory

Source-only text search cannot prove an app was fully seen. This reference
defines what counts as a surface and how the agent maintains honest,
persistent coverage without overstating it.

## What is a surface

A surface is any user-reachable visual unit that can drift on its own:
main and auxiliary windows, dialogs, sheets, popovers, inspectors,
sidebars, tabs, menus and commands, toolbars, onboarding/auth/permission
flows, and structurally distinct empty, loading, and error states of an
otherwise shared container.

A `View` file is not a surface. One view can host several surfaces; one
surface can compose many views. System-owned presentations (file panels,
system alerts) are navigation coverage only: noted as reachable, assigned
`owner: system`, never measured against app body keylines, never edited.

Only app-owned layout surfaces count toward the layout denominator. A focused
review names checked surfaces without implying a complete inventory.

## Build identity before traversal

Resolve the requested working tree and recent user changes before editing.
Record revision plus dirty state/build identity, executable path and process
being driven. If several builds share a name, target the intended process.
After rebuild/relaunch, confirm the evidence belongs to that artifact. Check
session availability and whether a window is reachable before treating absent
windows as a layout regression. Never change lock/security settings to test UI.

## Two-pass discovery for broad audits

**Pass A — static candidates.** Targeted search plus manual triage for
scene entry points (`WindowGroup`, `Window`, `DocumentGroup`, `Settings`,
`MenuBarExtra`), navigation destinations, selection-driven detail
branches, `.sheet` / `.popover` / `.inspector` / `.alert` /
`.fileImporter` presentations, `commands` / `CommandMenu`, context menus,
and AppKit-created windows and panels. Record feature flags, build
configs, entitlements, and auth or permission gates visible in code.

The sibling `scan` subcommand accelerates this pass. Treat its output as
heuristic candidate records (`confidence: candidate`) with file and line
hints, never as an inventory and never as coverage proof. Comments and
string literals must not become findings; multiline Swift forms are
handled conservatively. Line edits may shift candidate IDs; stable surface
IDs are curated separately in the inventory.

**Pass B — dynamic traversal.** From each relevant entry point, walk the
running app with reproducible steps. Open applicable windows and controls,
scroll populated content, and exercise the size and pane states that could
affect the audited relationships. Capture the route so another run can
repeat it. A broad coverage claim requires traversal of the full known
inventory; a focused finding needs its affected route and states.

**Reconcile explicitly:**

- in source but never reached: coverage gap or reasoned exclusion;
- reached at runtime but absent from the static set: inventory gap, add it;
- registered but absent from the build: stale entry, prune with a note.

## v1 bound

Manual curated manifest plus heuristic candidate scan. Cheap and
host-neutral. Explicitly not exhaustive static reachability and never
described as such.

## Persistent registry for broad or repeated audits (per-app data, outside the skill)

Use the app's existing audit location for a surfaces registry, contracts,
intentional exceptions, and evidence. Do not create a new top-level
`inventory/` directory for a focused task unless the app already uses one.
Suggested per-surface
record: stable ID, owner (`app` / `system`), source revision and build
config, route and prerequisites, family and variant, environment key,
status with reason, evidence refs.

Lifecycle: `discovered → reachable → captured → checked`, with terminal
`blocked (reason)` and `excluded (reason)`. Exclusion without a reason is
forbidden. Deleting an existing registry resets the denominator and must be
reported as such.

Alongside the list, keep a navigation graph (nodes are surfaces, edges
are reproducible actions), a presentation graph (push/select versus
sheet, popover, inspector, menu, window — chrome and dismissal differ),
and a risk-selected state and environment matrix per surface, not a
Cartesian product.

## Honest completeness wording

For a broad inventory audit, report the denominator, for example: N known
app-owned layout surfaces in this build/revision; M checked, K blocked on
stated gates, J flag-gated unvisited; plus S system-owned presentations covered for
navigation only. Inaccessible, account-gated, hardware-gated, flag-gated,
and destructive flows stay in the denominator as blocked with the exact
gate. Destructive flows are audited via fixtures or mocks, never live
data. Lazy content is captured at top plus scrolled positions. Unknown
universes are never labeled complete and never given percentages. For a
focused review, report checked surfaces and relevant unvisited states
without manufacturing an app-wide denominator.
Inability to measure a surface means unverified, never pass.

## Capability notes

Readable source is the only precondition for Pass A. Pass B needs a
runnable build plus permission to drive and capture it. Where the harness
cannot drive the app, record surfaces as blocked or unvisited with the
gate — do not infer geometry from source. No host-specific driver,
framework, or subscription is required by this skill; adapters are
optional and never redefine what counts as covered.
