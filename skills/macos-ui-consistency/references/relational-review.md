# Relational slot review

Adds slot relations missing or implicit in [layout-contracts.md](layout-contracts.md),
[whole-window-review.md](whole-window-review.md), and [window-adaptation.md](window-adaptation.md).
It grants no additional authorization; repairs follow the Default mode in `SKILL.md`
and evidence levels in [verification.md](verification.md).

Method, stated once: declare the slot and its consumers in the app contract first,
then compare pane-local or content-local relations at the same width and environment.
Equal outer frames prove nothing about text baselines, visible shapes, or internal padding.
Undeclared reflow is a candidate finding only where evidence or intent requires a shared
relationship; otherwise record uncertainty, never a blanket drift verdict. Text-only
feedback cannot claim independent optical verification.
State measured consumers and states plus unverified combinations once per check.
Native chrome, system materials and behavior, and safe areas are observed only.
Preserve keyboard focus order, VoiceOver labels, interaction, and behavior.

Header envelopes and proximity grouping stay in whole-window-review and layout-contracts
and are not restated here.

## 1. Reciprocal navigation continuity — same-slot switch

Relation: forward and reverse of a declared paired view toggle share one declared slot
in app-owned layout and stay under the cursor both ways, so repeated navigation needs
no re-acquisition and pinned neighbors do not shift. This applies only to a declared
paired view toggle. A drilldown, dialog dismissal, breadcrumb, or wizard step need not
use the same slot.

Check: go there and back at the same width and environment with populated content;
confirm the target stays in the declared slot under the established interaction point.

Do not prescribe a single icon shape or a title-bar placement. Preserve the
native-chrome boundary, keep action-specific labels for each direction, and preserve
keyboard focus and accessible names.

Non-finding: selection or label meaning changing with the switch is correct, not drift.
No exact identifier equality is required across the two states.

## 2. Content cap, padding, and centering — outer versus inner

Relation: where the contract declares centered composition, a centered container sits
in the pane and inner content sits inside that container with its own padding. The
declared outer bound already includes its own horizontal padding; size the centering
box to the declared outer size, never outer plus padding again.

Check pane-locally: outer container bounds against the pane, inner content against the
container, and left/right outer slack against the declared composition (even split only
where centered composition is declared). Never compare horizontal optical center against
text baselines; those are different axes.

Non-finding: differing caps across families; a full-width table beside a capped form.
No cap is required, period. Centered composition can be uncapped.

## 3. Growth and scroll containment — bounds hold under stress

Relation: each growing region relates to declared viewport bounds and scroll handling
per axis and region; nested scrolling can be valid (for example an outer list scrolling
vertically while an inner viewport scrolls horizontally, or pinned anchors staying put
while the list scrolls). Never prescribe exactly one scroll owner for the whole page.

Check empty, typical, and overflowing populated states even for fixed-size utilities;
no-resize never exempts overflow testing. Confirm pinned declared anchors stay put and
bounds hold under growth, in both resize directions where resizing applies.

## 4. Material and selection stability — state by state

System-driven inactive flattening and backdrop-dependent tones are observed differences,
not consistency failures. For app-owned treatments, compare whether resting, selected,
and applicable focused states retain their intended hierarchy and affordances.

Check the same surface in supported light/dark, active/inactive, and applicable
accessibility and backdrop states with populated content, scoped to appearances and
states relevant to the change. Text, selected state, and applicable keyboard focus
remain distinguishable under applicable accessibility appearance settings. An inactive
window need not retain the active focus visual. System-driven material shifts are
legitimate without a contract exception. Frame equality never proves perceived hierarchy.

Non-finding: system shifts noted as expected; intentional hierarchy the contract records.
Never force sameness or equal RGB across different backgrounds — a translucent treatment
correctly renders differently over different tones. Never adopt a blanket no-focus-ring
rule, never hide essential constraints in hover-only help, never re-skin chrome for fashion.

## What stays app-specific

Every cap, padding, slot, viewport bound, material choice, and tolerance here is an app
decision in that app's contract with scope, rationale, evidence method, and authority.
Portability test: the same four relations must be askable of a form app, a dense editor,
and a small utility with different aesthetics without forcing a redesign, a shared
number, or a shared visual treatment.
