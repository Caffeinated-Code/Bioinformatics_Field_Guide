#!/usr/bin/env bash
set -euo pipefail

resource_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
outdir="${1:-${resource_dir}/.test-results/sandbox}"
workdir="${resource_dir}/.test-work/sandbox"

command -v nextflow >/dev/null || {
  printf 'nextflow is required but was not found on PATH.\n' >&2
  exit 127
}

mkdir -p "${outdir}" "${workdir}"

nextflow run "${resource_dir}/sandbox/main.nf" \
  --reads "${resource_dir}/sandbox/data/tiny.fastq" \
  --min_reads 3 \
  --outdir "${outdir}" \
  -work-dir "${workdir}" \
  -ansi-log false

QC_RESULTS="${outdir}" python3 -m unittest discover \
  -s "${resource_dir}/sandbox/tests" \
  -p 'test_*.py' \
  -v

printf '\nQC summary\n'
cat "${outdir}/read_qc.tsv"
printf '\nGate decision\n'
cat "${outdir}/quality_gate.tsv"
