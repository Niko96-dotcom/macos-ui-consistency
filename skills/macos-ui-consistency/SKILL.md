---
name: macos-ui-consistency
description: Audit and align macOS app UI consistency with evidence.
license: MIT
---

# macOS UI Consistency

Guidance-driven audit-and-alignment for SwiftUI / AppKit apps on macOS.
Finds cross-screen drift (shells, keylines, type roles, control sizing,
grouping), reports it with evidence, and fixes only clear accidental
app-owned inconsistencies. This is not a generic Swift rewriter and not
an exhaustive scanner.

Apple guidance is linked, never restated as rules. App values are
calibrated per app and family; no universal dimensions are shipped here.

- [HIG Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- [HIG Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- [HIG Windows](https://developer.apple.com/design/human-interface-guidelines/windows)
- [HIG Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars)
- [HIG Split views](https://developer.apple.com/design/human-interface-guidelines/split-views)
- [Designing for macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos)
- [NSWindow minSize](https://developer.apple.com/documentation/appkit/nswindow/minsize) / [contentMinSize](https://developer.apple.com/documentation/appkit/nswindow/contentminsize)
- [NSView alignmentRectInsets](https://developer.apple.com/documentation/appkit/nsview/alignmentrectinsets?language=objc)
- [WWDC19 session 237 — custom alignment](https://developer.apple.com/videos/play/wwdc2019/237/)
- [`XCUIElementAttributes.frame`](https://developer.apple.com/documentation/xcuiautomation/xcuielementattributes)

## Modes

- **Default (audit + eligible repairs):** invocation defaults to auditing
  and automatically applying eligible repairs within current user
  authorization (see [references/verification.md](references/verification.md)).
  Repairs cover only demonstrably accidental app-owned inconsistencies
  with before/after verification. Ambiguity is reported, never
  blanket-confirmed.
- **Explicit audit-only / review / planning:** when the user explicitly
  requests audit-only, review, or planning, forbid all app edits; report
  only.
- Never expand an ordinary review request into fixes. Never reposition
  native titlebar, toolbar, traffic lights, document title, or safe
  areas. Never normalize intentional variants.

## Ownership boundary

- **System:** native chrome, materials, safe areas, system text styles,
  standard control behavior. Observed only.
- **App:** content-pane insets, content roles, shared shells/components,
  app-owned custom headers. Only these are measured and fixed.
- Preserve keyboard focus, VoiceOver order, interaction, and behavior on
  every change. A fix that alters semantics is out of scope.

## Workflow

1. **Discover.** Build a persistent per-app surface inventory (stable
   surface IDs, source, build, owner, prereqs, route, family, variant,
   status, evidence). See [references/discovery.md](references/discovery.md).
2. **Contract.** Declare relational role-to-role rules per page family in
   the same environment. No cross-family absolute coordinates.
   See [references/layout-contracts.md](references/layout-contracts.md).
3. **Measure.** Capture pane-local values with method, uncertainty, and
   evidence refs. Establish and runtime-test the usable sizing envelope
   where the app supports resizing (normal/compact/narrowest,
   applicable pane combinations) before polishing spacing. Fixed-size
   windows justify N/A with reason. Source-only work cannot claim
   visual verification.
4. **Compare and report** with the sibling CLI (schemas owned by
   [references/data-format.md](references/data-format.md); read it for normative fields).
   Resolve scripts relative to the loaded SKILL.md directory, not the repo root.
   Run with the app root as working directory; write outputs into an
   app-local audit directory (respect an existing project convention):

   ```sh
   SKILL_DIR="/absolute/path/to/macos-ui-consistency" # resolve from the loaded skill
   AUDIT_DIR=".audit/macos-ui-consistency"
   mkdir -p "$AUDIT_DIR"
   python3 "$SKILL_DIR/scripts/ui_consistency.py" scan . --output "$AUDIT_DIR/candidates.json"
   # After preparing contracts.json and measurements.json using data-format.md:
   python3 "$SKILL_DIR/scripts/ui_consistency.py" compare "$AUDIT_DIR/contracts.json" "$AUDIT_DIR/measurements.json" --output "$AUDIT_DIR/comparison.json"
   python3 "$SKILL_DIR/scripts/ui_consistency.py" report "$AUDIT_DIR/comparison.json" --output "$AUDIT_DIR/report.md"
   ```

   `scan` emits heuristic candidates only, never proof of coverage.
   `compare` checks supplied numeric metrics only, never screenshots or
   inferred semantics. Add `--force` to allow output overwrite; symlinked
   outputs are refused.
5. **Repair if eligible, then converge.** See [references/verification.md](references/verification.md).
   Re-run on an unchanged app must yield zero new findings. Never silently
   re-baseline a failing reference to quiet it.

## Cross-page alignment scope

Cross-page alignment requires inventorying and comparing the declared
shared shell anchors for that page family — whatever roles the contract
names (for example, one browser family might declare title/subtitle,
header envelope, controls baseline, divider, and body start; a settings
family would instead declare label/control columns) — at the same width
and environment before declaring pages aligned.
A report scoped to one anchor (e.g., title leading only) must state its
narrow scope explicitly and cannot imply whole-page verified.

## Guidance checks — six (detail in [references/layout-contracts.md](references/layout-contracts.md))

1. Shared shells and page families over per-screen offsets.
2. Pane-local keylines and relational anchors.
3. Semantic type roles, not decorated sizes.
4. Control sizing by context and role.
5. Grouping by proximity first; cards and pills only with a stated role.
6. Window adaptation first: usable sizing envelope before spacing polish.
   See [references/window-adaptation.md](references/window-adaptation.md).

## Capability fallbacks (host-neutral)

- **Source only:** candidate inventory, shell hypotheses, literal audit.
  No geometry verdicts.
- **Source plus manual screenshots:** observed findings with hand-checked
  pane-relative reasoning. No automated keyline verdicts.
- **Accessible runtime:** coarse rectangles and presence where the harness
  permits. No baseline or decorative-inset proof.
- **Instrumented probe:** not implemented; do not advertise or require it.
  Optional host/SDK adapters never change contract semantics and graduate
  only on measured gain.

## Evidence discipline

Every finding records location, state, and conditions (window size,
appearance, locale, fixture, sidebar/inspector, scroll). Severity applies
to issues only. Unmeasurable means unverified, never pass. Packaging
follows [Agent Skills specification](https://agentskills.io/specification):
this file plus `references/`, `scripts/`, `agents/` with progressive
disclosure. Per-app `inventory/` data lives outside the reusable skill.
