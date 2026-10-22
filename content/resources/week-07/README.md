# Week 7: Trustworthy Bioinformatics Pipeline CI

This project tests the custom ONT isoform workflow from Week 6 with the same commands on a laptop, GitHub Actions, and Jenkins.

## What Gets Tested

| Layer | Command | What it catches |
|---|---|---|
| Nextflow lint | `nextflow lint content/resources/week-06` | invalid or deprecated Nextflow syntax |
| Pipeline contract | `nf-test ... -stub-run` | broken channels, process dependencies, metadata, and output names |
| Real tiny run | `scripts/run_sandbox.sh` | command execution and file publication on three FASTQ reads |
| Scientific assertions | Python `unittest` | incorrect read count, base count, length summary, or gate decision |

The fast suite does not claim that minimap2, IsoQuant, or SQANTI3 produced biologically valid results. The public Week 6 toy dataset remains the real integration test.

## Run The Tiny Sandbox

Requirements: Nextflow, a supported Java runtime, Bash, and Python 3. No Docker or biological software is needed.

```bash
bash content/resources/week-07/scripts/run_sandbox.sh
```

Expected result:

```text
Ran 4 tests ... OK

metric          value
reads           3
bases           36
mean_length     12.0

metric          value
status          PASS
reads           3
minimum_reads   3
```

To see CI stop a bad result, run the pipeline directly with `--min_reads 4`. The data contains only three reads, so `QUALITY_GATE` must fail.

## Run The Complete Fast Suite

Install nf-test 0.9.3, then run:

```bash
bash content/resources/week-07/scripts/run_fast_ci.sh
```

The script is the shared test entry point. GitHub Actions and Jenkins call it instead of duplicating test logic.

## CI Runners

- `.github/workflows/week-07-pipeline-ci.yml` is the public GitHub Actions workflow.
- `Jenkinsfile` is the enterprise or on-premises equivalent.
- A Jenkins agent labeled `bioinformatics-ci` needs Java 17, Nextflow 26.04.2, nf-test 0.9.3, Bash, and Python 3 on `PATH`.

Use tiny synthetic or public data in CI. Never upload protected patient data, production credentials, or controlled reference assets to a public runner.
