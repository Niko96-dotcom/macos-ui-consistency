# Data format (single schema owner)

This file is the authoritative schema/CLI reference for `skills/macos-ui-consistency/scripts/ui_consistency.py`.
Other references point here without redefining the schema.

All example fixtures in `examples/` are **SYNTHETIC** only and **NOT** actual
runtime evidence. They are consistent with this schema.

Standard library only, Python >= 3.10. No dependencies. CLI never edits app sources.
All JSON I/O is deterministic (`sort_keys=True`, `indent=2`, UTF-8, LF, trailing
newline) and rejects NaN/Infinity (no NaN JSON on read or write).

## Concrete commands

```sh
python3 skills/macos-ui-consistency/scripts/ui_consistency.py scan ROOT --output /tmp/candidates.json [--force]
python3 skills/macos-ui-consistency/scripts/ui_consistency.py compare examples/contracts.json examples/measurements.json --output /tmp/comparison.json [--force]
python3 skills/macos-ui-consistency/scripts/ui_consistency.py report /tmp/comparison.json --output /tmp/report.md [--force]
```

- `ROOT`, `CONTRACTS`, `MEASUREMENTS`, `COMPARISON` are input paths (must exist).
- `--output PATH` is required for all subcommands.
- `--force` allows overwriting an existing output file. Without it, existing output is refused (exit 2).
- An output path that is a symlink is always refused (exit 2), even with `--force`.
- A missing output parent directory is an error (exit 2).
- `--output` must be a separate path from every input of that invocation, even with `--force` (exit 2). Same-path, normalized aliases (`./`, `sub/../`), parent-symlink aliases, and hardlinks (same inode) are all refused; invalid calls write no output and leave any existing output unchanged.
- `scan` never creates or overwrites a `.swift` source with `--output`, even with `--force` (exit 2), including `.swift` paths within `ROOT` via alias/symlink/hardlink. Overwriting a separate non-Swift output (e.g. `.json`) with `--force` remains allowed.

## Exit codes

| Subcommand | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| `scan` | success | — (never used) | invalid input / I/O (bad ROOT, unreadable Swift file, bad output path, overwrite/symlink refusal, JSON encode failure) | — (never used) |
| `compare` | no `fail` and no `unverified` (only `pass`/`excluded`) | any `fail` | invalid input / I/O (bad JSON, NaN/Inf/bool where numeric, duplicate IDs, malformed required fields, empty rules/surfaces, missing files, output refusal) | no `fail` but any `unverified` |
| `report` | success | — (never used) | invalid input / I/O (bad comparison JSON, output refusal) | — (never used) |

Empty contracts (`rules: []`) and empty measurements (`surfaces: []`) are invalid
(exit 2), never green. A rule with no applicable surfaces emits one `unverified`
finding with `surface_id: null`, so it is never silently green (exit 3).

## scan: source candidates (heuristic)

Input: `ROOT` directory scanned recursively for `*.swift` files.

- Default ignored names at any level: `.git`, `.build`, `.swiftpm`, `.audit`, `vendor`, `node_modules`, `DerivedData`.
- Symlinks are never followed; symlinked files/dirs are skipped. A symlinked `ROOT` is invalid (exit 2).
- Any unreadable file (I/O error, invalid UTF-8) aborts with exit 2; no partial “complete” output is written.
- Lexical masking strips `//` line comments, nested `/* … */` block comments,
  `"…"` strings (escapes handled), `"""…"""` multiline strings, and `#` raw-string
  delimiters (`#"…"#`, `#"""…"""#`). String interpolation contents are stripped as
  part of the string. This is a heuristic, not a full Swift parse.
- After masking, each line is searched for whole-word keywords:
  `WindowGroup`, `DocumentGroup`, `MenuBarExtra`, `CommandMenu`,
  `navigationDestination`, `contextMenu`, `fileImporter`, `fileExporter`,
  `commands`, `Settings`, `popover`, `inspector`, `Window`, `sheet`, `alert`.
  One candidate per `(line, kind)`; multiline call shapes are covered conservatively
  because the keyword itself is on one line.
