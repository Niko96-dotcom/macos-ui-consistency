# Relational layout contracts

Compare roles within the same family, density, and environment — never
absolute screen coordinates. A contract states what the app decided its
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
a contract. Across families, difference is expected and must not flag.

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
independent spacers do not create a shared column.

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
  variant, overflow and stacking decisions.

## The five guidance checks

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
   equal-width pills, or one width across families.
5. **Grouping.** Prefer proximity; reserve cards for genuinely distinct
   content and pills/badges/buttons for their own meanings. Never card
   every group, nest boxes that duplicate spacing, or re-skin materials
   because a newer OS style exists. Existing chrome and material choices
   are audited for consistency, not auto-replaced.

## Optical alignment last

Fix structural insets and baselines first. Equal frames can still
misalign text — use baselines, not centers. Ornamented views need
alignment-rect reasoning; symbols must weight-match adjacent text;
custom guides align text across nested stacks. Optical nudges are
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
