#!/usr/bin/env bash
# Stop on a failed command (-e), an unset variable (-u), or a failed command in
# a pipeline (-o pipefail). A test harness should never continue after failure.
set -euo pipefail

# Resolve paths from this script's location so it works from any directory.
resource_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
outdir="${1:-${resource_dir}/.test-results/sandbox}"
workdir="${resource_dir}/.test-work/sandbox"

# The sandbox is self-contained in Week 7. It needs Nextflow and Python, but it
# does not run the Week 6 pipeline or require nf-test.
for required_command in nextflow python3; do
  command -v "${required_command}" >/dev/null || {
    printf '%s is required but was not found on PATH.\n' "${required_command}" >&2
    exit 127
  }
done

mkdir -p "${outdir}" "${workdir}"

# Smoke test: execute both Nextflow processes on the three-read FASTQ. Because
# -e is enabled, any non-zero Nextflow status stops this wrapper immediately.
nextflow run "${resource_dir}/sandbox/main.nf" \
  --reads "${resource_dir}/sandbox/data/tiny.fastq" \
  --min_reads 3 \
  --outdir "${outdir}" \
  -work-dir "${workdir}" \
  -ansi-log false

# File-contract test: each promised TSV must exist, contain at least one byte,
# and begin with the schema expected by readers and downstream code.
for result_file in read_qc.tsv quality_gate.tsv; do
  result_path="${outdir}/${result_file}"
  if [[ ! -s "${result_path}" ]]; then
    printf 'File contract failed: %s is missing or empty.\n' "${result_path}" >&2
    exit 1
  fi
  if [[ "$(head -n 1 "${result_path}")" != $'metric\tvalue' ]]; then
    printf 'File contract failed: %s has the wrong header.\n' "${result_path}" >&2
    exit 1
  fi
done

printf 'File contract: PASS (two non-empty TSV files with metric/value headers)\n'

# Content tests: point unittest at the files just published by Nextflow, then
# discover every test_*.py file in sandbox/tests and print each assertion.
QC_RESULTS="${outdir}" python3 -m unittest discover \
  -s "${resource_dir}/sandbox/tests" \
  -p 'test_*.py' \
  -v

# Show the small result files so a learner can compare their terminal output.
printf '\nQC summary\n'
cat "${outdir}/read_qc.tsv"
printf '\nGate decision\n'
cat "${outdir}/quality_gate.tsv"
