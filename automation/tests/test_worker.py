import unittest
import io
import json
from pathlib import Path
from unittest.mock import Mock, patch
import importlib.util
import tempfile
import subprocess

WORKER = Path(__file__).resolve().parents[1] / "worker.py"
spec = importlib.util.spec_from_file_location("pov_worker", WORKER)
worker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(worker)

class WorkerSmokeTest(unittest.TestCase):
    def test_worker_compiles(self):
        compile(WORKER.read_text(encoding="utf-8"), str(WORKER), "exec")

    def test_repository_context_uses_real_tracked_paths(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "scripts").mkdir()
            (root / "tests").mkdir()
            (root / "AGENTS.md").write_text("2D ONLY", encoding="utf-8")
            (root / "scripts" / "real.gd").write_text("extends Node2D", encoding="utf-8")
            (root / "tests" / "movement_test.gd").write_text("extends Node", encoding="utf-8")
            with patch.object(worker, "ROOT", root), patch.object(
                worker, "command", return_value={"stdout": "AGENTS.md\nscripts/real.gd\ntests/movement_test.gd\n"}
            ):
                context = worker.repository_context()
            self.assertIn("scripts/real.gd", context)
            self.assertIn("extends Node2D", context)
            self.assertIn("tests/movement_test.gd", context)
            self.assertIn("2D ONLY", context)


class FakeProcess:
    def __init__(self, returncode=0, stdout="", stderr="", timeout_once=False):
        self.pid = 4321
        self.returncode = returncode
        self.stdout = io.StringIO(stdout)
        self.stderr = io.StringIO(stderr)
        self.timeout_once = timeout_once
        self.wait_calls = 0
        self.killed = False

    def wait(self, timeout=None):
        self.wait_calls += 1
        if self.timeout_once and self.wait_calls == 1:
            raise subprocess.TimeoutExpired(["godot"], timeout)
        return self.returncode

    def poll(self):
        return self.returncode if self.killed or self.wait_calls else None

    def kill(self):
        self.killed = True


class LoggedProcessTest(unittest.TestCase):
    def run_fake(self, process):
        with tempfile.TemporaryDirectory() as tmp, patch.object(
            worker.subprocess, "Popen", return_value=process
        ):
            log_path = Path(tmp) / "step.log"
            result = worker.run_logged_process(
                ["godot", "--headless"], log_path, timeout=1, target="test scene"
            )
            log = log_path.read_text(encoding="utf-8")
        return result, log

    def test_exit_zero_is_pass(self):
        result, log = self.run_fake(FakeProcess(returncode=0, stdout="ok\n"))
        self.assertEqual("PASS", result["status"])
        self.assertEqual(0, result["exit_code"])
        self.assertIn("[stdout] ok", log)

    def test_nonzero_exit_is_fail(self):
        result, log = self.run_fake(FakeProcess(returncode=1, stderr="failure\n"))
        self.assertEqual("FAIL", result["status"])
        self.assertEqual(1, result["exit_code"])
        self.assertIn("[stderr] failure", log)

    def test_timeout_keeps_partial_log_without_raising(self):
        process = FakeProcess(returncode=-9, stdout="partial output\n", timeout_once=True)
        with patch.object(worker, "terminate_process_tree", side_effect=lambda value: value.kill()):
            result, log = self.run_fake(process)
        self.assertEqual("TIMEOUT", result["status"])
        self.assertEqual(-9, result["exit_code"])
        self.assertIn("partial output", result["stdout"])
        self.assertIn("[stdout] partial output", log)
        self.assertIn("TIMEOUT", log)
        self.assertTrue(process.killed)
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            worker.write_report(folder, {"godot_steps": [result]})
            recorded = json.loads((folder / "report.json").read_text(encoding="utf-8"))
        self.assertEqual("TIMEOUT", recorded["godot_steps"][0]["status"])
        self.assertIn("partial output", recorded["godot_steps"][0]["stdout"])

    def test_windows_timeout_uses_taskkill_for_process_tree(self):
        process = FakeProcess(returncode=-9)
        process.wait_calls = 0
        with patch.object(worker.os, "name", "nt"), patch.object(
            worker.subprocess, "run", return_value=Mock(returncode=0)
        ) as run:
            worker.terminate_process_tree(process)
        self.assertEqual(["taskkill", "/PID", "4321", "/T", "/F"], run.call_args.args[0])
        self.assertTrue(process.killed)


class ResumeQaTest(unittest.TestCase):
    def test_resume_qa_skips_branch_creation_and_codex(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            approved_spec = root / "approved.md"
            approved_spec.write_text("approved", encoding="utf-8")
            run_folder = root / "run"
            run_folder.mkdir()
            calls = []

            def fake_command(argv, **_kwargs):
                calls.append(argv)
                if argv == ["git", "branch", "--show-current"]:
                    return {"code": 0, "stdout": "current-branch\n", "stderr": ""}
                raise AssertionError(f"Unexpected command in resume mode: {argv}")

            with patch.object(worker, "command", side_effect=fake_command), patch.object(
                worker, "create_run_folder", return_value=run_folder
            ), patch.object(worker, "run_qa_pipeline", return_value=0) as pipeline:
                result = worker.main([
                    "--issue", "6", "--resume-qa", "--approved-spec", str(approved_spec)
                ])

        self.assertEqual(0, result)
        self.assertEqual([["git", "branch", "--show-current"]], calls)
        pipeline.assert_called_once_with(
            6, "approved", run_folder, "resume-qa", "current-branch", skip_godot=False
        )

    def test_pipeline_persists_prior_steps_and_fails_on_timeout(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            tests = root / "tests"
            tests.mkdir()
            (tests / "a_test.tscn").write_text("", encoding="utf-8")
            (tests / "b_test.tscn").write_text("", encoding="utf-8")
            run_folder = root / "run"
            run_folder.mkdir()

            def outcome(target, status, exit_code, stdout=""):
                return {
                    "target": target,
                    "command": [target],
                    "exit_code": exit_code,
                    "duration_seconds": 0.1,
                    "status": status,
                    "timestamp": "2026-11-06T00:00:00.000+00:00",
                    "log_path": str(run_folder / f"{target}.log"),
                    "stdout": stdout,
                    "stderr": "",
                }

            results = [
                outcome("import", "PASS", 0),
                outcome("a", "PASS", 0),
                outcome("b", "TIMEOUT", -9, "partial"),
                outcome("Gemini QA", "PASS", 0, "VERDICT: PASS\n"),
            ]
            with patch.object(worker, "ROOT", root), patch.object(
                worker, "run_logged_process", side_effect=results
            ), patch.object(worker, "collect_diff", return_value=""), patch.object(
                worker, "command", return_value={"code": 0, "stdout": "", "stderr": ""}
            ):
                result = worker.run_qa_pipeline(
                    6, "approved", run_folder, "resume-qa", "current-branch"
                )

            report = json.loads((run_folder / "report.json").read_text(encoding="utf-8"))
        self.assertEqual(1, result)
        self.assertEqual(["PASS", "PASS", "TIMEOUT"],
                         [step["status"] for step in report["godot_steps"]])
        self.assertEqual("PASS", report["qa"]["status"])

if __name__ == "__main__":
    unittest.main()
