import unittest
from pathlib import Path

class WorkerSmokeTest(unittest.TestCase):
    def test_worker_exists(self):
        path = Path(__file__).resolve().parents[1] / "worker.py"
        self.assertTrue(path.is_file())
        compile(path.read_text(encoding="utf-8"), str(path), "exec")

if __name__ == "__main__":
    unittest.main()
