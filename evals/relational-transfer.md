# Relational transfer cases (synthetic, not executed)

Focused synthetic scenarios for
[relational-review.md](../skills/macos-ui-consistency/references/relational-review.md).
**None of these scenarios have been executed or scored; do not claim
results.** They test transfer of relation shapes to new aesthetics, not
wording recall: each case declares a relational contract, then requires a
finding against it plus a withheld non-finding. Schemas and verdict math
stay in [data-format.md](../skills/macos-ui-consistency/references/data-format.md);
current schema and CLI are unchanged.

General protocol per case: declare the family or window contract first;
capture full-window evidence at the same width and environment with
populated content; record window size, appearance, locale, pane states,
scroll, and navigation or resize order; map each claim to evidence and
contract; unmeasured combinations stay `unverified`, never pass.

## R-T1. Text editor — paired source/preview toggle

Synthetic setup (not executed): a text editor declares a paired source/preview
toggle sharing one declared slot in app-owned layout. A file drilldown from the
sidebar into a deeper document is explicitly outside the toggle contract.

Synthetic observation: at the same width with populated documents, forward uses
the declared slot but reverse appears in a different slot, forcing pointer
re-acquisition and shifting pinned neighbors.

Synthetic finding (not executed): FAIL against same-slot continuity for the
paired toggle only.

Synthetic non-finding (must be withheld): the drilldown not reusing the toggle
slot; label or selection meaning changing with the toggle state.

Forbidden edits: moving native chrome; forcing one icon shape or placement;
demanding identical identifiers across toggle states.

## R-T2. Preferences form plus data table — outer/inner cap with bounds

Synthetic setup (not executed): a preferences family declares centered composition
with outer cap 640 including 20 padding each side (content 600). An unrelated data
table family in the same app declares full-width content with no cap. A results list
declares a fixed viewport with internal scroll.

Synthetic observation: pane width 1000; actual wrapper 680 wide centered at x160
(spans 160..840); inner content x180..780. Wrapper exceeds the declared 640 outer
by 40, pooling slack asymmetrically against the declared even split. Separately, a
long synthetic result set overflows the fixed viewport and clips trailing actions
with no scroll path.

Synthetic finding (not executed): FAIL against outer/inner accounting for the
oversized wrapper; FAIL against bounds holding under stress for the clipped list.

Synthetic non-finding (must be withheld): the table using full width beside the
capped form; narrower content on a wider window while the cap holds.

Forbidden edits: shipping the form cap into the table family; prescribing one scroll
owner for the whole page; requiring a cap where none is declared; testing empty
state only.

## R-T3. Fixed-size high-contrast utility — bounds plus focus states

Synthetic setup (not executed): a fixed-size utility with no panes, populated data,
and a standard BLUE focus ring. Contract declares resting, selected, and keyboard
focus appearances across active and inactive window states under high-contrast
accessibility settings.

Synthetic observation: with populated content at the declared size, one control
clips and becomes unreachable; in one window state the selected row is
indistinguishable from resting, while distinct in the others.

Synthetic finding (not executed): FAIL against bounds holding under stress for the
clipped control; FAIL against state-by-state stability for the indistinguishable
selected state.

Synthetic non-finding (must be withheld): inactive focus not matching active focus;
a system-driven material shift without a contract exception.

Forbidden edits: requiring panes, resize, or a cap the app never declared;
adopting a blanket no-focus-ring rule; forcing equal RGB across backgrounds.

## Scoring note

Pass requires the synthetic finding reported with evidence and contract
citation, the synthetic non-finding excluded with reason, and zero
forbidden edits. A report that checks only one anchor cannot imply
whole-slot verified. Source-only reasoning stays `unverified` for geometry;
screenshots or pane-local measures are state evidence, not automated proof.
