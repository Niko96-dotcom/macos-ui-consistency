# Contributing

Small, evidence-first contributions are welcome. Keep the package
restrained: guidance plus a deterministic helper, no taste enforcement.

## Fixtures and negative controls

- Seed at most one accidental drift per fixture page; keep an
  intentional variant (for example a compact inspector in its own
  family) that must stay excluded, not flagged.
- Every fixture change needs a seeded-bad state, an aligned state, and
  the exact `swift build` / `swift run` commands in `fixture/README.md`.
- Screenshots under `docs/images/` are reference mode only. Do not
  present them as automatic repair proof.

## Tests

- Cover CLI behavior with `unittest` under `tests/`: malformed input
  (NaN, inf, bool), duplicate IDs, empty inputs, unit/space/environment
  mismatches, uncertainty overlap, symlink and overwrite refusal,
  determinism.
- Run `python3 -m unittest discover -s tests -v` before sending a
  change. CI repeats it on Ubuntu with Python 3.10 and 3.13 and
  compile-builds the fixture on macOS 14 (no runtime coverage claimed).

## No universal aesthetic rules

- Do not add global margins, grids, widths, fonts, or control sizes.
- Contracts stay per app and family with declared tolerance, unit,
  coordinate space, and environment.
- Taste calls, grouping opinions, and re-skins are never violations.

## Privacy

- Do not submit user app data, screenshots of real apps, private
  paths, logs, or credentials.
- Destructive or account-gated flows are exercised via fixtures or
  mocks only.

## Contract and schema changes

- `schema_version` and CLI exit codes are frozen for v0.1. Any change
  requires updated examples under `examples/`, updated
  `skills/macos-ui-consistency/references/data-format.md`, new tests,
  and a note in the pull request.
- New rules or checks need a fixture case plus an entry in
  `evals/scenarios.md`.

## Runtime evidence truthfulness

- Report what was actually run, on which host and OS, with which
  fixture revision. Unrun means untested.
- Source-only work cannot claim visual verification. Missing evidence
  is unverified, never pass.
- Never silently re-baseline a failing reference to quiet it.