- Relative source paths (`source`) are POSIX, sorted by `(source, line, kind)`.
- Stable candidate ID: `{source}:{kind}:{line}` (e.g. `App/ContentView.swift:sheet:42`).
  Line edits may change IDs; manually curated surface IDs persist separately and are
  not derived from scan IDs.
- `confidence` is always `"candidate"`.

Output object:

```json
{
  "schema_version": 1,
  "kind": "source-candidates",
  "root": ".",
  "candidates": [{"id": "App.swift:WindowGroup:3", "source": "App.swift", "line": 3, "kind": "WindowGroup", "confidence": "candidate"}],
  "limitations": ["..."]
}
```

Fields:

- `schema_version: 1` (int, not bool).
- `kind: "source-candidates"`.
- `root: string` — the `ROOT` argument as given (e.g. `"."`).
- `candidates: list` sorted as above; each has `id` (string), `source` (string),
  `line` (int >= 1), `kind` (one keyword), `confidence: "candidate"`.
- `limitations: list[string]` — always:
  - `heuristic lexical scan only; not a full Swift parser`
  - `comments and string literals stripped conservatively and never create hits; nested block comments handled lexically`
  - `candidate IDs derived from relative path+kind+line; line edits may change IDs; manually curated surface IDs persist separately`
  - `no runtime measurement and no completeness or app-wide coverage claim`
  - `CLI never edits app sources`

## contracts schema

```json
{
  "schema_version": 1,
  "rules": [{
    "id": "browser-title", "family": "browser", "variant": "regular",
    "role": "contentTitle", "metric": "leading",
    "expected": 24, "tolerance": 0.5,
    "unit": "pt", "coordinate_space": "pane-local",
    "environment_id": "fixture-regular", "authority": "app-decision"
  }]
}
```

- `schema_version: 1 | 2` (int, not bool). Version 1 keeps family-only rules;
  version 2 adds explicit scopes. Measurements and comparison outputs remain
  version 1. Older CLIs reject contracts version 2 instead of silently ignoring
  shared relationships.
- `rules: non-empty list` (empty is invalid, never green).
- Each rule requires: `id`, `variant`, `role`, `metric` (non-empty strings);
  `expected` (finite number, not bool); `tolerance` (finite number >= 0, not bool);
  `unit`, `coordinate_space`, `environment_id`, `authority` (non-empty strings).
- `role` is an app-owned content role (e.g. `contentTitle`), never native chrome
  (native titlebar/toolbar/traffic lights are not contracted; system surfaces are `excluded`).
- No universal `expected`/`tolerance` defaults are applied; every rule declares its own.
- Rule `id`s must be unique. No eval/expressions are supported or executed.
- Unknown extra fields (e.g. `_note`) are tolerated and ignored.

### Explicit scopes (contracts version 2)

- `scope`: `family` (default), `window`, or `component`.
- Family scope requires `family` (non-empty string), forbids `surface_ids`,
  and retains the version 1 matching/exclusion behavior.
- Window and component scopes require `surface_ids`: a non-empty list of
  unique non-empty strings naming the exact expected consumers. They forbid
  `family`; targets retain their own families in the measurements registry.
  Both scopes use identical numeric evaluation; the distinction documents
  whether the relationship belongs to window composition or shared controls.
- Explicit `scope` or `surface_ids` fields in version 1 are rejected. Other
  unknown metadata remains ignored. Version 1 rules still require `family`.
- All existing measurement evidence, uncertainty, environment, unit, ownership,
  and variant gates remain in force. Selection does not grant edit permission.

Synthetic example: align a label row in two different app-owned panes against
an app-chosen content-relative anchor. This is not a universal coordinate.

```json
{
  "schema_version": 2,
  "rules": [{
    "id": "shared-label-row", "scope": "window",
    "surface_ids": ["navigator", "tool-options"], "variant": "regular",
    "role": "groupLabel", "metric": "topFromContentTop",
    "expected": 76, "tolerance": 1,
    "unit": "pt", "coordinate_space": "window-content-local",
    "environment_id": "demo-regular", "authority": "app-decision"
  }]
}
```

