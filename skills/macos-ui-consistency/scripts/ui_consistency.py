#!/usr/bin/env python3
"""Bounded deterministic helper for macOS UI consistency.

Three subcommands (legacy contracts plus explicit shared scopes):
  scan ROOT --output PATH [--force]
  compare CONTRACTS MEASUREMENTS --output PATH [--force]
  report COMPARISON --output PATH [--force]

Standard library only, Python >= 3.10. No source edits. Deterministic JSON.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import re
import sys
from pathlib import Path

SCHEMA_VERSION = 1

SCAN_LIMITATIONS = [
    "heuristic lexical scan only; not a full Swift parser",
    "comments and string literals stripped conservatively and never create hits; nested block comments handled lexically",
    "candidate IDs derived from relative path+kind+line; line edits may change IDs; manually curated surface IDs persist separately",
    "no runtime measurement and no completeness or app-wide coverage claim",
    "CLI never edits app sources",
]

COMPARE_LIMITATIONS = [
    "compares declared numeric metrics only; no inferred semantics or screenshot analysis",
    "supplied-evidence quality remains agent responsibility; uncertainty=0 does not prove manual measurement exact",
    "empty contracts/measurements are invalid, never green",
    "no exhaustive app coverage claim; unmeasured is unverified, never pass",
]

DEFAULT_IGNORE = {".git", ".build", ".swiftpm", "vendor", "node_modules", "DerivedData"}

# Whole-word keywords searched per line after lexical masking.
SCAN_RE = re.compile(
    r"\b(WindowGroup|DocumentGroup|MenuBarExtra|CommandMenu|navigationDestination|contextMenu|fileImporter|fileExporter|commands|Settings|popover|inspector|Window|sheet|alert)\b"
)


def _eprint(msg: str) -> None:
    print(msg, file=sys.stderr)


def _fail(msg: str, code: int = 2):
    _eprint(f"error: {msg}")
    raise SystemExit(code)


def _is_finite_number(v: object) -> bool:
    if isinstance(v, bool):
        return False
    if not isinstance(v, (int, float)):
        return False
    try:
        return math.isfinite(float(v))
    except Exception:
        return False


def _req_str(obj: dict, key: str, ctx: str) -> str:
    if key not in obj:
        raise ValueError(f"{ctx}: missing required field {key!r}")
    v = obj[key]
    if not isinstance(v, str) or v == "":
        raise ValueError(f"{ctx}: field {key!r} must be non-empty string")
    return v


def _reject_constant(v: str) -> None:
    raise ValueError(f"non-finite JSON constant {v!r} not allowed (no NaN/Infinity)")


def _load_json_file(path_str: str) -> object:
    p = Path(path_str)
    try:
        with p.open("r", encoding="utf-8", errors="strict") as f:
            return json.load(f, parse_constant=_reject_constant)
    except FileNotFoundError:
        raise ValueError(f"input file not found: {path_str}")
    except IsADirectoryError:
        raise ValueError(f"input path is a directory: {path_str}")
    except (OSError, UnicodeDecodeError) as e:
        raise ValueError(f"cannot read input file {path_str}: {e}")
    except json.JSONDecodeError as e:
        raise ValueError(f"invalid JSON in {path_str}: {e}")


def _ensure_output_writable(output_str: str, force: bool) -> Path:
    out = Path(output_str)
    # Refuse symlink output even with --force.
    try:
        if os.path.islink(out):
            raise ValueError(f"refuse output symlink: {output_str}")
    except OSError as e:
        raise ValueError(f"cannot stat output path {output_str}: {e}")
    if out.exists():
        if out.is_dir():
            raise ValueError(f"output path is a directory: {output_str}")
        if not force:
            raise ValueError(f"refuse to overwrite existing output (use --force): {output_str}")
    parent = out.parent
    # Parent "" means cwd; treat as ".".
    parent_str = str(parent) if str(parent) != "" else "."
    try:
        if not Path(parent_str).exists():
            raise ValueError(f"output parent directory does not exist: {parent_str}")
        if not Path(parent_str).is_dir():
            raise ValueError(f"output parent is not a directory: {parent_str}")
    except OSError as e:
        raise ValueError(f"cannot stat output parent {parent_str}: {e}")
    return out


def _resolved_nonstrict(path_str: str) -> Path:
    try:
        return Path(path_str).resolve()
    except OSError:
        return Path(os.path.abspath(path_str))


def _is_same_file(a_str: str, b_str: str) -> bool:
    try:
        if _resolved_nonstrict(a_str) == _resolved_nonstrict(b_str):
            return True
    except Exception:
        pass
    try:
        a_st = os.stat(a_str)
        b_st = os.stat(b_str)
        if (a_st.st_ino, a_st.st_dev) == (b_st.st_ino, b_st.st_dev):
            return True
    except OSError:
        pass
    return False


def _ensure_output_distinct(output_str: str, inputs: list[str]) -> None:
    for inp in inputs:
        if _is_same_file(output_str, inp):
            raise ValueError(f"refuse to overwrite input file with output: {output_str} == {inp}")


def _ensure_scan_output_not_swift(output_str: str, out_path: Path, swift_files: list[Path]) -> None:
    if out_path.suffix == ".swift" or output_str.endswith(".swift"):
        raise ValueError(f"refuse to overwrite Swift source with scan output: {output_str}")
    try:
        out_res = out_path.resolve()
    except OSError:
        out_res = Path(os.path.abspath(output_str))
    for sf in swift_files:
        try:
            sf_res = sf.resolve()
        except OSError:
            continue
        if out_res == sf_res:
            raise ValueError(f"refuse to overwrite Swift source with scan output: {output_str} == {sf}")
    try:
        if out_path.exists() and out_path.is_file():
            for sf in swift_files:
                try:
                    if os.path.samefile(out_path, sf):
                        raise ValueError(
                            f"refuse to overwrite Swift source (hardlink) with scan output: {output_str} == {sf}"
                        )
                except OSError:
                    continue
    except OSError:
        pass


def _write_json(path: Path, obj: object) -> None:
    try:
        text = json.dumps(obj, sort_keys=True, indent=2, ensure_ascii=False, allow_nan=False)
    except ValueError as e:
        raise ValueError(f"cannot encode JSON (no NaN/inf allowed): {e}")
    text += "\n"
    try:
        with path.open("w", encoding="utf-8", newline="\n") as f:
            f.write(text)
    except OSError as e:
        raise ValueError(f"cannot write output file {path}: {e}")


def _write_text(path: Path, text: str) -> None:
    if not text.endswith("\n"):
        text += "\n"
    try:
        with path.open("w", encoding="utf-8", newline="\n") as f:
            f.write(text)
    except OSError as e:
        raise ValueError(f"cannot write output file {path}: {e}")


# ---------------------------------------------------------------- scan


def _mask_swift(text: str) -> str:
    """Lexically mask comments and string literals with spaces (newlines kept).

    Handles // line comments, nested /* block comments */, single-line "..."
    strings with escapes, multiline triple-quoted strings, and # raw-string
    delimiters with one or more hashes. String interpolation contents are
    stripped as part of the string (conservative: no hits from strings).
    This is a heuristic, not a full Swift parse.
    """
    n = len(text)
    out: list[str] = []
    i = 0
    state = "normal"
    block_depth = 0
    raw_hashes = 0
    while i < n:
        c = text[i]
        nxt2 = text[i : i + 2] if i + 1 < n else ""
        nxt3 = text[i : i + 3] if i + 2 < n else ""
        if state == "normal":
            if nxt2 == "//":
                state = "line"
                out.append(" ")
                out.append(" ")
                i += 2
            elif nxt2 == "/*":
                state = "block"
                block_depth = 1
                out.append(" ")
                out.append(" ")
                i += 2
            elif c == "#":
                j = i
                while j < n and text[j] == "#":
                    j += 1
                hashes = j - i
                rest3 = text[j : j + 3]
                rest1 = text[j : j + 1]
                if rest3 == '"""':
                    state = "rawmulti"
                    raw_hashes = hashes
                    for _ in range(hashes + 3):
                        out.append(" ")
                    i = j + 3
                elif rest1 == '"':
                    state = "rawstr"
                    raw_hashes = hashes
                    for _ in range(hashes + 1):
                        out.append(" ")
                    i = j + 1
                else:
                    out.append(c)
                    i += 1
            elif nxt3 == '"""':
                state = "multi"
                out.append(" ")
                out.append(" ")
                out.append(" ")
                i += 3
            elif c == '"':
                state = "str"
                out.append(" ")
                i += 1
            else:
                out.append(c)
                i += 1
        elif state == "line":
            if c == "\n":
                state = "normal"
                out.append("\n")
            elif c == "\r":
                out.append("\r")
            else:
                out.append(" ")
            i += 1
        elif state == "block":
            if nxt2 == "/*":
                block_depth += 1
                out.append(" ")
                out.append(" ")
                i += 2
            elif nxt2 == "*/":
                block_depth -= 1
                out.append(" ")
                out.append(" ")
                i += 2
                if block_depth == 0:
                    state = "normal"
            else:
                if c == "\n":
                    out.append("\n")
                elif c == "\r":
                    out.append("\r")
                else:
                    out.append(" ")
                i += 1
        elif state == "str":
            if c == "\\":
                out.append(" ")
                i += 1
                if i < n:
                    nc = text[i]
                    if nc == "\n":
                        out.append("\n")
                    elif nc == "\r":
                        out.append("\r")
                    else:
                        out.append(" ")
                    i += 1
            elif c == '"':
                out.append(" ")
                i += 1
                state = "normal"
            elif c == "\n":
                out.append("\n")
                i += 1
                state = "normal"
            elif c == "\r":
                out.append("\r")
                i += 1
                state = "normal"
            else:
                out.append(" ")
                i += 1
        elif state == "multi":
            if nxt3 == '"""':
                out.append(" ")
                out.append(" ")
                out.append(" ")
                i += 3
                state = "normal"
            elif c == "\\" and i + 1 < n:
                out.append(" ")
                i += 1
                nc = text[i]
                if nc == "\n":
                    out.append("\n")
                elif nc == "\r":
                    out.append("\r")
                else:
                    out.append(" ")
                i += 1
            else:
                if c == "\n":
                    out.append("\n")
                elif c == "\r":
                    out.append("\r")
                else:
                    out.append(" ")
                i += 1
        elif state == "rawstr":
            if c == '"':
                j = i + 1
                k = 0
                while k < raw_hashes and j < n and text[j] == "#":
                    j += 1
                    k += 1
                if k == raw_hashes:
                    out.append(" ")
                    for _ in range(k):
                        out.append(" ")
                    i = j
                    state = "normal"
                else:
                    out.append(" ")
                    i += 1
            elif c == "\n":
                out.append("\n")
                i += 1
                state = "normal"
            elif c == "\r":
                out.append("\r")
                i += 1
                state = "normal"
            else:
                out.append(" ")
                i += 1
        elif state == "rawmulti":
            if nxt3 == '"""':
                j = i + 3
                k = 0
                while k < raw_hashes and j < n and text[j] == "#":
                    j += 1
                    k += 1
                if k == raw_hashes:
                    for _ in range(3 + k):
                        out.append(" ")
                    i = j
                    state = "normal"
                else:
                    out.append(" ")
                    out.append(" ")
                    out.append(" ")
                    i += 3
            else:
                if c == "\n":
                    out.append("\n")
                elif c == "\r":
                    out.append("\r")
                else:
                    out.append(" ")
                i += 1
        else:  # pragma: no cover - unreachable
            out.append(c)
            i += 1
    return "".join(out)


