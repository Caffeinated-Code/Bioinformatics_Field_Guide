#!/usr/bin/env bash
set -euo pipefail

resource_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
outdir="${1:-${resource_dir}/.test-results/expected-failure}"
workdir="${resource_dir}/.test-work/expected-failure"
log_file="${outdir}/nextflow.log"
expected_message='QC failed: expected at least 4 reads, observed 3.'

command -v nextflow >/dev/null || {
  printf 'nextflow is required but was not found on PATH.\n' >&2
  exit 127
}

mkdir -p "${outdir}" "${workdir}"

set +e
nextflow run "${resource_dir}/sandbox/main.nf" \
  --reads "${resource_dir}/sandbox/data/tiny.fastq" \
  --min_reads 4 \
  --outdir "${outdir}" \
  -work-dir "${workdir}" \
  -ansi-log false >"${log_file}" 2>&1
exit_status=$?
set -e

if [[ "${exit_status}" -eq 0 ]]; then
  printf 'Expected-failure test failed: the pipeline accepted three reads when four were required.\n' >&2
  exit 1
fi

if ! grep -Fq "${expected_message}" "${log_file}"; then
  printf 'Expected-failure test failed: the pipeline failed for an unexpected reason.\n' >&2
  cat "${log_file}" >&2
  exit 1
fi

printf 'Expected-failure test: PASS\n'
grep -F -m 1 "${expected_message}" "${log_file}"
