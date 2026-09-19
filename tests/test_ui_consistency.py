"""Tests for ui_consistency.py (legacy and explicit shared-scope contracts). unittest + subprocess CLI."""
import json
import math
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "skills" / "macos-ui-consistency" / "scripts" / "ui_consistency.py"
EXAMPLE_CONTRACTS = Path(__file__).resolve().parent.parent / "examples" / "contracts.json"
EXAMPLE_MEASUREMENTS = Path(__file__).resolve().parent.parent / "examples" / "measurements.json"
EXAMPLE_EXPECTED = Path(__file__).resolve().parent.parent / "examples" / "expected-comparison.json"


def run_cli(*args):
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        capture_output=True,
        text=True,
        timeout=30,
    )


def write_json(path, obj):
    Path(path).write_text(json.dumps(obj, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def base_rule(**kw):
    d = {
        "id": "r1",
        "family": "browser",
        "variant": "regular",
        "role": "contentTitle",
        "metric": "leading",
        "expected": 24,
        "tolerance": 0.5,
        "unit": "pt",
        "coordinate_space": "pane-local",
        "environment_id": "fixture-regular",
        "authority": "app-decision",
    }
    d.update(kw)
    return d


def base_meas(**kw):
    d = {
        "role": "contentTitle",
        "metric": "leading",
        "value": 24,
        "unit": "pt",
        "coordinate_space": "pane-local",
        "method": "manual",
        "uncertainty": 0,
        "evidence": ["evidence/a.png"],
    }
    d.update(kw)
    return d


def base_surf(**kw):
    d = {
        "id": "s1",
        "family": "browser",
        "variant": "regular",
        "owner": "app",
        "status": "captured",
        "environment_id": "fixture-regular",
        "measurements": [base_meas()],
    }
    d.update(kw)
    return d


class ScanTests(unittest.TestCase):
    def test_scan_basic_hit_and_schema(self):
        with tempfile.TemporaryDirectory() as td:
            src = Path(td) / "src"
            src.mkdir()
            (src / "App.swift").write_text(
                "import SwiftUI\nstruct App: App {\nvar body: some Scene {\nWindowGroup { ContentView() }\n}\n}\n",
                encoding="utf-8",
            )
            out = Path(td) / "out.json"
            r = run_cli("scan", str(src), "--output", str(out))
            self.assertEqual(r.returncode, 0, r.stderr)
            obj = read_json(out)
            self.assertEqual(obj["schema_version"], 1)
            self.assertEqual(obj["kind"], "source-candidates")
            self.assertIn("limitations", obj)
            self.assertTrue(any("not a full Swift parser" in s for s in obj["limitations"]))
            self.assertEqual(len(obj["candidates"]), 1)
            c = obj["candidates"][0]
            self.assertEqual(c["kind"], "WindowGroup")
            self.assertEqual(c["source"], "App.swift")
            self.assertEqual(c["line"], 4)
            self.assertEqual(c["confidence"], "candidate")
            self.assertEqual(c["id"], "App.swift:WindowGroup:4")

    def test_scan_strips_comments_strings_and_nested_block(self):
        with tempfile.TemporaryDirectory() as td:
            src = Path(td) / "src"
            src.mkdir()
            (src / "A.swift").write_text(
                "// WindowGroup in line comment should not hit\n"
                'let s = "WindowGroup in string should not hit"\n'
                "/* outer /* nested WindowGroup inside */ still comment WindowGroup */\n"
                "/* closed */\n"
                "struct X { var b: some Scene { WindowGroup { Text(\"hi\") } } }\n"
                '.sheet(isPresented: $x) { Text("y") }\n'
                'let t = """\nWindowGroup inside multiline string\n"""\n',
                encoding="utf-8",
            )
            out = Path(td) / "out.json"
            r = run_cli("scan", str(src), "--output", str(out))
            self.assertEqual(r.returncode, 0, r.stderr)
            obj = read_json(out)
            kinds_lines = sorted((c["kind"], c["line"]) for c in obj["candidates"])
            # Only real code hits: WindowGroup line 5, sheet line 6.
            self.assertEqual(kinds_lines, [("WindowGroup", 5), ("sheet", 6)])

    def test_scan_multiline_modifier_form(self):
        with tempfile.TemporaryDirectory() as td:
            src = Path(td) / "src"
            src.mkdir()
            (src / "B.swift").write_text(
                "struct V: View {\nvar body: some View {\nText(\"a\")\n.sheet(\nisPresented: $x) { Text(\"b\") }\n}\n}\n",
                encoding="utf-8",
            )
            out = Path(td) / "out.json"
            r = run_cli("scan", str(src), "--output", str(out))
            self.assertEqual(r.returncode, 0, r.stderr)
            obj = read_json(out)
            self.assertTrue(any(c["kind"] == "sheet" for c in obj["candidates"]))

    def test_scan_ignores_default_dirs_and_sorted(self):
        with tempfile.TemporaryDirectory() as td:
            src = Path(td) / "src"
            src.mkdir()
            (src / "B.swift").write_text("struct B { var b: some Scene { WindowGroup { Text(1) } } }\n", encoding="utf-8")
            (src / "A.swift").write_text("struct A: View { func f() -> some View { Text(1).sheet(isPresented: $x){ Text(2) } } }\n", encoding="utf-8")
            gitd = src / ".git"
            gitd.mkdir()
            (gitd / "Hidden.swift").write_text("WindowGroup { }\n", encoding="utf-8")
            bd = src / ".build"
            bd.mkdir()
            (bd / "Gen.swift").write_text("WindowGroup { }\n", encoding="utf-8")
            out = Path(td) / "out.json"
            r = run_cli("scan", str(src), "--output", str(out))
            self.assertEqual(r.returncode, 0, r.stderr)
            obj = read_json(out)
            sources = [c["source"] for c in obj["candidates"]]
            self.assertEqual(sources, sorted(sources))
            self.assertNotIn(".git/Hidden.swift", sources)
            self.assertFalse(any(".build" in s for s in sources))

    def test_scan_skips_symlinks(self):
        with tempfile.TemporaryDirectory() as td:
            src = Path(td) / "src"
            src.mkdir()
            real = src / "Real.swift"
            real.write_text("WindowGroup { }\n", encoding="utf-8")
            link = src / "Link.swift"
            try:
                os.symlink(str(real), str(link))
            except (OSError, NotImplementedError) as e:
                self.skipTest(f"symlinks unavailable: {e}")
            linkdir_target = Path(td) / "other"
            linkdir_target.mkdir()
            (linkdir_target / "Other.swift").write_text("struct Z { func f(){ Text(1).sheet(isPresented:$x){Text(2)} } }\n", encoding="utf-8")
            linkdir = src / "linkeddir"
            try:
                os.symlink(str(linkdir_target), str(linkdir))
            except (OSError, NotImplementedError) as e:
                self.skipTest(f"symlinks unavailable: {e}")
            out = Path(td) / "out.json"
            r = run_cli("scan", str(src), "--output", str(out))
            self.assertEqual(r.returncode, 0, r.stderr)
            obj = read_json(out)
            sources = [c["source"] for c in obj["candidates"]]
            # Only Real.swift hit; symlinked file and symlinked dir contents skipped.
            self.assertEqual(sources, ["Real.swift"])
            self.assertTrue(all(c["kind"] == "WindowGroup" for c in obj["candidates"]))

    def test_scan_refuses_overwrite_and_symlink_output(self):
        with tempfile.TemporaryDirectory() as td:
            src = Path(td) / "src"
            src.mkdir()
            (src / "A.swift").write_text("WindowGroup { }\n", encoding="utf-8")
            out = Path(td) / "out.json"
            out.write_text("{}", encoding="utf-8")
            r = run_cli("scan", str(src), "--output", str(out))
            self.assertEqual(r.returncode, 2)
            # With --force it overwrites.
            r2 = run_cli("scan", str(src), "--output", str(out), "--force")
            self.assertEqual(r2.returncode, 0, r2.stderr)
            # Symlink output refused even with --force.
            real_out = Path(td) / "real.json"
            link_out = Path(td) / "link.json"
            try:
                os.symlink(str(real_out), str(link_out))
            except (OSError, NotImplementedError) as e:
                self.skipTest(f"symlinks unavailable: {e}")
            r3 = run_cli("scan", str(src), "--output", str(link_out), "--force")
            self.assertEqual(r3.returncode, 2)

    def test_scan_invalid_root_and_read_failure_no_misleading_complete(self):
        with tempfile.TemporaryDirectory() as td:
            out = Path(td) / "out.json"
            r = run_cli("scan", str(Path(td) / "nope"), "--output", str(out))
            self.assertEqual(r.returncode, 2)
            self.assertFalse(out.exists())
            # ROOT is a file, not a dir.
            f = Path(td) / "file.txt"
            f.write_text("hi", encoding="utf-8")
            r2 = run_cli("scan", str(f), "--output", str(out))
            self.assertEqual(r2.returncode, 2)
            self.assertFalse(out.exists())
            # Invalid UTF-8 Swift file -> error, no output.
            src = Path(td) / "src2"
            src.mkdir()
            (src / "Bad.swift").write_bytes(b"WindowGroup \xff\xfe invalid\n")
            r3 = run_cli("scan", str(src), "--output", str(out))
            self.assertEqual(r3.returncode, 2)
            self.assertFalse(out.exists())

    def test_scan_repeat_deterministic(self):
        with tempfile.TemporaryDirectory() as td:
            src = Path(td) / "src"
            src.mkdir()
            (src / "A.swift").write_text("WindowGroup { }\nText(1).sheet(isPresented:$x){Text(2)}\n", encoding="utf-8")
            o1 = Path(td) / "o1.json"
            o2 = Path(td) / "o2.json"
            self.assertEqual(run_cli("scan", str(src), "--output", str(o1)).returncode, 0)
            self.assertEqual(run_cli("scan", str(src), "--output", str(o2)).returncode, 0)
            self.assertEqual(o1.read_bytes(), o2.read_bytes())


class CompareTests(unittest.TestCase):
    def _run_compare(self, td, contracts, measurements, expect_code=None):
        c = Path(td) / "c.json"
        m = Path(td) / "m.json"
        o = Path(td) / "o.json"
        if o.exists():
            o.unlink()
        write_json(c, contracts)
        write_json(m, measurements)
        r = run_cli("compare", str(c), str(m), "--output", str(o))
        if expect_code is not None:
            self.assertEqual(r.returncode, expect_code, r.stderr)
        return r, o

    def test_shared_scopes_compare_only_named_consumers_across_families(self):
        for scope in ("window", "component"):
            with self.subTest(scope=scope), tempfile.TemporaryDirectory() as td:
                rule = base_rule(scope=scope, surface_ids=["nav", "options"])
                del rule["family"]
                surfaces = [base_surf(id="nav", family="navigation"),
                            base_surf(id="options", family="inspector",
                                      measurements=[base_meas(value=30)]),
                            base_surf(id="unrelated", family="inspector")]
                _, out = self._run_compare(td, {"schema_version": 2, "rules": [rule]},
                                          {"schema_version": 1, "surfaces": surfaces}, 1)
                self.assertEqual({f["surface_id"]: f["status"] for f in read_json(out)["findings"]},
                                 {"nav": "pass", "options": "fail", "unrelated": "excluded"})

    def test_shared_scope_missing_target_is_not_silent_success(self):
        with tempfile.TemporaryDirectory() as td:
            rule = base_rule(scope="window", surface_ids=["s1", "missing"])
            del rule["family"]
            _, out = self._run_compare(td, {"schema_version": 2, "rules": [rule]},
                                      {"schema_version": 1, "surfaces": [base_surf()]}, 3)
            obj = read_json(out)
            self.assertEqual(obj["summary"]["pass"], 1)
            gap = next(f for f in obj["findings"] if f["surface_id"] == "missing")
            self.assertEqual(gap["status"], "unverified")
            report = Path(td) / "report.md"
            r = run_cli("report", str(out), "--output", str(report))
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertIn("missing", report.read_text())

    def test_shared_scope_preserves_evidence_and_ownership_gates(self):
        cases = [
            ({"variant": "compact"}, "unverified", 3),
            ({"environment_id": "other"}, "unverified", 3),
            ({"status": "blocked", "reason": "permission"}, "unverified", 3),
            ({"status": "unvisited"}, "unverified", 3),
            ({"measurements": []}, "unverified", 3),
            ({"measurements": [base_meas(evidence=[])]}, "unverified", 3),
            ({"measurements": [base_meas(coordinate_space="window-local")]}, "unverified", 3),
            ({"measurements": [base_meas(uncertainty=1)]}, "unverified", 3),
            ({"owner": "system"}, "excluded", 0),
            ({"status": "excluded", "reason": "intentional exception"}, "excluded", 0),
        ]
        for changes, status, code in cases:
            with self.subTest(changes=changes), tempfile.TemporaryDirectory() as td:
                rule = base_rule(scope="component", surface_ids=["s1", "target"])
                del rule["family"]
                _, out = self._run_compare(td, {"schema_version": 2, "rules": [rule]},
                                          {"schema_version": 1, "surfaces": [
                                              base_surf(), base_surf(id="target", family="inspector", **changes)]}, code)
                target = next(f for f in read_json(out)["findings"] if f["surface_id"] == "target")
                self.assertEqual(target["status"], status)

    def test_shared_scope_rejects_ambiguous_or_malformed_selection(self):
        cases = [
            {"scope": "window"},
            {"scope": "window", "surface_ids": []},
            {"scope": "window", "surface_ids": "s1"},
            {"scope": "window", "surface_ids": ["s1", "s1"]},
            {"scope": "window", "surface_ids": [" "]},
            {"scope": "window", "surface_ids": [{}]},
            {"scope": "window", "surface_ids": ["s1"], "family": "browser"},
            {"scope": "family", "surface_ids": ["s1"], "family": "browser"},
            {"scope": "unknown"}, {"scope": []},
        ]
        for fields in cases:
            with self.subTest(fields=fields), tempfile.TemporaryDirectory() as td:
                rule = base_rule()
                del rule["family"]
                rule.update(fields)
                _, out = self._run_compare(td, {"schema_version": 2, "rules": [rule]},
                                          {"schema_version": 1, "surfaces": [base_surf()]}, 2)
                self.assertFalse(out.exists())

    def test_scope_extension_requires_v2_and_legacy_results_are_unchanged(self):
        with tempfile.TemporaryDirectory() as td:
            rule = base_rule(scope="window", surface_ids=["s1"])
            self._run_compare(td, {"schema_version": 1, "rules": [rule]},
                              {"schema_version": 1, "surfaces": [base_surf()]}, 2)
            legacy = read_json(EXAMPLE_CONTRACTS)
            _, out = self._run_compare(td, legacy, read_json(EXAMPLE_MEASUREMENTS), 1)
            self.assertEqual(out.read_bytes(), EXAMPLE_EXPECTED.read_bytes())
            legacy["schema_version"] = 2
            legacy["rules"][0]["scope"] = "family"
            _, out = self._run_compare(td, legacy, read_json(EXAMPLE_MEASUREMENTS), 1)
            self.assertEqual(out.read_bytes(), EXAMPLE_EXPECTED.read_bytes())

    def test_shared_scope_determinism_and_no_applicable_gap(self):
        with tempfile.TemporaryDirectory() as td:
            rule = base_rule(scope="window", surface_ids=["missing", "s1"])
            del rule["family"]
            contracts = {"schema_version": 2, "rules": [rule]}
            measurements = {"schema_version": 1, "surfaces": [base_surf(owner="system"), base_surf(id="other")]}
            _, out = self._run_compare(td, contracts, measurements, 3)
            before = out.read_bytes()
            self.assertTrue(any(f["surface_id"] is None and f["status"] == "unverified"
                                for f in read_json(out)["findings"]))
            rule["surface_ids"].reverse()
            measurements["surfaces"].reverse()
            _, out = self._run_compare(td, contracts, measurements, 3)
            self.assertEqual(before, out.read_bytes())

    def test_compare_pass_exit0(self):
        with tempfile.TemporaryDirectory() as td:
            contracts = {"schema_version": 1, "rules": [base_rule()]}
            measurements = {"schema_version": 1, "surfaces": [base_surf()]}
            r, o = self._run_compare(td, contracts, measurements, expect_code=0)
            obj = read_json(o)
            self.assertEqual(obj["summary"], {"excluded": 0, "fail": 0, "pass": 1, "unverified": 0})
            f = obj["findings"][0]
            self.assertEqual(f["status"], "pass")
            self.assertEqual(f["actual"], 24)
            self.assertEqual(f["expected"], 24)

    def test_compare_fail_exit1(self):
        with tempfile.TemporaryDirectory() as td:
            m = base_meas(value=32, uncertainty=0.1)
            contracts = {"schema_version": 1, "rules": [base_rule()]}
            measurements = {"schema_version": 1, "surfaces": [base_surf(measurements=[m])]}
            r, o = self._run_compare(td, contracts, measurements, expect_code=1)
            obj = read_json(o)
            self.assertEqual(obj["summary"]["fail"], 1)
            self.assertEqual(obj["findings"][0]["status"], "fail")

    def test_compare_empty_never_green(self):
        with tempfile.TemporaryDirectory() as td:
            c = Path(td) / "c.json"
            m = Path(td) / "m.json"
            o = Path(td) / "o.json"
            write_json(c, {"schema_version": 1, "rules": []})
            write_json(m, {"schema_version": 1, "surfaces": [base_surf()]})
            r = run_cli("compare", str(c), str(m), "--output", str(o))
            self.assertEqual(r.returncode, 2)
            write_json(c, {"schema_version": 1, "rules": [base_rule()]})
            write_json(m, {"schema_version": 1, "surfaces": []})
            r2 = run_cli("compare", str(c), str(m), "--output", str(o), "--force")
            self.assertEqual(r2.returncode, 2)

    def test_compare_duplicate_ids_invalid(self):
        with tempfile.TemporaryDirectory() as td:
            contracts = {"schema_version": 1, "rules": [base_rule(id="dup"), base_rule(id="dup")]}
            measurements = {"schema_version": 1, "surfaces": [base_surf()]}
            r, _ = self._run_compare(td, contracts, measurements)
            self.assertEqual(r.returncode, 2)
            # Duplicate surface ids.
            s1 = base_surf(id="dup")
            s2 = base_surf(id="dup")
            contracts2 = {"schema_version": 1, "rules": [base_rule()]}
            measurements2 = {"schema_version": 1, "surfaces": [s1, s2]}
            r2, _ = self._run_compare(td, contracts2, measurements2)
            self.assertEqual(r2.returncode, 2)
            # Duplicate role+metric within a surface.
            bad = base_surf(measurements=[base_meas(), base_meas()])
            r3, _ = self._run_compare(td, contracts2, {"schema_version": 1, "surfaces": [bad]})
            self.assertEqual(r3.returncode, 2)

    def test_compare_bool_nan_inf_invalid(self):
        with tempfile.TemporaryDirectory() as td:
            # Bool expected invalid.
            contracts = {"schema_version": 1, "rules": [base_rule(expected=True)]}
            measurements = {"schema_version": 1, "surfaces": [base_surf()]}
            r, _ = self._run_compare(td, contracts, measurements)
            self.assertEqual(r.returncode, 2)
            # Bool tolerance invalid.
            contracts2 = {"schema_version": 1, "rules": [base_rule(tolerance=False)]}
            r2, _ = self._run_compare(td, contracts2, measurements)
            self.assertEqual(r2.returncode, 2)
            # NaN literal invalid (non-standard JSON).
            c = Path(td) / "c.json"
            m = Path(td) / "m.json"
            o = Path(td) / "o.json"
            c.write_text(
                '{"schema_version": 1, "rules": [{"id": "r1", "family": "browser", "variant": "regular", '
                '"role": "contentTitle", "metric": "leading", "expected": NaN, "tolerance": 0.5, '
                '"unit": "pt", "coordinate_space": "pane-local", "environment_id": "fixture-regular", '
                '"authority": "app-decision"}]}',
                encoding="utf-8",
            )
            write_json(m, measurements)
            r3 = run_cli("compare", str(c), str(m), "--output", str(o))
            self.assertEqual(r3.returncode, 2)
            # Infinity value invalid.
            c.write_text(
                '{"schema_version": 1, "rules": [{"id": "r1", "family": "browser", "variant": "regular", '
                '"role": "contentTitle", "metric": "leading", "expected": 24, "tolerance": 0.5, '
                '"unit": "pt", "coordinate_space": "pane-local", "environment_id": "fixture-regular", '
                '"authority": "app-decision"}]}',
                encoding="utf-8",
            )
            m.write_text(
                '{"schema_version": 1, "surfaces": [{"id": "s1", "family": "browser", "variant": "regular", '
                '"owner": "app", "status": "captured", "environment_id": "fixture-regular", '
                '"measurements": [{"role": "contentTitle", "metric": "leading", "value": Infinity, '
                '"unit": "pt", "coordinate_space": "pane-local", "method": "manual", '
                '"uncertainty": 0, "evidence": ["e.png"]}]}]}',
                encoding="utf-8",
            )
            r4 = run_cli("compare", str(c), str(m), "--output", str(o), "--force")
            self.assertEqual(r4.returncode, 2)
            # Bool value invalid.
            bad_meas = base_surf(measurements=[base_meas(value=True)])
            r5, _ = self._run_compare(td, {"schema_version": 1, "rules": [base_rule()]}, {"schema_version": 1, "surfaces": [bad_meas]})
            self.assertEqual(r5.returncode, 2)
            # Negative tolerance / uncertainty invalid.
            r6, _ = self._run_compare(td, {"schema_version": 1, "rules": [base_rule(tolerance=-0.1)]}, {"schema_version": 1, "surfaces": [base_surf()]})
            self.assertEqual(r6.returncode, 2)
            r7, _ = self._run_compare(td, {"schema_version": 1, "rules": [base_rule()]}, {"schema_version": 1, "surfaces": [base_surf(measurements=[base_meas(uncertainty=-1)])]})
            self.assertEqual(r7.returncode, 2)

    def test_compare_unknown_fields_tolerated(self):
        with tempfile.TemporaryDirectory() as td:
            rule = base_rule()
            rule["extra_unknown"] = {"nested": [1, 2]}
            surf = base_surf()
            surf["extra"] = 123
            meas = surf["measurements"][0]
            meas["extra2"] = "hi"
            contracts = {"schema_version": 1, "rules": [rule], "_note": "synthetic"}
            measurements = {"schema_version": 1, "surfaces": [surf], "_note": "x"}
            r, o = self._run_compare(td, contracts, measurements, expect_code=0)
            self.assertEqual(read_json(o)["summary"]["pass"], 1)

    def test_compare_missing_role_value_null_missing_evidence_unverified(self):
        with tempfile.TemporaryDirectory() as td:
            contracts = {"schema_version": 1, "rules": [base_rule()]}
            # No matching role.
            s_nomatch = base_surf(id="a", measurements=[base_meas(role="otherRole")])
            # Null value.
            s_null = base_surf(id="b", measurements=[base_meas(value=None)])
            # Missing value key treated as null.
            m_missing = base_meas()
            del m_missing["value"]
            s_missing_val = base_surf(id="c", measurements=[m_missing])
            # Empty evidence.
            s_noev = base_surf(id="d", measurements=[base_meas(evidence=[])])
            # Missing evidence key.
            m_noevkey = base_meas()
            del m_noevkey["evidence"]
            s_noevkey = base_surf(id="e", measurements=[m_noevkey])
            measurements = {"schema_version": 1, "surfaces": [s_nomatch, s_null, s_missing_val, s_noev, s_noevkey]}
            r, o = self._run_compare(td, contracts, measurements, expect_code=3)
            obj = read_json(o)
            self.assertEqual(obj["summary"]["unverified"], 5)
            self.assertEqual(obj["summary"]["fail"], 0)
            by_id = {f["surface_id"]: f for f in obj["findings"]}
            self.assertIn("no matching measurement", by_id["a"]["reason"])
            self.assertIn("null", by_id["b"]["reason"])
            self.assertIn("missing evidence", by_id["d"]["reason"])

    def test_compare_unit_space_env_mismatch_unverified(self):
        with tempfile.TemporaryDirectory() as td:
            contracts = {"schema_version": 1, "rules": [base_rule()]}
            s_unit = base_surf(id="u", measurements=[base_meas(unit="px")])
            s_space = base_surf(id="s", measurements=[base_meas(coordinate_space="screen")])
            s_env = base_surf(id="e", environment_id="other-env")
            s_noenv = base_surf(id="n")
            del s_noenv["environment_id"]
            measurements = {"schema_version": 1, "surfaces": [s_unit, s_space, s_env, s_noenv]}
            r, o = self._run_compare(td, contracts, measurements, expect_code=3)
            obj = read_json(o)
            self.assertEqual(obj["summary"]["unverified"], 4)
            by_id = {f["surface_id"]: f for f in obj["findings"]}
            self.assertIn("unit/space", by_id["u"]["reason"])
            self.assertIn("unit/space", by_id["s"]["reason"])
            self.assertIn("environment mismatch", by_id["e"]["reason"])
            self.assertIn("environment mismatch", by_id["n"]["reason"])

    def test_compare_uncertainty_overlap(self):
        with tempfile.TemporaryDirectory() as td:
            # delta 0.6, tol 0.5, unc 0.2 -> overlap (0.8 > 0.5, 0.4 <= 0.5) => unverified.
            contracts = {"schema_version": 1, "rules": [base_rule(expected=24, tolerance=0.5)]}
            s_over = base_surf(id="over", measurements=[base_meas(value=24.6, uncertainty=0.2)])
            # delta 0.4, tol 0.5, unc 0.1 -> pass (0.5 <= 0.5).
            s_pass = base_surf(id="p", measurements=[base_meas(value=24.4, uncertainty=0.1)])
            # delta 1.0, tol 0.5, unc 0.1 -> fail (0.9 > 0.5).
            s_fail = base_surf(id="f", measurements=[base_meas(value=25.0, uncertainty=0.1)])
            measurements = {"schema_version": 1, "surfaces": [s_over, s_pass, s_fail]}
            r, o = self._run_compare(td, contracts, measurements, expect_code=1)
            obj = read_json(o)
            by_id = {f["surface_id"]: f for f in obj["findings"]}
            self.assertEqual(by_id["over"]["status"], "unverified")
            self.assertIn("overlap", by_id["over"]["reason"])
            self.assertEqual(by_id["p"]["status"], "pass")
            self.assertEqual(by_id["f"]["status"], "fail")

    def test_compare_no_applicable_surface_null_finding(self):
        with tempfile.TemporaryDirectory() as td:
            contracts = {"schema_version": 1, "rules": [base_rule(family="browser", variant="regular")]}
            other = base_surf(id="other", family="inspector", variant="compact")
            measurements = {"schema_version": 1, "surfaces": [other]}
            r, o = self._run_compare(td, contracts, measurements, expect_code=3)
            obj = read_json(o)
            # One excluded (mismatch) + one null unverified gap.
            statuses = sorted(f["status"] for f in obj["findings"])
            self.assertEqual(statuses, ["excluded", "unverified"])
            nulls = [f for f in obj["findings"] if f["surface_id"] is None]
            self.assertEqual(len(nulls), 1)
            self.assertIn("no applicable surface", nulls[0]["reason"])

    def test_compare_system_and_family_excluded_blocked_unvisited(self):
        with tempfile.TemporaryDirectory() as td:
            contracts = {"schema_version": 1, "rules": [base_rule()]}
            s_sys = base_surf(id="sys", owner="system")
            s_fam = base_surf(id="fam", family="other")
            s_blocked = base_surf(id="blk", status="blocked", reason="gate", measurements=[])
            s_unvis = base_surf(id="unv", status="unvisited", measurements=[])
            s_ok = base_surf(id="ok")
            measurements = {"schema_version": 1, "surfaces": [s_sys, s_fam, s_blocked, s_unvis, s_ok]}
            r, o = self._run_compare(td, contracts, measurements, expect_code=3)
            obj = read_json(o)
            by_id = {f["surface_id"]: f for f in obj["findings"]}
            self.assertEqual(by_id["sys"]["status"], "excluded")
            self.assertEqual(by_id["fam"]["status"], "excluded")
            self.assertEqual(by_id["blk"]["status"], "unverified")
            self.assertEqual(by_id["unv"]["status"], "unverified")
            self.assertEqual(by_id["ok"]["status"], "pass")
            # Blocked/excluded without reason invalid.
            bad = base_surf(id="bad", status="blocked", measurements=[])
            # base_surf includes no reason by default; blocked without reason must be invalid.
            r2, _ = self._run_compare(td, contracts, {"schema_version": 1, "surfaces": [bad]})
            self.assertEqual(r2.returncode, 2)

    def test_compare_excluded_status_and_owner_system(self):
        with tempfile.TemporaryDirectory() as td:
            contracts = {"schema_version": 1, "rules": [base_rule()]}
            s_exc = base_surf(id="exc", status="excluded", reason="intentional", measurements=[])
            measurements = {"schema_version": 1, "surfaces": [s_exc]}
            r, o = self._run_compare(td, contracts, measurements, expect_code=3)
            obj = read_json(o)
            # excluded surface + null gap unverified.
            by_id = {f["surface_id"]: f for f in obj["findings"] if f["surface_id"] is not None}
            self.assertEqual(by_id["exc"]["status"], "excluded")

    def test_compare_deterministic_repeat_and_no_nan(self):
        with tempfile.TemporaryDirectory() as td:
            contracts = {"schema_version": 1, "rules": [base_rule()]}
            measurements = {"schema_version": 1, "surfaces": [base_surf(id="b"), base_surf(id="a")]}
            c = Path(td) / "c.json"
            m = Path(td) / "m.json"
            o1 = Path(td) / "o1.json"
            o2 = Path(td) / "o2.json"
            write_json(c, contracts)
            write_json(m, measurements)
            self.assertEqual(run_cli("compare", str(c), str(m), "--output", str(o1)).returncode, 0)
            self.assertEqual(run_cli("compare", str(c), str(m), "--output", str(o2)).returncode, 0)
            self.assertEqual(o1.read_bytes(), o2.read_bytes())
            raw = o1.read_text(encoding="utf-8")
            self.assertNotIn("NaN", raw)
            self.assertNotIn("Infinity", raw)
            obj = json.loads(raw)
            for f in obj["findings"]:
                for k in ("expected", "actual"):
                    v = f[k]
                    if v is not None:
                        self.assertFalse(isinstance(v, bool))
                        self.assertTrue(math.isfinite(float(v)))

    def test_compare_paths_overwrite(self):
        with tempfile.TemporaryDirectory() as td:
            contracts = {"schema_version": 1, "rules": [base_rule()]}
            measurements = {"schema_version": 1, "surfaces": [base_surf()]}
            c = Path(td) / "c.json"
            m = Path(td) / "m.json"
            o = Path(td) / "o.json"
            write_json(c, contracts)
            write_json(m, measurements)
            o.write_text("{}", encoding="utf-8")
            r = run_cli("compare", str(c), str(m), "--output", str(o))
            self.assertEqual(r.returncode, 2)
            r2 = run_cli("compare", str(c), str(m), "--output", str(o), "--force")
            self.assertEqual(r2.returncode, 0)
            # Symlink output refused.
            real = Path(td) / "real.json"
            link = Path(td) / "link.json"
            try:
                os.symlink(str(real), str(link))
            except (OSError, NotImplementedError) as e:
                self.skipTest(f"symlinks unavailable: {e}")
            r3 = run_cli("compare", str(c), str(m), "--output", str(link), "--force")
            self.assertEqual(r3.returncode, 2)


class ReportTests(unittest.TestCase):
    def _make_comparison(self, td):
        contracts = {"schema_version": 1, "rules": [base_rule()]}
        measurements = {"schema_version": 1, "surfaces": [base_surf()]}
        c = Path(td) / "c.json"
        m = Path(td) / "m.json"
        o = Path(td) / "comp.json"
        write_json(c, contracts)
        write_json(m, measurements)
        r = run_cli("compare", str(c), str(m), "--output", str(o))
        self.assertEqual(r.returncode, 0)
        return o

    def test_report_basic_and_schema(self):
        with tempfile.TemporaryDirectory() as td:
            comp = self._make_comparison(td)
            out = Path(td) / "r.md"
            r = run_cli("report", str(comp), "--output", str(out))
            self.assertEqual(r.returncode, 0, r.stderr)
            text = out.read_text(encoding="utf-8")
            self.assertIn("# UI Consistency Comparison Report", text)
            self.assertIn("## Summary", text)
            self.assertIn("## Findings", text)
            self.assertIn("## Limitations", text)
            self.assertIn("pass: 1", text)
            self.assertIn("no claim of exhaustive", text.lower())

    def test_report_invalid_and_overwrite(self):
        with tempfile.TemporaryDirectory() as td:
            bad = Path(td) / "bad.json"
            bad.write_text('{"schema_version": 1, "kind": "wrong"}', encoding="utf-8")
            out = Path(td) / "r.md"
            r = run_cli("report", str(bad), "--output", str(out))
            self.assertEqual(r.returncode, 2)
            comp = self._make_comparison(td)
            out.write_text("x", encoding="utf-8")
            r2 = run_cli("report", str(comp), "--output", str(out))
            self.assertEqual(r2.returncode, 2)
            r3 = run_cli("report", str(comp), "--output", str(out), "--force")
            self.assertEqual(r3.returncode, 0)

    def test_report_deterministic(self):
        with tempfile.TemporaryDirectory() as td:
            comp = self._make_comparison(td)
            o1 = Path(td) / "a.md"
            o2 = Path(td) / "b.md"
            self.assertEqual(run_cli("report", str(comp), "--output", str(o1)).returncode, 0)
            self.assertEqual(run_cli("report", str(comp), "--output", str(o2)).returncode, 0)
            self.assertEqual(o1.read_bytes(), o2.read_bytes())


class ExamplesTests(unittest.TestCase):
    def test_examples_exist_and_consistent(self):
        self.assertTrue(EXAMPLE_CONTRACTS.exists(), "examples/contracts.json missing")
        self.assertTrue(EXAMPLE_MEASUREMENTS.exists(), "examples/measurements.json missing")
        self.assertTrue(EXAMPLE_EXPECTED.exists(), "examples/expected-comparison.json missing")
        contracts = json.loads(EXAMPLE_CONTRACTS.read_text(encoding="utf-8"))
        measurements = json.loads(EXAMPLE_MEASUREMENTS.read_text(encoding="utf-8"))
        expected = json.loads(EXAMPLE_EXPECTED.read_text(encoding="utf-8"))
        # Synthetic label present in inputs (tolerated unknown field).
        self.assertIn("SYNTHETIC", str(contracts.get("_note", "")))
        self.assertIn("SYNTHETIC", str(measurements.get("_note", "")))
        # Expected file is a valid comparison with the documented summary.
        self.assertEqual(expected["schema_version"], 1)
        self.assertEqual(expected["kind"], "comparison")
        self.assertEqual(expected["summary"], {"excluded": 1, "fail": 1, "pass": 2, "unverified": 1})

    def test_examples_compare_matches_expected(self):
        with tempfile.TemporaryDirectory() as td:
            out = Path(td) / "got.json"
            r = run_cli("compare", str(EXAMPLE_CONTRACTS), str(EXAMPLE_MEASUREMENTS), "--output", str(out))
            # Fixture contains a fail (playlists 32 vs 24) so exit 1.
            self.assertEqual(r.returncode, 1, r.stderr)
            got = json.loads(out.read_text(encoding="utf-8"))
            exp = json.loads(EXAMPLE_EXPECTED.read_text(encoding="utf-8"))
            self.assertEqual(got, exp)


class OverwriteProtectionTests(unittest.TestCase):
    def test_compare_output_same_as_contracts_refused(self):
        with tempfile.TemporaryDirectory() as td:
            c = Path(td) / "c.json"
            m = Path(td) / "m.json"
            write_json(c, {"schema_version": 1, "rules": [base_rule()]})
            write_json(m, {"schema_version": 1, "surfaces": [base_surf()]})
            before = c.read_bytes()
            r = run_cli("compare", str(c), str(m), "--output", str(c), "--force")
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertEqual(c.read_bytes(), before)

    def test_compare_output_same_as_measurements_refused(self):
        with tempfile.TemporaryDirectory() as td:
            c = Path(td) / "c.json"
            m = Path(td) / "m.json"
            write_json(c, {"schema_version": 1, "rules": [base_rule()]})
            write_json(m, {"schema_version": 1, "surfaces": [base_surf()]})
            before = m.read_bytes()
            r = run_cli("compare", str(c), str(m), "--output", str(m), "--force")
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertEqual(m.read_bytes(), before)

    def test_compare_output_normalized_alias_refused(self):
        with tempfile.TemporaryDirectory() as td:
            c = Path(td) / "c.json"
            m = Path(td) / "m.json"
            sub = Path(td) / "sub"
            sub.mkdir()
            write_json(c, {"schema_version": 1, "rules": [base_rule()]})
            write_json(m, {"schema_version": 1, "surfaces": [base_surf()]})
            before = c.read_bytes()
            alias = os.path.join(str(sub), "..", "c.json")
            r = run_cli("compare", str(c), str(m), "--output", alias, "--force")
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertEqual(c.read_bytes(), before)
            # Dot alias for measurements.
            alias2 = os.path.join(td, ".", "m.json")
            before_m = m.read_bytes()
            r2 = run_cli("compare", str(c), str(m), "--output", alias2, "--force")
            self.assertEqual(r2.returncode, 2, r2.stderr)
            self.assertEqual(m.read_bytes(), before_m)

    def test_compare_output_parent_symlink_refused(self):
        with tempfile.TemporaryDirectory() as td:
            real = Path(td) / "real"
            real.mkdir()
            c = real / "c.json"
            m = real / "m.json"
            write_json(c, {"schema_version": 1, "rules": [base_rule()]})
            write_json(m, {"schema_version": 1, "surfaces": [base_surf()]})
            link = Path(td) / "link"
            try:
                os.symlink(str(real), str(link))
            except (OSError, NotImplementedError) as e:
                self.skipTest(f"symlinks unavailable: {e}")
            before = c.read_bytes()
            r = run_cli("compare", str(c), str(m), "--output", str(link / "c.json"), "--force")
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertEqual(c.read_bytes(), before)

    def test_compare_output_hardlink_refused(self):
        with tempfile.TemporaryDirectory() as td:
            c = Path(td) / "c.json"
            m = Path(td) / "m.json"
            write_json(c, {"schema_version": 1, "rules": [base_rule()]})
            write_json(m, {"schema_version": 1, "surfaces": [base_surf()]})
            hard = Path(td) / "hard.json"
            try:
                os.link(str(c), str(hard))
            except (OSError, NotImplementedError) as e:
                self.skipTest(f"hardlinks unavailable: {e}")
            before = c.read_bytes()
            r = run_cli("compare", str(c), str(m), "--output", str(hard), "--force")
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertEqual(c.read_bytes(), before)
            self.assertEqual(hard.read_bytes(), before)

    def test_report_output_same_and_alias_refused(self):
        with tempfile.TemporaryDirectory() as td:
            c = Path(td) / "c.json"
            m = Path(td) / "m.json"
            comp = Path(td) / "comp.json"
            write_json(c, {"schema_version": 1, "rules": [base_rule()]})
            write_json(m, {"schema_version": 1, "surfaces": [base_surf()]})
            r0 = run_cli("compare", str(c), str(m), "--output", str(comp))
            self.assertEqual(r0.returncode, 0, r0.stderr)
            before = comp.read_bytes()
            # Same path.
            r = run_cli("report", str(comp), "--output", str(comp), "--force")
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertEqual(comp.read_bytes(), before)
            # Normalized alias.
            sub = Path(td) / "sub"
            sub.mkdir()
            alias = os.path.join(str(sub), "..", "comp.json")
            r2 = run_cli("report", str(comp), "--output", alias, "--force")
            self.assertEqual(r2.returncode, 2, r2.stderr)
            self.assertEqual(comp.read_bytes(), before)

    def test_report_output_parent_symlink_and_hardlink_refused(self):
        with tempfile.TemporaryDirectory() as td:
            real = Path(td) / "real"
            real.mkdir()
            c = real / "c.json"
            m = real / "m.json"
            comp = real / "comp.json"
            write_json(c, {"schema_version": 1, "rules": [base_rule()]})
            write_json(m, {"schema_version": 1, "surfaces": [base_surf()]})
            self.assertEqual(run_cli("compare", str(c), str(m), "--output", str(comp)).returncode, 0)
            before = comp.read_bytes()
            link = Path(td) / "link"
            try:
                os.symlink(str(real), str(link))
            except (OSError, NotImplementedError) as e:
                self.skipTest(f"symlinks unavailable: {e}")
            r = run_cli("report", str(comp), "--output", str(link / "comp.json"), "--force")
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertEqual(comp.read_bytes(), before)
            # Hardlink alias to the comparison input.
            hard2 = real / "hard2.json"
            try:
                os.link(str(comp), str(hard2))
            except (OSError, NotImplementedError) as e:
                self.skipTest(f"hardlinks unavailable: {e}")
            r2 = run_cli("report", str(comp), "--output", str(hard2), "--force")
            self.assertEqual(r2.returncode, 2, r2.stderr)
            self.assertEqual(comp.read_bytes(), before)

    def test_scan_never_overwrites_swift_source(self):
        with tempfile.TemporaryDirectory() as td:
            src = Path(td) / "src"
            src.mkdir()
            app = src / "App.swift"
            app.write_text("WindowGroup { }\n", encoding="utf-8")
            before = app.read_bytes()
            # Direct .swift output.
            r = run_cli("scan", str(src), "--output", str(app), "--force")
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertEqual(app.read_bytes(), before)
            # New .swift path must not be created.
            new_swift = src / "New.swift"
            r2 = run_cli("scan", str(src), "--output", str(new_swift), "--force")
            self.assertEqual(r2.returncode, 2, r2.stderr)
            self.assertFalse(new_swift.exists())
            # Outside ROOT .swift also refused.
            outside = Path(td) / "out.swift"
            outside.write_text("old", encoding="utf-8")
            before_out = outside.read_bytes()
            r3 = run_cli("scan", str(src), "--output", str(outside), "--force")
            self.assertEqual(r3.returncode, 2, r3.stderr)
            self.assertEqual(outside.read_bytes(), before_out)
            # Legitimate separate .json replacement still works.
            out = Path(td) / "out.json"
            out.write_text("{}", encoding="utf-8")
            r4 = run_cli("scan", str(src), "--output", str(out), "--force")
            self.assertEqual(r4.returncode, 0, r4.stderr)
            self.assertEqual(app.read_bytes(), before)

    def test_scan_swift_alias_parent_symlink_hardlink_refused(self):
        with tempfile.TemporaryDirectory() as td:
            src = Path(td) / "src"
            src.mkdir()
            app = src / "App.swift"
            app.write_text("WindowGroup { }\n", encoding="utf-8")
            before = app.read_bytes()
            sub = src / "sub"
            sub.mkdir()
            alias = os.path.join(str(sub), "..", "App.swift")
            r = run_cli("scan", str(src), "--output", alias, "--force")
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertEqual(app.read_bytes(), before)
            # Parent symlink alias to the swift source.
            real = Path(td) / "real"
            real.mkdir()
            (real / "A.swift").write_text("WindowGroup { }\n", encoding="utf-8")
            link = Path(td) / "link"
            try:
                os.symlink(str(real), str(link))
            except (OSError, NotImplementedError) as e:
                self.skipTest(f"symlinks unavailable: {e}")
            target_before = (real / "A.swift").read_bytes()
            r2 = run_cli("scan", str(real), "--output", str(link / "A.swift"), "--force")
            self.assertEqual(r2.returncode, 2, r2.stderr)
            self.assertEqual((real / "A.swift").read_bytes(), target_before)
            # Hardlink with non-swift name pointing at swift inode.
            hard = Path(td) / "hard.json"
            try:
                os.link(str(app), str(hard))
            except (OSError, NotImplementedError) as e:
                self.skipTest(f"hardlinks unavailable: {e}")
            hard_before = hard.read_bytes()
            r3 = run_cli("scan", str(src), "--output", str(hard), "--force")
            self.assertEqual(r3.returncode, 2, r3.stderr)
            self.assertEqual(app.read_bytes(), before)
            self.assertEqual(hard.read_bytes(), hard_before)


class ReportRegressionTests(unittest.TestCase):
    def _valid_comparison_obj(self, td):
        c = Path(td) / "c.json"
        m = Path(td) / "m.json"
        comp = Path(td) / "comp.json"
        write_json(c, {"schema_version": 1, "rules": [base_rule()]})
        write_json(m, {"schema_version": 1, "surfaces": [base_surf()]})
        r = run_cli("compare", str(c), str(m), "--output", str(comp))
        self.assertEqual(r.returncode, 0, r.stderr)
        return json.loads(comp.read_text(encoding="utf-8"))

    def test_report_rejects_contradictory_summary(self):
        with tempfile.TemporaryDirectory() as td:
            obj = self._valid_comparison_obj(td)
            obj["summary"] = {"pass": 0, "fail": 0, "unverified": 0, "excluded": 0}
            bad = Path(td) / "bad.json"
            write_json(bad, obj)
            out = Path(td) / "r.md"
            r = run_cli("report", str(bad), "--output", str(out))
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertFalse(out.exists())
            # Existing output unchanged.
            out.write_text("sentinel", encoding="utf-8")
            before = out.read_bytes()
            r2 = run_cli("report", str(bad), "--output", str(out), "--force")
            self.assertEqual(r2.returncode, 2, r2.stderr)
            self.assertEqual(out.read_bytes(), before)

    def test_report_rejects_empty_findings(self):
        with tempfile.TemporaryDirectory() as td:
            obj = {
                "schema_version": 1,
                "kind": "comparison",
                "findings": [],
                "summary": {"pass": 0, "fail": 0, "unverified": 0, "excluded": 0},
                "limitations": ["x"],
            }
            bad = Path(td) / "bad.json"
            write_json(bad, obj)
            out = Path(td) / "r.md"
            r = run_cli("report", str(bad), "--output", str(out))
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertFalse(out.exists())

    def test_report_rejects_duplicate_findings(self):
        with tempfile.TemporaryDirectory() as td:
            obj = self._valid_comparison_obj(td)
            dup = dict(obj["findings"][0])
            obj["findings"].append(dup)
            # Recompute summary to match duplicated counts so only duplicate triggers.
            counts = {"pass": 0, "fail": 0, "unverified": 0, "excluded": 0}
            for f in obj["findings"]:
                counts[f["status"]] += 1
            obj["summary"] = counts
            bad = Path(td) / "bad.json"
            write_json(bad, obj)
            out = Path(td) / "r.md"
            r = run_cli("report", str(bad), "--output", str(out))
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertFalse(out.exists())

    def test_report_maintains_intrinsic_limitations_when_empty(self):
        with tempfile.TemporaryDirectory() as td:
            obj = self._valid_comparison_obj(td)
            obj["limitations"] = []
            comp = Path(td) / "empty_lim.json"
            write_json(comp, obj)
            out = Path(td) / "r.md"
            r = run_cli("report", str(comp), "--output", str(out))
            self.assertEqual(r.returncode, 0, r.stderr)
            text = out.read_text(encoding="utf-8")
            self.assertNotIn("none declared", text)
            for expected in [
                "compares declared numeric metrics only",
                "supplied-evidence quality remains agent responsibility",
                "empty contracts/measurements are invalid, never green",
                "no exhaustive app coverage claim",
            ]:
                self.assertIn(expected, text)


class CompareBoundaryTests(unittest.TestCase):
    def _run(self, td, contracts, measurements):
        c = Path(td) / "c.json"
        m = Path(td) / "m.json"
        o = Path(td) / "o.json"
        if o.exists():
            o.unlink()
        write_json(c, contracts)
        write_json(m, measurements)
        r = run_cli("compare", str(c), str(m), "--output", str(o))
        return r, o

    def test_uncertainty_lower_bound_equals_tolerance_is_unverified(self):
        with tempfile.TemporaryDirectory() as td:
            # delta 1.0, unc 0.5 -> lower 0.5 == tol 0.5 => unverified, not fail (exact binary values).
            contracts = {"schema_version": 1, "rules": [base_rule(expected=24, tolerance=0.5)]}
            surf = base_surf(measurements=[base_meas(value=25.0, uncertainty=0.5)])
            measurements = {"schema_version": 1, "surfaces": [surf]}
            r, o = self._run(td, contracts, measurements)
            self.assertEqual(r.returncode, 3, r.stderr)
            obj = read_json(o)
            self.assertEqual(obj["findings"][0]["status"], "unverified")
            self.assertIn("overlap", obj["findings"][0]["reason"])

    def test_pass_plus_excluded_exit_zero(self):
        with tempfile.TemporaryDirectory() as td:
            contracts = {"schema_version": 1, "rules": [base_rule()]}
            ok = base_surf(id="ok")
            exc = base_surf(id="exc", status="excluded", reason="intentional", measurements=[])
            measurements = {"schema_version": 1, "surfaces": [ok, exc]}
            r, o = self._run(td, contracts, measurements)
            self.assertEqual(r.returncode, 0, r.stderr)
            obj = read_json(o)
            # Applicable ok passes, excluded stays excluded, no null gap.
            self.assertEqual(obj["summary"], {"pass": 1, "fail": 0, "unverified": 0, "excluded": 1})

    def test_compare_missing_input_leaves_no_output(self):
        with tempfile.TemporaryDirectory() as td:
            c = Path(td) / "c.json"
            m = Path(td) / "m.json"
            o = Path(td) / "o.json"
            write_json(m, {"schema_version": 1, "surfaces": [base_surf()]})
            # Missing contracts.
            r = run_cli("compare", str(c), str(m), "--output", str(o))
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertFalse(o.exists())
            # Existing output unchanged on invalid.
            write_json(c, {"schema_version": 1, "rules": [base_rule()]})
            o.write_text("sentinel", encoding="utf-8")
            before = o.read_bytes()
            bad_m = Path(td) / "bad.json"
            bad_m.write_text("not json", encoding="utf-8")
            r2 = run_cli("compare", str(c), str(bad_m), "--output", str(o), "--force")
            self.assertEqual(r2.returncode, 2, r2.stderr)
            self.assertEqual(o.read_bytes(), before)

    def test_report_missing_input_leaves_no_output(self):
        with tempfile.TemporaryDirectory() as td:
            missing = Path(td) / "missing.json"
            out = Path(td) / "r.md"
            r = run_cli("report", str(missing), "--output", str(out))
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertFalse(out.exists())


class ScanRegressionTests(unittest.TestCase):
    def test_scan_raw_string_masking(self):
        with tempfile.TemporaryDirectory() as td:
            src = Path(td) / "src"
            src.mkdir()
            (src / "R.swift").write_text(
                'let a = #"WindowGroup in raw string should not hit"#\n'
                'let b = ##"sheet in raw double hash should not hit"##\n'
                'let c = #"alert in raw should not hit"#\n'
                'struct X { var b: some Scene { WindowGroup { Text("hi") } } }\n',
                encoding="utf-8",
            )
            out = Path(td) / "out.json"
            r = run_cli("scan", str(src), "--output", str(out))
            self.assertEqual(r.returncode, 0, r.stderr)
            obj = read_json(out)
            self.assertEqual([(c["kind"], c["line"]) for c in obj["candidates"]], [("WindowGroup", 4)])

    def test_scan_symlink_root_refused_no_output(self):
        with tempfile.TemporaryDirectory() as td:
            real = Path(td) / "real"
            real.mkdir()
            (real / "A.swift").write_text("WindowGroup { }\n", encoding="utf-8")
            link = Path(td) / "link"
            try:
                os.symlink(str(real), str(link))
            except (OSError, NotImplementedError) as e:
                self.skipTest(f"symlinks unavailable: {e}")
            out = Path(td) / "out.json"
            r = run_cli("scan", str(link), "--output", str(out))
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertFalse(out.exists())

    def test_scan_invalid_root_leaves_existing_output_unchanged(self):
        with tempfile.TemporaryDirectory() as td:
            out = Path(td) / "out.json"
            out.write_text("sentinel", encoding="utf-8")
            before = out.read_bytes()
            r = run_cli("scan", str(Path(td) / "nope"), "--output", str(out), "--force")
            self.assertEqual(r.returncode, 2, r.stderr)
            self.assertEqual(out.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