def _iter_swift_files(root_abs: Path):
    stack: list[Path] = [root_abs]
    while stack:
        cur = stack.pop()
        try:
            with os.scandir(cur) as it:
                entries = sorted(list(it), key=lambda e: e.name)
        except OSError as e:
            raise ValueError(f"cannot list directory {cur}: {e}")
        # Push dirs in reverse so pop yields sorted order.
        dirs: list[Path] = []
        for entry in entries:
            name = entry.name
            if name in DEFAULT_IGNORE:
                continue
            try:
                if entry.is_symlink():
                    continue
            except OSError as e:
                raise ValueError(f"cannot stat {entry.path}: {e}")
            try:
                is_dir = entry.is_dir(follow_symlinks=False)
            except OSError as e:
                raise ValueError(f"cannot stat {entry.path}: {e}")
            if is_dir:
                dirs.append(Path(entry.path))
            else:
                if name.endswith(".swift"):
                    yield Path(entry.path)
        for d in reversed(dirs):
            stack.append(d)


def cmd_scan(root_str: str, output_str: str, force: bool) -> int:
    try:
        out_path = _ensure_output_writable(output_str, force)
        # Never create/overwrite a Swift source, even with --force.
        if out_path.suffix == ".swift" or output_str.endswith(".swift"):
            raise ValueError(f"refuse to overwrite Swift source with scan output: {output_str}")
    except ValueError as e:
        _eprint(f"error: {e}")
        return 2
    root_p = Path(root_str)
    try:
        if os.path.islink(root_p):
            _eprint(f"error: ROOT must not be a symlink: {root_str}")
            return 2
    except OSError as e:
        _eprint(f"error: cannot stat ROOT {root_str}: {e}")
        return 2
    if not root_p.exists():
        _eprint(f"error: ROOT does not exist: {root_str}")
        return 2
    if not root_p.is_dir():
        _eprint(f"error: ROOT is not a directory: {root_str}")
        return 2
    try:
        root_abs = root_p.resolve()
    except OSError as e:
        _eprint(f"error: cannot resolve ROOT {root_str}: {e}")
        return 2
    try:
        swift_files = list(_iter_swift_files(root_abs))
    except ValueError as e:
        _eprint(f"error: {e}")
        return 2
    try:
        # Refuse output that resolves to the same file as ROOT (dir alias) or
        # to any Swift source (normalized alias, parent symlink, hardlink).
        if _is_same_file(output_str, root_str):
            raise ValueError(f"refuse to overwrite input ROOT with scan output: {output_str} == {root_str}")
        _ensure_scan_output_not_swift(output_str, out_path, swift_files)
    except ValueError as e:
        _eprint(f"error: {e}")
        return 2
    candidates: list[dict] = []
    for f in swift_files:
        try:
            with f.open("r", encoding="utf-8", errors="strict") as fh:
                text = fh.read()
        except (OSError, UnicodeDecodeError) as e:
            _eprint(f"error: cannot read Swift file {f}: {e}")
            return 2
        try:
            rel = f.relative_to(root_abs).as_posix()
        except ValueError:
            _eprint(f"error: cannot relativize path {f}")
            return 2
        masked = _mask_swift(text)
        for lineno, line in enumerate(masked.splitlines(), start=1):
            kinds = set(m.group(1) for m in SCAN_RE.finditer(line))
            for kind in kinds:
                cid = f"{rel}:{kind}:{lineno}"
                candidates.append(
                    {
                        "confidence": "candidate",
                        "id": cid,
                        "kind": kind,
                        "line": lineno,
                        "source": rel,
                    }
                )
    candidates.sort(key=lambda c: (c["source"], c["line"], c["kind"]))
    obj = {
        "candidates": candidates,
        "kind": "source-candidates",
        "limitations": list(SCAN_LIMITATIONS),
        "root": root_str,
        "schema_version": SCHEMA_VERSION,
    }
    try:
        _write_json(out_path, obj)
    except ValueError as e:
        _eprint(f"error: {e}")
        return 2
    return 0


