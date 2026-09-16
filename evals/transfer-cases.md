# Transfer cases (scored 2026-09-16, this host)

Cases 1–5 were executed against dedicated fixture apps on this Mac (Dark
appearance, 2x Retina) and all passed; per-case records live in
`.audit/case1` … `.audit/case5` (gitignored working material) with the
scoring notes below. Case 5 additionally passed a blinded agent run
(`.audit/case5-blind/report.md`). No test-app edits were made during any
case run; audit-only unless stated. Evidence: `docs/images/case*` plus
instrumented `--dump-geometry` values quoted per case.

General protocol (runnable or manual): declare a per-family relational
contract first; capture screenshots or pane-local manual measures at the
same width/environment per state; record window size, scale, locale,
pane states, scroll, and navigation/resize order; map each claim to
evidence and contract; unmeasured combinations stay `unverified`, never
pass. Score: expected finding reported with evidence, expected
non-finding excluded with reason, zero forbidden edits (verify via
`git status` where a repo exists).

## 1. Settings form — varying label lengths and localization

**Setup/input:** settings window with label/control rows; observe at
default and narrow widths in base locale plus one long-locale pass
(longer labels, wrapping); record pane-local label-column and control-
column edges, not screen coordinates.

**Expected finding:** drift of the declared shared label/control column
within the same family/environment is FAIL (for example, one row's
control edge offset from the declared column beyond tolerance).

**Expected non-findings:** longer wrapped copy length itself; row height
growth from wrapping; system text-style sizes.

**Forbidden edits:** truncating or shortening copy to equalize lengths;
shrinking fonts; forcing one equal width across unrelated groups;
repositioning native chrome.

**Run 2026-09-16 (SettingsFixture): PASS.** Default + minimum widths ×
base + long locales: shared control column holds in all four cells
(162.0 good rows, 174.0 seeded row instrumented; screenshot leadings
agree differentially to the pixel). Longer wrapped copy, row-height
growth, and system sizes excluded. Zero file modifications.

## 2. Document editor — essential inspector, optional navigation

**Setup/input:** editor where the inspector is the essential editor for
the declared primary task and the side navigation pane is declared
optional/collapsible; observe default, compact, and narrowest (both
resize directions), with nav open/closed and inspector open, plus
keyboard/VoiceOver spot-check.

**Expected finding:** primary editor controls clipped, unreachable, or
arbitrarily scaled at narrowest is FAIL; stranding required function in
a hidden pane without an app-declared fallback is FAIL.

**Expected non-findings:** nav collapsed by user intent with a declared
reversible fallback; density differences where the contract declares a
separate compact family.

**Forbidden edits:** forcing the essential inspector to collapse;
assuming every inspector is optional; universally requiring button +
menu + shortcut where the app provides a different accessible fallback;
changing meaning or info hierarchy without design intent.

**Run 2026-09-16 (EditorFixture): PASS.** Narrow (700): fixed 300pt
format bar overflows the 200pt inspector pane (instrumented + slider
visibly cut at the window edge) → FAIL as expected; `--aligned` wrapped
rows fit → reachable. Inspector never collapsed; nav optionality
untouched.

## 3. Dense workspace — deliberate pane constraints, inner scroll

**Setup/input:** dense timeline workspace with app-declared constrained
panes where the inner timeline viewport declares horizontal scroll;
observe at default and narrowest with applicable pane combinations;
record outer-page vs inner-viewport scroll separately.

**Expected finding:** clipped primary transport/selection controls,
unreachable actions, or horizontal outer-page scroll outside the
declared inner viewport is FAIL.

**Expected non-finding:** horizontal scroll confined to the declared
inner timeline viewport; differing internal gutters the semantic
contract declares intentional.

**Forbidden edits:** removing deliberate pane constraints or inner
scroll to force everything to fit; normalizing intentional gutter
differences by type alone; claiming every differing edge inconsistent.

**Run 2026-09-16 (WorkspaceFixture): PASS.** Narrow (560): 460pt
transport spans past the 410pt viewport with Snap clipped off-window and
no declared outer scroll → FAIL as expected; `--aligned` fills the
viewport exactly inside the declared horizontal ScrollView with all six
transport buttons AX-exposed. Caveat: synthetic wheel events did not move
the scroller (harness limit); reachability rests on construction +
widen demo + AX exposure. Pane constraints and inner timeline scroll
kept.

## 4. Small fixed-size utility — no sidebar, no resize

**Setup/input:** small utility window declared fixed-size with
justification and no sidebar; observe at the declared size; record the
no-resize declaration and check every primary control is visible and
operable with no outer scroll.

**Expected finding:** any clipped primary control or unreachable action
at the declared size is FAIL.

**Expected non-findings:** absence of a resize matrix (record N/A with
reason — this passes, it does not fail); absence of collapse or
overflow affordances the app does not declare.

**Forbidden edits:** requiring a resize matrix, sidebar collapse, or an
overflow menu/disclosure the app never declared; applying visual scaling
to hide a fit failure (native small/mini sizes in context remain
allowed).

**Run 2026-09-16 (UtilityFixture): PASS.** Declared fixed 320×200:
programmatic resize refused (stays put); all three controls visible;
Start AX-clicked with `utility-action-fired` observed. Correct outcome
for a sound utility is no finding; no matrix/collapse/overflow demanded.

## 5. Adversarial — majority shared pattern is wrong

**Setup/input:** four sibling screens where three share the same copied
label-column offset and one follows the declared semantic contract;
contract declares the minority value correct. Observe all four at the
same width/environment with pane-local measures.

**Expected finding:** the majority three FAIL against the contract; the
minority passes. Report must cite the contract, not frequency.

**Expected non-finding:** none — do not exclude the majority as
"established convention."

**Forbidden edits:** re-baselining the contract to the majority;
treating frequency or majority alone as justification; inferring a
heuristic taste call as certain to fix it; silently re-baselining a
reference to quiet the failure.

**Run 2026-09-16 (AdversarialFixture, blinded): PASS.** A fresh agent
given only the skill, the contract (162), and the measurements
(174/174/174/162) failed the majority against the contract with exact
math, passed the minority, kept scope honesty, and explicitly refused to
re-baseline — with zero file modifications.
