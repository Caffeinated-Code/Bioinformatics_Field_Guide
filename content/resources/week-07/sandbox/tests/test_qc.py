"""Known-answer and invariant tests for the three-read FASTQ sandbox."""

import csv
import os
import unittest
from pathlib import Path


RESULTS = Path(os.environ.get("QC_RESULTS", ".test-results/sandbox"))


def read_metrics(path: Path) -> dict[str, str]:
    """Load a two-column metric/value TSV into a dictionary."""
    with path.open(newline="", encoding="ascii") as handle:
        return {
            row["metric"]: row["value"]
            for row in csv.DictReader(handle, delimiter="\t")
        }


class TestTinyFastqQualityGate(unittest.TestCase):
    """Check exact fixture answers and relationships that must always hold."""

    @classmethod
    def setUpClass(cls) -> None:
        # Read each result once, then share it with every test method below.
        cls.qc = read_metrics(RESULTS / "read_qc.tsv")
        cls.gate = read_metrics(RESULTS / "quality_gate.tsv")

    def test_required_metrics(self) -> None:
        # Exact key sets catch missing, renamed, and unexpected output fields.
        self.assertSetEqual(
            set(self.qc),
            {"reads", "bases", "mean_length", "min_length", "max_length"},
        )
        self.assertSetEqual(
            set(self.gate),
            {"status", "reads", "minimum_reads"},
        )

    def test_read_count(self) -> None:
        # The fixture contains exactly three FASTQ records.
        self.assertEqual(int(self.qc["reads"]), 3)

    def test_total_bases(self) -> None:
        # Its read lengths are 12, 8, and 16: 12 + 8 + 16 = 36.
        self.assertEqual(int(self.qc["bases"]), 36)

    def test_length_summary(self) -> None:
        self.assertEqual(float(self.qc["mean_length"]), 12.0)
        self.assertEqual(int(self.qc["min_length"]), 8)
        self.assertEqual(int(self.qc["max_length"]), 16)

    def test_lengths_are_ordered(self) -> None:
        minimum = int(self.qc["min_length"])
        mean = float(self.qc["mean_length"])
        maximum = int(self.qc["max_length"])
        # This mathematical relationship should hold for any non-empty FASTQ.
        self.assertLessEqual(minimum, mean)
        self.assertLessEqual(mean, maximum)

    def test_quality_gate(self) -> None:
        # PASS is internally consistent only when observed reads meet the rule.
        self.assertEqual(self.gate["status"], "PASS")
        self.assertGreaterEqual(
            int(self.gate["reads"]), int(self.gate["minimum_reads"])
        )


if __name__ == "__main__":
    unittest.main()