# ---------------------------------------------------------------- compare


def _validate_contracts(data: object) -> list[dict]:
    if not isinstance(data, dict):
        raise ValueError("contracts: top-level must be an object")
    if "schema_version" not in data:
        raise ValueError("contracts: missing schema_version")
    sv = data["schema_version"]
    if type(sv) is not int or sv not in (1, 2):
        raise ValueError("contracts: schema_version must be 1 or 2")
    if "rules" not in data:
        raise ValueError("contracts: missing rules")
    rules = data["rules"]
    if not isinstance(rules, list) or len(rules) == 0:
        raise ValueError("contracts: rules must be a non-empty list (empty is never green)")
    seen: set[str] = set()
    out: list[dict] = []
    for idx, r in enumerate(rules):
        ctx = f"rules[{idx}]"
        if not isinstance(r, dict):
            raise ValueError(f"{ctx}: must be an object")
        rid = _req_str(r, "id", ctx)
        if rid in seen:
            raise ValueError(f"contracts: duplicate rule id {rid!r}")
        seen.add(rid)
        scope = r.get("scope", "family")
        if scope not in ("family", "window", "component"):
            raise ValueError(f"{ctx}: scope must be family, window, or component")
        if sv == 1 and ("scope" in r or "surface_ids" in r):
            raise ValueError(f"{ctx}: explicit scopes require contracts schema_version 2")
        targets = r.get("surface_ids")
        if scope == "family":
            family = _req_str(r, "family", ctx)
            if "surface_ids" in r:
                raise ValueError(f"{ctx}: family scope cannot specify surface_ids")
        else:
            family = None
            if "family" in r:
                raise ValueError(f"{ctx}: shared scope uses surface_ids, not family")
            if (not isinstance(targets, list) or not targets
                    or any(not isinstance(x, str) or not x.strip() for x in targets)
                    or len(set(targets)) != len(targets)):
                raise ValueError(f"{ctx}: surface_ids must be a non-empty list of unique non-empty strings")
        variant = _req_str(r, "variant", ctx)
        role = _req_str(r, "role", ctx)
        metric = _req_str(r, "metric", ctx)
        if "expected" not in r:
            raise ValueError(f"{ctx}: missing expected")
        exp = r["expected"]
        if not _is_finite_number(exp):
            raise ValueError(f"{ctx}: expected must be a finite number (not bool/NaN/inf)")
        if "tolerance" not in r:
            raise ValueError(f"{ctx}: missing tolerance")
        tol = r["tolerance"]
        if not _is_finite_number(tol) or float(tol) < 0:
            raise ValueError(f"{ctx}: tolerance must be a finite number >= 0 (not bool/NaN/inf)")
        unit = _req_str(r, "unit", ctx)
        cspace = _req_str(r, "coordinate_space", ctx)
        env = _req_str(r, "environment_id", ctx)
        auth = _req_str(r, "authority", ctx)
        out.append(
            {
                "id": rid,
                "family": family,
                "scope": scope,
                "surface_ids": targets,
                "variant": variant,
                "role": role,
                "metric": metric,
                "expected": exp,
                "tolerance": tol,
                "unit": unit,
                "coordinate_space": cspace,
                "environment_id": env,
                "authority": auth,
            }
        )
    return out


