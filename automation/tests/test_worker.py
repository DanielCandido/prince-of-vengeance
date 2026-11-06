import unittest
from pathlib import Path
from unittest.mock import patch
import importlib.util
import tempfile

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

if __name__ == "__main__":
    unittest.main()
