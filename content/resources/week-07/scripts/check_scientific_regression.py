#!/usr/bin/env python3
"""Compare observed pipeline metrics with a reviewed, versioned baseline."""

from __future__ import annotations

import argparse
import csv
from decimal import Decimal, InvalidOperation
from pathlib import Path


def read_rows(path: Path) -> list[dict[str, str]]:
    """Read a tab-separated table and reject an empty file."""
    with path.open(newline="", encoding="ascii") as handle:
        rows = list(csv.DictReader(handle, delimiter="\t"))
    if not rows:
        raise ValueError(f"{path} contains no metric rows")
    return rows


def decimal(value: str, label: str) -> Decimal:
    """Parse one numeric cell while preserving exact decimal arithmetic."""
    try:
        return Decimal(value)
    except InvalidOperation as error:
        raise ValueError(f"{label} is not numeric: {value!r}") from error


def observed_metrics(path: Path) -> dict[str, Decimal]:
    """Return unique metric names mapped to their observed values."""
    metrics: dict[str, Decimal] = {}
    for row in read_rows(path):
        name = row.get("metric", "")
        if not name or "observed" not in row:
            raise ValueError(f"{path} needs metric and observed columns")
        if name in metrics:
            raise ValueError(f"duplicate observed metric: {name}")
        metrics[name] = decimal(row["observed"], f"{name}.observed")
    return metrics


def compare(baseline_path: Path, observed_path: Path) -> int:
    """Print one comparison row per metric and return 0 only when all pass."""
    observed = observed_metrics(observed_path)
    expected_names: set[str] = set()
    failed = False

    print("metric\texpected\tobserved\ttolerance\tdelta\tstatus")
    for row in read_rows(baseline_path):
        name = row.get("metric", "")
        if not name or "expected" not in row or "absolute_tolerance" not in row:
            raise ValueError(
                f"{baseline_path} needs metric, expected, and absolute_tolerance columns"
            )
        if name in expected_names:
            raise ValueError(f"duplicate baseline metric: {name}")
        expected_names.add(name)

        expected = decimal(row["expected"], f"{name}.expected")
        tolerance = decimal(row["absolute_tolerance"], f"{name}.tolerance")
        if tolerance < 0:
            raise ValueError(f"{name}.tolerance must be zero or positive")

        if name not in observed:
            print(f"{name}\t{expected}\tMISSING\t{tolerance}\tNA\tFAIL")
            failed = True
            continue

        actual = observed[name]
        delta = actual - expected
        status = "PASS" if abs(delta) <= tolerance else "FAIL"
        failed = failed or status == "FAIL"
        print(f"{name}\t{expected}\t{actual}\t{tolerance}\t{delta}\t{status}")

    unexpected = sorted(set(observed) - expected_names)
    for name in unexpected:
        print(f"{name}\tUNEXPECTED\t{observed[name]}\tNA\tNA\tFAIL")
        failed = True

    if failed:
        print("Scientific regression: FAIL")
        return 1

    print(f"Scientific regression: PASS ({len(expected_names)} metrics)")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Compare observed metrics with a reviewed scientific baseline."
    )
    parser.add_argument("baseline", type=Path, help="baseline TSV")
    parser.add_argument("observed", type=Path, help="observed metrics TSV")
    args = parser.parse_args()

    try:
        return compare(args.baseline, args.observed)
    except (OSError, ValueError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    raise SystemExit(main())