def _validate_measurements(data: object) -> list[dict]:
    if not isinstance(data, dict):
        raise ValueError("measurements: top-level must be an object")
    if "schema_version" not in data:
        raise ValueError("measurements: missing schema_version")
    sv = data["schema_version"]
    if type(sv) is not int or sv != 1:
        raise ValueError("measurements: schema_version must be 1")
    if "surfaces" not in data:
        raise ValueError("measurements: missing surfaces")
    surfaces = data["surfaces"]
    if not isinstance(surfaces, list) or len(surfaces) == 0:
        raise ValueError("measurements: surfaces must be a non-empty list (empty is never green)")
    seen: set[str] = set()
    out: list[dict] = []
    for idx, s in enumerate(surfaces):
        ctx = f"surfaces[{idx}]"
        if not isinstance(s, dict):
            raise ValueError(f"{ctx}: must be an object")
        sid = _req_str(s, "id", ctx)
        if sid in seen:
            raise ValueError(f"measurements: duplicate surface id {sid!r}")
        seen.add(sid)
        family = _req_str(s, "family", ctx)
        variant = _req_str(s, "variant", ctx)
        owner = _req_str(s, "owner", ctx)
        if owner not in ("app", "system"):
            raise ValueError(f"{ctx}: owner must be 'app' or 'system'")
        status = _req_str(s, "status", ctx)
        if status not in ("captured", "blocked", "unvisited", "excluded"):
            raise ValueError(f"{ctx}: status must be captured/blocked/unvisited/excluded")
        # environment_id: optional-unknown; if missing/None -> None (unverified later).
        env: str | None = None
        if "environment_id" in s and s["environment_id"] is not None:
            ev = s["environment_id"]
            if not isinstance(ev, str) or ev == "":
                raise ValueError(f"{ctx}: environment_id must be a non-empty string when present")
            env = ev
        # reason: required for blocked/excluded.
        reason: str | None = None
        if "reason" in s and s["reason"] is not None:
            rv = s["reason"]
            if not isinstance(rv, str) or rv == "":
                raise ValueError(f"{ctx}: reason must be a non-empty string when present")
            reason = rv
        if status in ("blocked", "excluded") and not reason:
            raise ValueError(f"{ctx}: status {status!r} requires a non-empty reason")
        if "measurements" not in s:
            raise ValueError(f"{ctx}: missing measurements")
        mlist = s["measurements"]
        if not isinstance(mlist, list):
            raise ValueError(f"{ctx}: measurements must be a list")
        seen_rm: set[tuple[str, str]] = set()
        norm_meas: list[dict] = []
        for j, m in enumerate(mlist):
            mctx = f"{ctx}.measurements[{j}]"
            if not isinstance(m, dict):
                raise ValueError(f"{mctx}: must be an object")
            role = _req_str(m, "role", mctx)
            metric = _req_str(m, "metric", mctx)
            if (role, metric) in seen_rm:
                raise ValueError(f"{ctx}: duplicate role+metric {(role, metric)!r}")
            seen_rm.add((role, metric))
            # value: missing/None allowed (unverified); else finite number.
            if "value" not in m or m["value"] is None:
                value = None
            else:
                value = m["value"]
                if not _is_finite_number(value):
                    raise ValueError(f"{mctx}: value must be a finite number or null (not bool/NaN/inf)")
            unit = _req_str(m, "unit", mctx)
            cspace = _req_str(m, "coordinate_space", mctx)
            method = _req_str(m, "method", mctx)
            if "uncertainty" not in m:
                raise ValueError(f"{mctx}: missing uncertainty")
            unc = m["uncertainty"]
            if not _is_finite_number(unc) or float(unc) < 0:
                raise ValueError(f"{mctx}: uncertainty must be a finite number >= 0 (not bool/NaN/inf)")
            # evidence: missing -> [] (unverified); present must be list of non-empty strings.
            if "evidence" not in m or m["evidence"] is None:
                evidence: list[str] = []
            else:
                evd = m["evidence"]
                if not isinstance(evd, list):
                    raise ValueError(f"{mctx}: evidence must be a list of non-empty strings")
                for k, e in enumerate(evd):
                    if not isinstance(e, str) or e == "":
                        raise ValueError(f"{mctx}.evidence[{k}]: must be a non-empty string")
                evidence = list(evd)
            norm_meas.append(
                {
                    "role": role,
                    "metric": metric,
                    "value": value,
                    "unit": unit,
                    "coordinate_space": cspace,
                    "method": method,
                    "uncertainty": unc,
                    "evidence": evidence,
                }
            )
        out.append(
            {
                "id": sid,
                "family": family,
                "variant": variant,
                "owner": owner,
                "status": status,
                "environment_id": env,
                "reason": reason,
                "measurements": norm_meas,
            }
        )
    return out


