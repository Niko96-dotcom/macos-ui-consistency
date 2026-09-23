---
name: macos-ui-consistency
description: Audit macOS SwiftUI or AppKit interfaces for unintended layout and visual drift across related surfaces, and repair clear app-owned inconsistencies when authorized.
license: MIT
---

# macOS UI Consistency

Use this skill to compare related Mac app surfaces against the app's design intent. Preserve intentional differences and native behavior. The reusable method supplies no universal margins, window sizes, or visual style.

## Scope and authority

- Follow the user's requested scope. An explicit audit, review, or planning request produces findings only. Otherwise, audit and repair clear accidental app-owned inconsistencies within the user's existing authorization. Ask about material design ambiguity; do not turn a taste preference or a majority pattern into a rule.
- Treat native chrome, safe areas, system materials, and standard control behavior as system-owned. Observe them in the audit. Change app-owned toolbar or window configuration only when the user has requested that scope and the platform API supports it; never shift system-managed geometry as a spacing workaround.
- Preserve semantics, state, keyboard focus, accessibility order and labels, and unrelated work. Use fixtures or mocks for destructive flows and preserve real user data.

## Workflow

1. **Identify the target and scope.** Check the intended source revision, dirty state, and app design contract if one exists. When using runtime evidence, identify the running executable and build. If no contract exists, derive candidate relationships from the user's request and repeated app patterns, and mark uncertain design choices as proposed. A source file is not necessarily one UI surface. For a broad or repeat audit, maintain a stable per-app surface inventory; for a focused task, record the affected surfaces and states. See [discovery](references/discovery.md).
2. **Declare comparable relationships.** Group genuinely related screens by family and variant. Name the app-owned anchors or control roles that should match, their consumers, environment, and intentional exceptions. Compare pane-local or content-local relationships, not screen coordinates. For numeric contracts use [layout contracts](references/layout-contracts.md) and the [data format](references/data-format.md). For view switches, centered composition, growth, or material states, use [relational review](references/relational-review.md).
3. **Observe the relevant states.** Capture populated content and the transitions likely to expose drift. Where resizing matters, test default, compact, and smallest supported sizes plus the applicable pane combinations and both resize directions. Fixed-size windows still need content reachability checks. A source review can identify likely causes but cannot verify rendered geometry or visual quality. See [window adaptation](references/window-adaptation.md) and [whole-window review](references/whole-window-review.md) for cross-page work.
4. **Compare and repair.** Record each issue with its affected surface, state, evidence, proposed relationship, and confidence. Numeric measurements need a method and uncertainty. Use the CLI below only when its bounded numeric comparison or source-candidate scan helps; visual and interaction verdicts remain separate. Repair an eligible shared cause, then verify affected consumers and relevant states before marking it fixed. See [verification and repair eligibility](references/verification.md).
5. **Report what was checked.** Separate measured, observed, inferred, blocked, and unverified claims. Name intentional differences and remaining issues. A focused pass cannot imply whole-app coverage; a numeric pass cannot imply visual acceptance. Record accepted app-specific rules in the app's own contract when the task calls for ongoing consistency.

## Optional helper

Resolve the script relative to the loaded `SKILL.md`, then run it from the app root. Its `scan` output is a heuristic candidate list. `compare` checks supplied numeric metrics only; it does not measure the app or inspect images. The [data format](references/data-format.md) owns the JSON schemas and exit codes.

```sh
SKILL_DIR="/absolute/path/to/macos-ui-consistency"
AUDIT_DIR=".audit/macos-ui-consistency"
mkdir -p "$AUDIT_DIR"
python3 "$SKILL_DIR/scripts/ui_consistency.py" scan . --output "$AUDIT_DIR/candidates.json"
```

When numeric contracts and measurements exist, prepare them using the [data format](references/data-format.md), then run:

```sh
python3 "$SKILL_DIR/scripts/ui_consistency.py" compare "$AUDIT_DIR/contracts.json" "$AUDIT_DIR/measurements.json" --output "$AUDIT_DIR/comparison.json"
python3 "$SKILL_DIR/scripts/ui_consistency.py" report "$AUDIT_DIR/comparison.json" --output "$AUDIT_DIR/report.md"
```

Existing output is refused unless `--force`; output symlinks are refused. A comparison with failures exits 1; unverified without failure exits 3. No exit code establishes whole-app visual acceptance.
