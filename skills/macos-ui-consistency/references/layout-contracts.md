# Relational layout contracts

Compare declared relationships at the same density and environment — never
absolute screen coordinates. Page families remain the default scope; explicit
window and component contracts can connect named surfaces across families. A contract states what the app decided its
screens share; Apple guidance informs the vocabulary, not the values.

Relevant Apple sources: [HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
(window types, toolbar placement, adaptation), [HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
(Mac body text with a small minimum, SF Pro, system text styles, leading and
truncation), [HIG Windows](https://developer.apple.com/design/human-interface-guidelines/windows),
[NSView alignmentRectInsets](https://developer.apple.com/documentation/appkit/nsview/alignmentrectinsets?language=objc)
(frames may differ from alignment geometry), [WWDC19 session 237](https://developer.apple.com/videos/play/wwdc2019/237/)
(first/last baselines and custom guides across nested stacks).

## Page families first

Group sibling screens before writing rules. Typical families: browser or
list pages (content title, body, actions, filters, tables), settings and
forms (readable width, label and control columns), editors and canvases
(workspace priority), sheets, popovers, and inspectors (compact rules).
Same role plus same family plus same density plus same environment shares
a family contract. Across families, differences stay excluded unless an
explicit window or component contract declares that relationship.

## Three contract levels

- **Window:** shared app-owned header bands, content starts, panel widths,
  materials, and corresponding label/control rows across named panes.
- **Family:** the page's composition, content hierarchy, adaptation, and
  intentional variants. Different bodies can share one window header.
- **Component:** appearance and geometry of equivalent controls across
  named consumers: shape, height, fill, grouping, selection and focus.
  Equivalent appearance does not require identical behavior or AX roles.

Declare rationale and targets from the accepted app design or user intent.
Do not infer equal panel widths, centered/leading headers, joined selectors,
or bottom-pinned actions as universal platform requirements. Keep native
chrome outside app-owned contracts. Model only the shared relationship;
never relabel unrelated pages as one family to get a comparator pass.
Numeric shared scopes use contracts schema 2 with explicit surface IDs;
see [data-format.md](data-format.md). Materials, optical weight, and control
semantics need visual/interaction evidence outside the numeric comparator.
State-transition and whole-window acceptance are described in
[whole-window-review.md](whole-window-review.md).

Variants (subtitle absent, narrow stacking, inspector open, scrolled or
sticky state) belong in the contract's variant field so narrow or wrapped
layouts pass by declaration rather than by per-screen exception.

## Anchors, not coordinates

Define named relationships (content leading from pane leading plus page
inset; body top from header bottom plus gap) so sidebar resizing and
window moves preserve the relationship while absolute positions change.
Canonical comparisons happen in pane-local or content-local points with a
declared unit and coordinate space. Points times scale equals pixels;
cross-scale pixel diffs are invalid. Distinguish container edges from
text edges and icon gutters from table columns. Independent stacks with
independent spacers do not create a shared column. Define one relational
 control column (declared shared selection label/control/action keylines:
 baselines, grid columns, value edges) separately from content/table
 internal gutters (cell padding, internal insets). Whether differing
 internal gutters are intentional is decided by the declared semantic
 contract and design intent, never exempted by control type alone; only
 drift of the declared shared column fails. Do not require one equal
 width across unrelated controls. Do not mechanically align labels to
 button text glyphs — use native alignment geometry and group semantics.
 Never label every differing edge "inconsistent".

Every rule carries scope, rationale, evidence method, severity,
tolerance, environment, and authority (`apple`, `app-decision`, or
`audit-heuristic`). Heuristics must never be presented as Apple
requirements. Tolerances are calibrated to measurement uncertainty and
environment per app; illustrative values from other documents must not
become defaults. Normative field lists live in [data-format.md](data-format.md)
(tooling-owned); this file defines intent only.

## Ownership of values

- **System — respect, do not reposition:** native window and document
  titles, traffic lights, titlebar and system-managed toolbar geometry,
  safe areas, sidebar material, accent, system text styles, standard
  control metrics, scroll-edge behavior.
- **App semantic values — the contract's subject:** page insets per
  family, section and header gaps, content-title, content-body, and
  content-action roles; an app-owned custom header or toolbar inside the
  content pane is distinct from the system-managed toolbar and may carry
  keylines.
- **Component — encapsulated:** badge height policy, button style per
  context, icon-label gap, optical insets, cell padding.
- **Environment or derived — computed:** breakpoints from usable width,
  label-column width with a wrap bound, header height from content plus
  variant, overflow and stacking decisions. Usable width/height envelope
  first (see [window-adaptation.md](window-adaptation.md)). Findings from a
  captured size may be reported for that size while the envelope is unverified;
  do not claim compact/minimum acceptance or extrapolate below tested sizes.

## Platform metrics vs app values

Apple owns idiom, never numbers for the app: Mac push/square/help/image
button roles, pop-up menu as space-efficient selector, 13pt default /
10pt minimum type floor with SF Pro, tooltip/RTL/keyboard conventions,
frame-vs-alignment-rect behavior. The app owns every inset, gap,
breakpoint, and minimum window content size. No universal numeric window
size ships from this skill; no HIG sentence becomes an app default.

## The six guidance checks

1. **Shells.** One shared shell per family; fix drift at the highest
   responsible level (shell, component, value, composition) before
   touching screens. Arbitrary shell extraction solely to homogenize is
   out of scope.
2. **Keylines.** Title, body, and action edges share declared anchors in
   the same family and environment. Verify declared relationships after
   pane resizes rather than requiring identical coordinates.
3. **Type roles.** Few faces, built-in styles, hierarchy preserved under
   scaling, minimal truncation, stacking rather than crowding at large
   sizes. Test Mac accessibility and app scaling, not phone checklists.
4. **Control sizing.** Size, style, and shape follow context and role;
   Mac idiom is compact relative to touch UIs. Never force touch targets,
   equal-width pills, or one width across families. Native small/mini
   control sizes in their documented contexts are allowed; arbitrary
   visual scaling to hide a fit failure is not allowed.
5. **Grouping.** Prefer proximity; reserve cards for genuinely distinct
   content and pills/badges/buttons for their own meanings. Never card
   every group, nest boxes that duplicate spacing, or re-skin materials
   because a newer OS style exists. Existing chrome and material choices
   are audited for consistency, not auto-replaced.
6. **Window adaptation.** Usable sizing envelope before spacing polish.
   See [window-adaptation.md](window-adaptation.md).

## Shared header envelope (declared scope and environment)

Wrapped copy length itself is intentional, but downstream drift of shared
shell anchors (for example, a browser family's controls baseline, divider,
or body start) across sibling pages at the same width violates the shared
shell and is actionable.

Where sibling headers in a declared family or shared window contract differ only
by wrapping copy length, downstream anchors must stay stable by a declared
mechanism. One allowed pattern is a shared width-dependent, content-derived
header/description envelope over sibling descriptions: a SwiftUI Layout or
hidden accessibility-excluded sizing reference measuring all sibling
descriptions live at the current width, height is the max. Other declared
mechanisms are equally acceptable where they fit the family — for example,
top-anchored controls independent of header height, or a fixed family header
height with wrapping copy confined below the anchor line. Whatever the
mechanism, it must hold with no truncation, no shortened copy, no per-page
offsets, and no stale height on resize or inspector-open (narrow widths and
inspector-open re-resolve live; no historical max cache). The mechanism
applies within the declared family or explicitly shared window contract
at the same environment, never indiscriminately across every page. Preserve differences the semantic contract declares
intentional plus system chrome; never exempt gutter differences by type
alone.

## Compact composition (intentional, not accidental stacking)

A narrow-window fallback is a declared variant, not an excuse for a cramped
mixed stack. Flag accidental stacking (for example: large blank reserved
above controls on the shortest sibling plus misaligned selection labels
plus secondary actions crammed below) as FAIL against the declared compact
contract even when each control alone looks native.

Deliberate compact contract (app-decision, per same width/variant):

- Hierarchy: follow the declared task priority for what stays visible and
  operable as space shrinks; do not assume one pane always wins. Preserve
  meaning and information hierarchy unless design intent explicitly
  reorders it. Long secondary copy may move to a declared below-controls
  or overflow location with full text still discoverable and wrapping;
  never truncate or blanket-hide important content to fit, and do not
  require overflow menus or disclosures for every app — the mechanism is
  app-declared.
- Aligned labels: where selection controls form a semantic group, declare
  shared label/control/action columns with relational anchors (baselines,
  grid columns, value edges) using native alignment geometry plus group
  semantics. Do not add arbitrary per-screen offsets, force one equal
  width across unrelated controls, or mechanically align labels to button
  text glyphs.
- Action overflow: any overflow mechanism is app-declared and must keep
  every action and current selection reachable with preserved
  accessibility labels, identifiers, and focus at readable native sizes
  (never scale/shrink controls to fit, never globally force equal
  heights, never reset state on navigation/resize, never reposition
  native chrome).
- Adaptation is fit-driven (content-measured fit, not device/width
  assumptions); shared pieces are reused, not duplicated giant layouts.

Example (explicitly labelled, not normative): one app might place
secondary actions in a labeled overflow menu and long copy in a shared
disclosure below controls, resolving a width-dependent shared envelope
live in both resize directions.

Assess hierarchy, aligned labels, overflow reachability, and content
discoverability together. Test thresholds live in both directions
(wide→narrow and narrow→wide), with applicable pane combinations open
and closed at the app-declared default and minimum sizes, and with
shortest vs longest headers, so stale heights and one-way-only fallbacks
cannot pass. Where a window is declared fixed-size with justification,
the resize matrix is N/A with reason recorded.

## Optical alignment last

Fix structural insets and baselines first. Equal frames can still
misalign text — use baselines, not centers. Ornamented views need
alignment-rect reasoning (`alignmentRectInsets`: segmented-picker indent,
menu chevron, switch track overhang are native, not app offsets);
symbols must weight-match adjacent text;
 custom guides align text across nested stacks. Compact selection-value and
 overflow-action edges are judged against the declared control column, not
 against content leading or table cell text. Optical nudges are
component-owned, narrow, documented with a reason, and allowlisted —
never scattered per-screen offsets. Geometry invariance across
appearances holds only where the contract claims it.

## Prohibited normalizations

No universal grid value, no single max width for all families, no blind
truncation or font shrinking for long text, no percentage-of-window
heights, no choosing a new meaning for badge versus filter versus
action, no heuristic grouping or taste call presented as a violation.
Overflow policy (truncate with access, reflow, collapse to menu) is
declared per surface; toolbar overflow handling varies by API, style,
OS, and deployment target, so capability-check the app rather than
assuming system handling.
