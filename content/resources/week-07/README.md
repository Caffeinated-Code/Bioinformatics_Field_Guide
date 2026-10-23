# Week 7: Trustworthy Bioinformatics Pipeline CI

This project tests the custom ONT isoform workflow from Week 6 with the same commands on a laptop, GitHub Actions, and Jenkins.

## What Gets Tested

| Layer | Command | What it catches |
|---|---|---|
| Nextflow lint | `nextflow lint content/resources/week-06` | invalid or deprecated Nextflow syntax |
| Tiny integration run | `scripts/run_sandbox.sh` | commands that cannot execute or publish results |
| File contract | Bash checks in `run_sandbox.sh` | missing, empty, or malformed TSV outputs |
| Schema and known values | Python `unittest` | missing metrics or incorrect counts and lengths |
| Scientific invariant | Python `unittest` | impossible ordering such as mean length above the maximum |
| Expected failure | `scripts/test_expected_failure.sh` | a QC gate that accidentally accepts bad input |
| Pipeline contract | `nf-test ... -stub-run` | broken channels, process dependencies, metadata, and output names |

The fast suite does not claim that minimap2, IsoQuant, or SQANTI3 produced biologically valid results. The public Week 6 toy dataset remains the real integration test.

## Project Map

```text
week-07/
  sandbox/main.nf             # two-process FASTQ QC workflow
  sandbox/data/tiny.fastq     # three synthetic reads
  sandbox/tests/test_qc.py    # six content and invariant tests
  scripts/run_sandbox.sh      # one-command hands-on lab
  scripts/test_expected_failure.sh # verifies the QC gate rejects bad input
  scripts/run_fast_ci.sh      # shared local and CI entry point
  Jenkinsfile                 # Jenkins pipeline-as-code example
```

## Run The Tiny Sandbox

Requirements: Nextflow 26.04.2, Java 17, Bash, and Python 3. No Docker or biological software is needed.

From the repository root, run:

```bash
bash content/resources/week-07/scripts/run_sandbox.sh
```

Expected result:

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

To verify that CI stops a bad result, run:

```bash
bash content/resources/week-07/scripts/test_expected_failure.sh
```

The data contains three reads while the test requires four. The script passes only if `QUALITY_GATE` fails for the expected reason.

## Run The Complete Fast Suite

Install nf-test 0.9.3, then run this from the repository root:

```bash
bash content/resources/week-07/scripts/run_fast_ci.sh
```

The script is the shared test entry point. GitHub Actions and Jenkins call it instead of duplicating test logic.

Expected final lines:

```text
Ran 6 tests ... OK
Expected-failure test: PASS
QC failed: expected at least 4 reads, observed 3.
```

## CI Runners

- `.github/workflows/week-07-pipeline-ci.yml` is the public GitHub Actions workflow.
- `Jenkinsfile` is the enterprise or on-premises equivalent. Set the Jenkins script path to `content/resources/week-07/Jenkinsfile`.
- A Jenkins agent labeled `bioinformatics-ci` needs Java 17, Nextflow 26.04.2, nf-test 0.9.3, Bash, and Python 3 on `PATH`.
- The Jenkins controller needs the Pipeline and JUnit plugins to execute the file and publish the XML test report.

Use tiny synthetic or public data in CI. Never upload protected patient data, production credentials, or controlled reference assets to a public runner.
