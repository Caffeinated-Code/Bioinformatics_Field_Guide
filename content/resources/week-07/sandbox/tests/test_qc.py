import csv
import os
import unittest
from pathlib import Path


RESULTS = Path(os.environ.get("QC_RESULTS", ".test-results/sandbox"))


def read_metrics(path: Path) -> dict[str, str]:
    with path.open(newline="", encoding="ascii") as handle:
        return {
            row["metric"]: row["value"]
            for row in csv.DictReader(handle, delimiter="\t")
        }


class TestTinyFastqQualityGate(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.qc = read_metrics(RESULTS / "read_qc.tsv")
        cls.gate = read_metrics(RESULTS / "quality_gate.tsv")

    def test_read_count(self) -> None:
        self.assertEqual(int(self.qc["reads"]), 3)

    def test_total_bases(self) -> None:
        self.assertEqual(int(self.qc["bases"]), 36)

    def test_length_summary(self) -> None:
        self.assertEqual(float(self.qc["mean_length"]), 12.0)
        self.assertEqual(int(self.qc["min_length"]), 8)
        self.assertEqual(int(self.qc["max_length"]), 16)

    def test_quality_gate(self) -> None:
        self.assertEqual(self.gate["status"], "PASS")
        self.assertGreaterEqual(
            int(self.gate["reads"]), int(self.gate["minimum_reads"])
        )


if __name__ == "__main__":
    unittest.main()