def _do_compare(rules: list[dict], surfaces: list[dict]) -> tuple[list[dict], dict]:
    rules_sorted = sorted(rules, key=lambda r: r["id"])
    surfs_sorted = sorted(surfaces, key=lambda s: s["id"])
    findings: list[dict] = []
    for rule in rules_sorted:
        applicable_ids: set[str] = set()
        for s in surfs_sorted:
            if (
                (s["family"] == rule["family"] if rule["scope"] == "family"
                 else s["id"] in rule["surface_ids"])
                and s["variant"] == rule["variant"]
                and s["owner"] == "app"
                and s["status"] != "excluded"
            ):
                applicable_ids.add(s["id"])
        for surf in surfs_sorted:
            rid = rule["id"]
            sid = surf["id"]
            exp = rule["expected"]
            if (rule["scope"] != "family" and sid in rule["surface_ids"]
                    and surf["owner"] == "app" and surf["status"] != "excluded"
                    and surf["variant"] != rule["variant"]):
                findings.append({
                    "rule_id": rid, "surface_id": sid, "status": "unverified",
                    "expected": exp, "actual": None, "evidence": [],
                    "reason": "declared shared-scope target has a different variant; capture requested variant",
                })
                continue
            if sid not in applicable_ids:
                if surf["owner"] == "system":
                    reason = "system-owned surface excluded from app contracts"
                elif surf["status"] == "excluded":
                    reason = f"surface status excluded: {surf.get('reason')}"
                elif rule["scope"] != "family":
                    reason = "surface not selected by explicit shared scope"
                elif surf["family"] != rule["family"] or surf["variant"] != rule["variant"]:
                    reason = (
                        f"family/variant mismatch: rule {rule['family']}/{rule['variant']} "
                        f"vs surface {surf['family']}/{surf['variant']}"
                    )
                else:
                    reason = "not applicable; excluded"
                findings.append(
                    {
                        "rule_id": rid,
                        "surface_id": sid,
                        "status": "excluded",
                        "expected": exp,
                        "actual": None,
                        "reason": reason,
                        "evidence": [],
                    }
                )
                continue
            # Applicable surface.
            if surf["status"] in ("blocked", "unvisited"):
                sreason = surf.get("reason")
                if sreason:
                    reason = f"surface status {surf['status']}: {sreason}"
                else:
                    reason = f"surface status {surf['status']}"
                findings.append(
                    {
                        "rule_id": rid,
                        "surface_id": sid,
                        "status": "unverified",
                        "expected": exp,
                        "actual": None,
                        "reason": reason,
                        "evidence": [],
                    }
                )
                continue
            # Captured: environment gate.
            match = None
            for m in surf["measurements"]:
                if m["role"] == rule["role"] and m["metric"] == rule["metric"]:
                    match = m
                    break
            surf_env = surf.get("environment_id")
            if surf_env is None or surf_env != rule["environment_id"]:
                if surf_env is None:
                    reason = f"environment mismatch: rule {rule['environment_id']!r} vs surface unknown"
                else:
                    reason = (
                        f"environment mismatch: rule {rule['environment_id']!r} "
                        f"vs surface {surf_env!r}"
                    )
                if match is not None and match["value"] is not None:
                    actual = match["value"]
                    evidence = list(match["evidence"])
                elif match is not None:
                    actual = None
                    evidence = list(match["evidence"])
                else:
                    actual = None
                    evidence = []
                findings.append(
                    {
                        "rule_id": rid,
                        "surface_id": sid,
                        "status": "unverified",
                        "expected": exp,
                        "actual": actual,
                        "reason": reason,
                        "evidence": evidence,
                    }
                )
                continue
            # Environment matches: measurement checks.
            if match is None:
                findings.append(
                    {
                        "rule_id": rid,
                        "surface_id": sid,
                        "status": "unverified",
                        "expected": exp,
                        "actual": None,
                        "reason": f"no matching measurement for role {rule['role']!r} metric {rule['metric']!r}",
                        "evidence": [],
                    }
                )
                continue
            if match["value"] is None:
                findings.append(
                    {
                        "rule_id": rid,
                        "surface_id": sid,
                        "status": "unverified",
                        "expected": exp,
                        "actual": None,
                        "reason": f"measurement value null/unknown for role {rule['role']!r} metric {rule['metric']!r}",
                        "evidence": list(match["evidence"]),
                    }
                )
                continue
            if not match["evidence"]:
                findings.append(
                    {
                        "rule_id": rid,
                        "surface_id": sid,
                        "status": "unverified",
                        "expected": exp,
                        "actual": match["value"],
                        "reason": f"missing evidence for role {rule['role']!r} metric {rule['metric']!r}",
                        "evidence": [],
                    }
                )
                continue
            if match["unit"] != rule["unit"] or match["coordinate_space"] != rule["coordinate_space"]:
                findings.append(
                    {
                        "rule_id": rid,
                        "surface_id": sid,
                        "status": "unverified",
                        "expected": exp,
                        "actual": match["value"],
                        "reason": (
                            f"unit/space mismatch: rule {rule['unit']!r}/{rule['coordinate_space']!r} "
                            f"vs measurement {match['unit']!r}/{match['coordinate_space']!r}"
                        ),
                        "evidence": list(match["evidence"]),
                    }
                )
                continue
            delta = abs(match["value"] - exp)  # type: ignore[operator]
            tol = rule["tolerance"]
            unc = match["uncertainty"]
            # All finite, >= 0 tolerances.
            try:
                pass_cond = (float(delta) + float(unc)) <= float(tol)
                fail_cond = (float(delta) - float(unc)) > float(tol)
            except Exception:
                findings.append(
                    {
                        "rule_id": rid,
                        "surface_id": sid,
                        "status": "unverified",
                        "expected": exp,
                        "actual": match["value"],
                        "reason": "non-numeric comparison; unverified",
                        "evidence": list(match["evidence"]),
                    }
                )
                continue
            if pass_cond:
                findings.append(
                    {
                        "rule_id": rid,
                        "surface_id": sid,
                        "status": "pass",
                        "expected": exp,
                        "actual": match["value"],
                        "reason": f"delta {delta!r} within tolerance {tol!r} (uncertainty {unc!r})",
                        "evidence": list(match["evidence"]),
                    }
                )
            elif fail_cond:
                findings.append(
                    {
                        "rule_id": rid,
                        "surface_id": sid,
                        "status": "fail",
                        "expected": exp,
                        "actual": match["value"],
                        "reason": f"delta {delta!r} exceeds tolerance {tol!r} (uncertainty {unc!r})",
                        "evidence": list(match["evidence"]),
                    }
                )
            else:
                findings.append(
                    {
                        "rule_id": rid,
                        "surface_id": sid,
                        "status": "unverified",
                        "expected": exp,
                        "actual": match["value"],
                        "reason": (
                            f"uncertainty overlap: delta {delta!r} tolerance {tol!r} "
                            f"uncertainty {unc!r}; neither pass nor fail"
                        ),
                        "evidence": list(match["evidence"]),
                    }
                )
        if rule["scope"] != "family":
            present_ids = {s["id"] for s in surfs_sorted}
            for missing_id in sorted(set(rule["surface_ids"]) - present_ids):
                findings.append({
                    "rule_id": rule["id"], "surface_id": missing_id,
                    "status": "unverified", "expected": rule["expected"],
                    "actual": None, "evidence": [],
                    "reason": "declared shared-scope target missing; coverage gap, not success",
                })
        if not applicable_ids:
            findings.append(
                {
                    "rule_id": rule["id"],
                    "surface_id": None,
                    "status": "unverified",
                    "expected": rule["expected"],
                    "actual": None,
                    "reason": (
                        f"no applicable surface for rule {rule['id']!r} "
                        f"(family {rule['family']!r} variant {rule['variant']!r}); "
                        "coverage gap, not success"
                    ),
                    "evidence": [],
                }
            )
    findings.sort(key=lambda f: (f["rule_id"], f["surface_id"] if f["surface_id"] is not None else ""))
    summary = {"pass": 0, "fail": 0, "unverified": 0, "excluded": 0}
    for f in findings:
        summary[f["status"]] += 1
    return findings, summary


