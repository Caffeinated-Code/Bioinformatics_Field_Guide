# Week 7: Reliable Bioinformatics Pipeline Testing

This project teaches seven reusable testing patterns around the custom Week 6
Nextflow pipeline. The same commands run on a laptop, GitHub Actions, or a
prepared Jenkins agent.

## Clone The Required Layout

Clone the Field Guide repository once. It already contains both weeks in the
correct sibling directories:

```bash
git clone https://github.com/Caffeinated-Code/Bioinformatics_Field_Guide.git
cd Bioinformatics_Field_Guide

# Verify that the self-contained sandbox and the Week 6 contract target exist.
test -f content/resources/week-07/sandbox/main.nf
test -f content/resources/week-06/main.nf
```

Do not clone Week 6 inside Week 7. `run_fast_ci.sh` expects this layout:

```text
content/resources/
  week-06/   # pipeline inspected by lint and nf-test
  week-07/   # sandbox, test harnesses, and CI examples
```

The five-minute sandbox uses only Week 7. The `lint` and `contract` targets use
Week 6, so the complete fast suite needs both directories.

## What Gets Tested

| Layer | Command or file | What it catches |
|---|---|---|
| Nextflow lint | `nextflow lint content/resources/week-06` | syntax and static code issues before execution |
| smoke run | `scripts/run_sandbox.sh` | a command or process that cannot complete |
| file contract | Bash checks in `run_sandbox.sh` | missing, empty, or malformed TSV outputs |
| known answers | Python `unittest` | wrong fields, read count, bases, or lengths |
| invariants | Python `unittest` | internally impossible or contradictory metrics |
| expected failure | `scripts/test_expected_failure.sh` | a QC gate that accepts invalid input |
| workflow contract | Week 6 `tests/pipeline.nf.test` | broken channels, dependencies, metadata, or task graph |
| scientific regression | `check_scientific_regression.py` | reviewed biological metrics moving beyond tolerance |

Stubs and synthetic data test software behavior. They do not prove that
minimap2, IsoQuant, or SQANTI3 produced biologically valid results. Use the
public Week 6 dataset for real-tool and scientific regression testing.

## Project Map

```text
week-07/
  sandbox/main.nf                  # two-process FASTQ QC workflow
  sandbox/data/tiny.fastq          # three synthetic reads
  sandbox/tests/test_qc.py         # six known-answer and invariant tests
  scientific-regression/
    baseline.tsv                   # reviewed, versioned expectations
    observed-pass.tsv              # passing practice result
    observed-fail.tsv              # intentionally failing practice result
  scripts/run_sandbox.sh           # smoke + file + unittest harness
  scripts/test_expected_failure.sh # proves the QC gate rejects bad input
  scripts/run_fast_ci.sh           # shared local and hosted-CI entry point
  scripts/collect_week06_metrics.sh
  scripts/check_scientific_regression.py
  Jenkinsfile                      # enterprise/on-premises pipeline example
```

## Run The Five-Minute Sandbox

Requirements: Nextflow 26.04.2, Java 17, Bash, and Python 3. No Docker or
biological software is needed.

```bash
bash content/resources/week-07/scripts/run_sandbox.sh
```

The wrapper performs three steps:

1. It runs the two-process Nextflow sandbox on `tiny.fastq`.
2. It checks that two non-empty TSV files have `metric<TAB>value` headers.
3. It runs six Python assertions against the TSV contents.

Expected final result:

```text
File contract: PASS (two non-empty TSV files with metric/value headers)
Ran 6 tests ... OK

metric          value
reads           3
bases           36
mean_length     12.0

metric          value
status          PASS
reads           3
minimum_reads   3
```

## Prove The Gate Can Fail

```bash
bash content/resources/week-07/scripts/test_expected_failure.sh
```

The fixture contains three reads while this test requires four. The wrapper
passes only when Nextflow exits non-zero *and* emits the expected QC message.

```text
Expected-failure test: PASS (Nextflow exit code 1)
QC failed: expected at least 4 reads, observed 3.
```

## Run The Complete Fast Suite

The complete fast suite means all checks designed to finish quickly on every
pull request. It does not run the large containers or public-data analysis.

Requirements: Nextflow 26.04.2, Java 17, nf-test 0.9.3, Bash, and Python 3.

```bash
bash content/resources/week-07/scripts/run_fast_ci.sh
```

Run one target while debugging:

| Target | Command | Runs |
|---|---|---|
| versions | `.../run_fast_ci.sh versions` | runtime inventory |
| lint | `.../run_fast_ci.sh lint` | Week 6 static analysis |
| contract | `.../run_fast_ci.sh contract` | five-task nf-test stub run |
| sandbox | `.../run_fast_ci.sh sandbox` | real tiny workflow and six assertions |
| negative | `.../run_fast_ci.sh negative` | expected QC rejection |
| all | `.../run_fast_ci.sh all` | every target above, in order |

GitHub Actions and Jenkins call this script instead of duplicating test logic.

## Try Scientific Regression Testing

Compare the reviewed Week 6 baseline with the passing practice metrics:

```bash
python3 content/resources/week-07/scripts/check_scientific_regression.py \
  content/resources/week-07/scientific-regression/baseline.tsv \
  content/resources/week-07/scientific-regression/observed-pass.tsv
```

Then run the intentionally changed metrics. Exit code `1` is expected:

```bash
python3 content/resources/week-07/scripts/check_scientific_regression.py \
  content/resources/week-07/scientific-regression/baseline.tsv \
  content/resources/week-07/scientific-regression/observed-fail.tsv
```

After a real Week 6 run, collect the same metrics from the BAM, model GTF, and
SQANTI3 classification table:

```bash
bash content/resources/week-07/scripts/collect_week06_metrics.sh \
  results/week06-toy/alignments/ISOQUANT_TOY.sorted.bam \
  PATH/TO/ISOQUANT_TOY.transcript_models.gtf \
  PATH/TO/SQANTI_CLASSIFICATION.txt \
  > observed.tsv
```

Review changed metrics before updating `baseline.tsv`. A passing threshold is
a scientific decision, not a convenient way to turn CI green.

## CI Runners

- `.github/workflows/week-07-pipeline-ci.yml` is the public GitHub Actions workflow.
- `Jenkinsfile` runs the same targets on private or on-premises infrastructure.
- A Jenkins agent labeled `bioinformatics-ci` needs Java 17, Nextflow 26.04.2,
  nf-test 0.9.3, Bash, and Python 3 on `PATH`.
- The Jenkins controller needs Pipeline and JUnit support to run the file and
  publish the XML report.

Use synthetic or public data on public runners. Never place protected patient
data, production credentials, or controlled reference assets in public CI.
