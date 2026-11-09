#!/usr/bin/env bash
# This wrapper expects the inner Nextflow command to fail, so it temporarily
# disables Bash's automatic exit behavior and then inspects the failure.
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

# A three-read FASTQ cannot satisfy --min_reads 4. Capture both the log and the
# Nextflow process exit status instead of letting set -e stop the wrapper.
set +e
nextflow run "${resource_dir}/sandbox/main.nf" \
  --reads "${resource_dir}/sandbox/data/tiny.fastq" \
  --min_reads 4 \
  --outdir "${outdir}" \
  -work-dir "${workdir}" \
  -ansi-log false >"${log_file}" 2>&1
exit_status=$?
set -e

# Exit status 0 would mean the invalid case was incorrectly accepted.
if [[ "${exit_status}" -eq 0 ]]; then
  printf 'Expected-failure test failed: the pipeline accepted three reads when four were required.\n' >&2
  exit 1
fi

# A non-zero status alone is insufficient: a missing tool or syntax error could
# also fail. Require the precise QC message to prove the intended branch ran.
if ! grep -Fq "${expected_message}" "${log_file}"; then
  printf 'Expected-failure test failed: the pipeline failed for an unexpected reason.\n' >&2
  cat "${log_file}" >&2
  exit 1
fi

printf 'Expected-failure test: PASS (Nextflow exit code %s)\n' "${exit_status}"
grep -F -m 1 "${expected_message}" "${log_file}"