def cmd_compare(contracts_str: str, measurements_str: str, output_str: str, force: bool) -> int:
    try:
        out_path = _ensure_output_writable(output_str, force)
        _ensure_output_distinct(output_str, [contracts_str, measurements_str])
    except ValueError as e:
        _eprint(f"error: {e}")
        return 2
    try:
        cdata = _load_json_file(contracts_str)
        mdata = _load_json_file(measurements_str)
    except ValueError as e:
        _eprint(f"error: {e}")
        return 2
    try:
        rules = _validate_contracts(cdata)
        surfaces = _validate_measurements(mdata)
    except ValueError as e:
        _eprint(f"error: {e}")
        return 2
    findings, summary = _do_compare(rules, surfaces)
    obj = {
        "findings": findings,
        "kind": "comparison",
        "limitations": list(COMPARE_LIMITATIONS),
        "schema_version": SCHEMA_VERSION,
        "summary": summary,
    }
    try:
        _write_json(out_path, obj)
    except ValueError as e:
        _eprint(f"error: {e}")
        return 2
    n_fail = summary["fail"]
    n_unv = summary["unverified"]
    if n_fail > 0:
        return 1
    if n_unv > 0:
        return 3
    return 0


# ---------------------------------------------------------------- report


def _validate_comparison(data: object) -> dict:
    if not isinstance(data, dict):
        raise ValueError("comparison: top-level must be an object")
    if data.get("schema_version") is None:
        raise ValueError("comparison: missing schema_version")
    sv = data["schema_version"]
    if type(sv) is not int or sv != 1:
        raise ValueError("comparison: schema_version must be 1")
    if data.get("kind") != "comparison":
        raise ValueError("comparison: kind must be 'comparison'")
    if "findings" not in data or not isinstance(data["findings"], list):
        raise ValueError("comparison: findings must be a list")
    if "summary" not in data or not isinstance(data["summary"], dict):
        raise ValueError("comparison: summary must be an object")
    for k in ("pass", "fail", "unverified", "excluded"):
        if k not in data["summary"]:
            raise ValueError(f"comparison: summary missing {k!r}")
        v = data["summary"][k]
        if type(v) is not int or v < 0:
            raise ValueError(f"comparison: summary {k!r} must be a non-negative int")
    if len(data["findings"]) == 0:
        raise ValueError("comparison: findings must be non-empty (empty is never green)")
    seen_pairs: set[tuple[str, str | None]] = set()
    recomputed = {"pass": 0, "fail": 0, "unverified": 0, "excluded": 0}
    for idx, f in enumerate(data["findings"]):
        ctx = f"findings[{idx}]"
        if not isinstance(f, dict):
            raise ValueError(f"{ctx}: must be an object")
        for k in ("rule_id", "status", "reason"):
            if k not in f:
                raise ValueError(f"{ctx}: missing {k!r}")
            if not isinstance(f[k], str) or f[k] == "":
                raise ValueError(f"{ctx}: {k!r} must be non-empty string")
        if f["status"] not in ("pass", "fail", "unverified", "excluded"):
            raise ValueError(f"{ctx}: invalid status {f['status']!r}")
        if "surface_id" not in f:
            raise ValueError(f"{ctx}: missing surface_id")
        if f["surface_id"] is not None and (not isinstance(f["surface_id"], str) or f["surface_id"] == ""):
            raise ValueError(f"{ctx}: surface_id must be non-empty string or null")
        for k in ("expected", "actual"):
            if k not in f:
                raise ValueError(f"{ctx}: missing {k!r}")
            v = f[k]
            if v is not None and not _is_finite_number(v):
                raise ValueError(f"{ctx}: {k!r} must be finite number or null")
        if "evidence" not in f or not isinstance(f["evidence"], list):
            raise ValueError(f"{ctx}: evidence must be a list")
        for e in f["evidence"]:
            if not isinstance(e, str) or e == "":
                raise ValueError(f"{ctx}: evidence entries must be non-empty strings")
        pair = (f["rule_id"], f["surface_id"])
        if pair in seen_pairs:
            raise ValueError(f"{ctx}: duplicate finding for rule_id {f['rule_id']!r} surface_id {f['surface_id']!r}")
        seen_pairs.add(pair)
        recomputed[f["status"]] += 1
    if "limitations" not in data or not isinstance(data["limitations"], list):
        raise ValueError("comparison: limitations must be a list")
    for k in ("pass", "fail", "unverified", "excluded"):
        if data["summary"][k] != recomputed[k]:
            raise ValueError(
                f"comparison: summary {data['summary']!r} inconsistent with findings counts {recomputed!r}"
            )
    return data  # type: ignore[return-value]


