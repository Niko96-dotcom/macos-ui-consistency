# Whole-window composition and state review

Use this reference for cross-page alignment, especially when the user points
to several screenshots or says inconsistencies remain everywhere. For
transferable slot relations within a surface or across declared consumers, read
[relational-review.md](relational-review.md); that file owns slot
definitions, this file owns whole-window and transition acceptance.

## Establish the design, then propagate corrections

Read the app's accepted design contract and inspect the full window before
normalizing individual pages. Name the relationships the user expects to
hold: shared header bands, panel treatment, primary content starts,
label/control rows, primary action placement, and equivalent control shapes.
Map each to its consumers, scope, variants, and intentional exceptions.

Each correction becomes a candidate rule plus a consumer sweep. A differently
shaped primary button prompts inspection of equivalent buttons on every page;
a drifting selector prompts checks of all equivalent option groups and their
states. Record the rule once in the shared component or contract, rather than
applying an isolated offset. Do not generalize to unrelated semantic roles.

If aligned anchors still produce awkward whitespace, weak hierarchy, or a
poor task flow, identify a composition problem. Within authorized redesign
scope, compare a small set of coherent layouts with actual controls and
populated states before porting all pages. A repair-only request gets a
bounded design proposal for material changes outside scope. Existing user
approval applies across consumers; do not repeatedly seek it.

## Review three independent outcomes

1. **Geometry:** compare all declared anchors, including horizontal and
   vertical placement, header/body boundaries, control envelopes, and
   relationship to neighboring panes. Equal outer frames do not prove equal
   text baselines, visible shapes, or internal padding.
2. **Transitions:** capture the same surface before and after relevant
   interaction. Declare stable anchors and allowed reflow, then check focus,
   selection, mode changes, conditional helper/error text, expanding options,
   progress, and populated results. Keep transient information in a deliberate
   location; do not conceal essential constraints in hover-only help to pass.
3. **Visual composition:** inspect full-window balance and readable crops:
   materials, panel proportions, corner shape, resting affordances, selected
   appearance, typography, density, and optical weight. A brand with a logo
   can need different type sizing from a page title on open canvas while
   sharing a header band. Record that as intentional hierarchy.

Inspect only states applicable to the change, with meaningful real or fixture
content. A focused field should not unexpectedly acquire a different layout
or reveal its only editing affordance. Joined choices or option grids are
app decisions, not universal substitutes for native menus. Preserve semantic
roles, keyboard operation, visible focus, accessible names and selection.
Never adopt a blanket no-focus-ring rule from an app's visual preference.

State records belong beside the app's audit evidence: surface/transition,
before and after state, stable anchors, allowed reflow, environment, evidence,
and geometry/visual/interaction verdicts. The CLI does not execute transitions
or compare screenshots. Separate captures may be represented by stable state
surface IDs with the same contract variant when the relationship must hold;
intentional alternate layouts use separate variant contracts.

## Completion evidence

- Capture affected consumers at the same window size, appearance,
  scale, pane configuration, and scroll position. Compare full-window images
  together, then inspect individual controls at readable scale. Cropped title
  strips alone cannot establish whole-window acceptance.
- Exercise the relevant transitions and the resizing matrix in
  [verification.md](verification.md). Check that shared actions retain their
  declared position even when sibling pages have different option counts.
- Audit the relationships affected by the change, including shared consumers
  that might have moved with it. For a whole-app audit, cover the declared
  full set.
  A second unchanged pass yielding no code edits proves idempotence only;
  it does not prove visual quality or completeness.
- Report checked consumers, blocked states, deliberate differences, and
  unresolved visual issues. Numeric pass plus an optical failure is unfinished.
  User acceptance is recorded only when actually given, never inferred from
  tests or silence. Do not require another approval for already authorized work.

## Preserve the accepted result

Update the app's existing design contract with relationships, component
ownership, variants, rationale, and evidence references; distinguish proposed,
agent-verified, and user-accepted decisions. Add focused regression checks for
meaningful invariants. Source guards cannot replace runtime state or visual
checks; changing a test and its contract together does not itself justify a
new design. Remove superseded guidance or mark it historical, and ensure the
app's contributor instructions point at the current contract.

App dimensions, materials, chosen hidden features, and optical exceptions stay
in that app. The reusable skill owns the method, not a particular app's style.