Use the same declared origin for shared-window anchors, or measure a derived
relationship (for example, distance from each pane's leading edge). The CLI
compares supplied scalar values to the declared expectation; it does not
subtract frames from different surfaces, resolve origins, evaluate expressions,
or infer which relationships ought to hold. Supply those measurements with
evidence. Appearance, materials, and optical balance need separate visual
review; do not encode a subjective verdict as a numeric measurement.

## measurements schema

```json
{
  "schema_version": 1,
  "surfaces": [{
    "id": "albums", "family": "browser", "variant": "regular",
    "owner": "app", "status": "captured",
    "environment_id": "fixture-regular",
    "measurements": [{
      "role": "contentTitle", "metric": "leading", "value": 24,
      "unit": "pt", "coordinate_space": "pane-local",
      "method": "manual", "uncertainty": 0.1,
      "evidence": ["evidence/albums.png"]
    }]
  }]
}
```

- `schema_version: 1`, `surfaces: non-empty list` (empty is invalid, never green).
- Each surface requires: `id`, `family`, `variant` (non-empty strings);
  `owner: "app" | "system"`; `status: "captured" | "blocked" | "unvisited" | "excluded"`;
  `measurements: list` (may be empty; missing/non-list is invalid).
- `environment_id`: optional-unknown. If present it must be a non-empty string;
  if missing/`null` it is treated as unknown and yields `unverified` when
  family/variant otherwise match (never invalid).
- `reason`: non-empty string required when `status` is `blocked` or `excluded`;
  optional otherwise (if present, must be non-empty string).
- Each measurement requires: `role`, `metric`, `unit`, `coordinate_space`, `method`
  (non-empty strings); `uncertainty` (finite number >= 0, not bool, required);
  `value` (finite number or `null`; missing is treated as `null`; bool/NaN/Inf/string is invalid);
  `evidence` (missing/`null` is treated as `[]`; otherwise list of non-empty strings; non-string entries are invalid).
- Duplicate surface `id`s are invalid. Duplicate `(role, metric)` within one surface is invalid.
- Unknown extra fields are tolerated.

## compare: classification

`compare CONTRACTS MEASUREMENTS --output PATH` emits:

```json
{
  "schema_version": 1, "kind": "comparison",
  "findings": [{"rule_id": "browser-title", "surface_id": "albums", "status": "pass",
                "expected": 24, "actual": 24, "reason": "...", "evidence": ["evidence/albums.png"]}],
  "summary": {"pass": 2, "fail": 1, "unverified": 1, "excluded": 1},
  "limitations": ["..."]
}
```

- `findings` sorted by `(rule_id, surface_id or "")`; `surface_id` may be `null`
  only for the no-applicable-surface gap finding. A named shared target absent
  from measurements retains its declared ID in an `unverified` gap finding.
- Each finding has `rule_id` (string), `surface_id` (string or `null`),
  `status: "pass" | "fail" | "unverified" | "excluded"`,
  `expected` (finite number or `null` where unknown; in practice always the rule value),
  `actual` (finite number or `null` where unknown), `reason` (string),
  `evidence` (list of strings). No false precision: numbers are emitted as given.
- `summary` counts findings per status.
- `limitations` are always the four strings listed under `compare` below.

Rules per `rule × surface` pair (sorted inputs for determinism):

- `owner == "system"` → `excluded` (`actual: null`, `evidence: []`).
- `status == "excluded"` → `excluded`.
- Family scope: `family`/`variant` mismatch → `excluded` (intentional variants
  stay excluded, e.g. compact inspector vs browser).
- Window/component scope: unlisted surface → `excluded`; listed app-owned,
  non-excluded surface with mismatched variant → `unverified` (capture the
  requested variant). Every listed ID missing from measurements emits an
  `unverified` gap finding. Explicitly excluded targets still need a reason.
- Otherwise the surface is applicable (`captured`/`blocked`/`unvisited` with
  matching family or explicit selection, matching variant, and `owner == "app"`):
  - `blocked`/`unvisited` → `unverified` (`actual: null`).
  - `environment_id` missing or mismatched → `unverified` (when scope and variant match).
  - No matching `(role, metric)` measurement, or `value == null`/missing → `unverified`.
  - Missing/empty `evidence` → `unverified` (even if numeric values would pass).
  - `unit` or `coordinate_space` mismatch (exact string equality) → `unverified`.
  - Else uncertainty-aware numeric verdict with `delta = abs(value - expected)`:
    - `delta + uncertainty <= tolerance` → `pass`
    - `delta - uncertainty > tolerance` → `fail`
    - otherwise (overlap) → `unverified` (in particular `delta - uncertainty == tolerance` with `uncertainty > 0` is `unverified`, not `fail`).
  - `uncertainty = 0` does not prove exactness; supplied-evidence quality remains agent responsibility.
- A rule with zero applicable surfaces additionally emits one `unverified` finding
  with `surface_id: null` and reason `no applicable surface for rule …; coverage gap, not success`.

Compare `limitations` (exact):

- `compares declared numeric metrics only; no inferred semantics or screenshot analysis`
- `supplied-evidence quality remains agent responsibility; uncertainty=0 does not prove manual measurement exact`
- `empty contracts/measurements are invalid, never green`
- `no exhaustive app coverage claim; unmeasured is unverified, never pass`

## report: Markdown

`report COMPARISON --output PATH` checks the comparison object's structure
(`schema_version`, `kind`, non-empty `findings` with `rule_id/surface_id/status/expected/actual/reason/evidence`,
`summary` non-negative ints exactly matching recomputed finding counts, unique `(rule_id, surface_id)` pairs,
`limitations` list of non-empty strings). A `pass` or `fail` finding requires
a finite actual value and non-empty evidence; a null `surface_id` is reserved
for unverified coverage gaps. It writes deterministic Markdown:

- `# UI Consistency Comparison Report`, deterministic intro (no exhaustive-coverage claim),
  `## Summary` (`pass/fail/unverified/excluded` counts),
  `## Findings` table sorted by `(rule_id, surface_id)` (`null` → `null`, empty evidence → `—`),
  `## Limitations` bullets, and a closing coverage note.
- Contradictory `summary` counts, empty `findings`, and semantically duplicate findings (same `rule_id` + `surface_id`) are invalid (exit 2), never green.
- Intrinsic `compare` limitations are always maintained in the report: any missing intrinsic entries are appended, so an empty supplied `limitations` still yields the four intrinsic bullets (never `none declared` for that case).
- Supplied text is escaped as literal Markdown table/list content; it cannot
  inject Markdown link or image syntax or raw HTML. A renderer may still
  auto-link a plain URL. The report does not recompute verdicts from contracts
  and measurements; use `compare` output as its input.
- Same overwrite/symlink/input-distinct rule as above.

## Capability limitations

- Heuristic lexical scan only; nested block comments handled, but this is not a full
  Swift parse (macros, conditional compilation, generated code and raw-string edge cases
  are best-effort; interpolation never creates hits).
- Candidate IDs are unstable across line edits; use manually curated surface IDs for persistence.
- CLI compares declared numeric metrics only; it does not infer semantics, inspect
  screenshots, or verify visual hierarchy/materials/motion/accessibility.
- System-owned presentations are navigation/integration coverage only (`excluded`), never
  measured against app body keylines and never modified.
- Tolerances/uncertainties are in declared `unit`/`coordinate_space`; cross-unit/space
  comparison is `unverified`, never auto-converted.
- No app-wide completeness proof from any output; unmeasured is `unverified`.

## Example fixtures (synthetic, consistent)

- `examples/contracts.json`: one rule `browser-title` (`browser/regular`, `contentTitle/leading`, `24 ± 0.5 pt`, `pane-local`, `fixture-regular`).
- `examples/measurements.json`: `albums` 24 (pass), `tracks` 24 (pass),
  `playlists` 32 (fail against the same 24 pt contract), `inspector-compact`
  (`inspector/compact`, excluded by family/variant), `hidden-sheet`
  (`browser/regular`, `blocked` with reason, unverified).
- `examples/expected-comparison.json`: the deterministic `compare` output for the above
  (`pass: 2, fail: 1, unverified: 1, excluded: 1`; exit 1). Regenerate with the
  `compare` command; any hand edit must preserve byte-identical determinism
  (`sort_keys`, `indent=2`).