def _fmt_cell(v: object) -> str:
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "INVALID-BOOL"
    if isinstance(v, (int, float)):
        return repr(v)
    return str(v)


def _md_escape(s: str) -> str:
    return s.replace("|", "/").replace("\r\n", " ").replace("\n", " ").replace("\r", " ")


def cmd_report(comparison_str: str, output_str: str, force: bool) -> int:
    try:
        out_path = _ensure_output_writable(output_str, force)
        _ensure_output_distinct(output_str, [comparison_str])
    except ValueError as e:
        _eprint(f"error: {e}")
        return 2
    try:
        cdata = _load_json_file(comparison_str)
    except ValueError as e:
        _eprint(f"error: {e}")
        return 2
    try:
        comp = _validate_comparison(cdata)
    except ValueError as e:
        _eprint(f"error: {e}")
        return 2
    findings = sorted(
        comp["findings"],
        key=lambda f: (f["rule_id"], f["surface_id"] if f["surface_id"] is not None else ""),
    )
    summary = comp["summary"]
    lines: list[str] = []
    lines.append("# UI Consistency Comparison Report")
    lines.append("")
    lines.append("Deterministic human-readable report of declared numeric contracts only.")
    lines.append("No claim of exhaustive app coverage; unmeasured surfaces are unverified, never pass.")
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append(f"- pass: {summary['pass']}")
    lines.append(f"- fail: {summary['fail']}")
    lines.append(f"- unverified: {summary['unverified']}")
    lines.append(f"- excluded: {summary['excluded']}")
    lines.append("")
    lines.append("## Findings")
    lines.append("")
    lines.append("| rule_id | surface_id | status | expected | actual | reason | evidence |")
    lines.append("|---|---|---|---|---|---|---|")
    for f in findings:
        sid = f["surface_id"] if f["surface_id"] is not None else "null"
        ev = ", ".join(f["evidence"]) if f["evidence"] else "—"
        lines.append(
            f"| {_md_escape(str(f['rule_id']))} | {_md_escape(str(sid))} | "
            f"{_md_escape(str(f['status']))} | {_md_escape(_fmt_cell(f['expected']))} | "
            f"{_md_escape(_fmt_cell(f['actual']))} | {_md_escape(str(f['reason']))} | "
            f"{_md_escape(ev)} |"
        )
    lines.append("")
    lines.append("## Limitations")
    lines.append("")
    supplied_lims = comp.get("limitations", [])
    out_lims: list[str] = [str(l) for l in supplied_lims]
    for intrinsic in COMPARE_LIMITATIONS:
        if intrinsic not in out_lims:
            out_lims.append(intrinsic)
    for lim in out_lims:
        lines.append(f"- {_md_escape(str(lim))}")
    if not out_lims:
        lines.append("- none declared")
    lines.append("")
    lines.append(
        "Coverage note: this report covers declared contracts only; "
        "it is not proof of app-wide consistency or completeness."
    )
    lines.append("")
    try:
        _write_text(out_path, "\n".join(lines))
    except ValueError as e:
        _eprint(f"error: {e}")
        return 2
    return 0


