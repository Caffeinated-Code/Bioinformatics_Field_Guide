#!/usr/bin/env bash
set -euo pipefail

resource_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
outdir="${1:-${resource_dir}/.test-results/sandbox}"
workdir="${resource_dir}/.test-work/sandbox"

for required_command in nextflow python3; do
  command -v "${required_command}" >/dev/null || {
    printf '%s is required but was not found on PATH.\n' "${required_command}" >&2
    exit 127
  }
done

mkdir -p "${outdir}" "${workdir}"

nextflow run "${resource_dir}/sandbox/main.nf" \
  --reads "${resource_dir}/sandbox/data/tiny.fastq" \
  --min_reads 3 \
  --outdir "${outdir}" \
  -work-dir "${workdir}" \
  -ansi-log false

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

QC_RESULTS="${outdir}" python3 -m unittest discover \
  -s "${resource_dir}/sandbox/tests" \
  -p 'test_*.py' \
  -v

printf '\nQC summary\n'
cat "${outdir}/read_qc.tsv"
printf '\nGate decision\n'
cat "${outdir}/quality_gate.tsv"