# ---------------------------------------------------------------- cli


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="ui_consistency.py",
        description="Bounded deterministic helper for macOS UI consistency.",
    )
    sub = p.add_subparsers(dest="cmd", required=True)
    ps = sub.add_parser("scan", help="heuristic Swift candidate scan (read-only)")
    ps.add_argument("root", help="ROOT directory of Swift sources to scan")
    ps.add_argument("--output", required=True, help="output JSON path")
    ps.add_argument("--force", action="store_true", help="allow overwriting existing output")
    pc = sub.add_parser("compare", help="compare contracts vs measurements")
    pc.add_argument("contracts", help="contracts JSON path")
    pc.add_argument("measurements", help="measurements JSON path")
    pc.add_argument("--output", required=True, help="output comparison JSON path")
    pc.add_argument("--force", action="store_true", help="allow overwriting existing output")
    pr = sub.add_parser("report", help="render comparison as Markdown")
    pr.add_argument("comparison", help="comparison JSON path")
    pr.add_argument("--output", required=True, help="output Markdown path")
    pr.add_argument("--force", action="store_true", help="allow overwriting existing output")
    return p


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        if args.cmd == "scan":
            return cmd_scan(args.root, args.output, args.force)
        if args.cmd == "compare":
            return cmd_compare(args.contracts, args.measurements, args.output, args.force)
        if args.cmd == "report":
            return cmd_report(args.comparison, args.output, args.force)
    except BrokenPipeError:
        return 2
    return 2


if __name__ == "__main__":
    sys.exit(main())
