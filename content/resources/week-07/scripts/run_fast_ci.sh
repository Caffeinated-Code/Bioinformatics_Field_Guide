#!/usr/bin/env bash
set -euo pipefail

resource_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_root="$(cd "${resource_dir}/../../.." && pwd)"
week06="${repo_root}/content/resources/week-06"
report_dir="${repo_root}/build/test-results"
nf_test_bin="${NF_TEST_BIN:-nf-test}"
target="${1:-all}"

require_command() {
  command -v "$1" >/dev/null || {
    printf '%s is required but was not found on PATH.\n' "$1" >&2
    exit 127
  }
}

show_versions() {
  require_command nextflow
  require_command python3
  require_command "${nf_test_bin}"
  nextflow -version
  "${nf_test_bin}" version
  python3 --version
}

lint_pipeline() {
  nextflow lint "${week06}"
}

test_pipeline_contract() {
  mkdir -p "${report_dir}"
  (
    cd "${week06}"
    "${nf_test_bin}" test tests/pipeline.nf.test \
      --ci \
      --junitxml "${report_dir}/nf-test.xml"
  )
}

test_sandbox() {
  bash "${resource_dir}/scripts/run_sandbox.sh" "${repo_root}/build/sandbox"
}

test_expected_failure() {
  bash "${resource_dir}/scripts/test_expected_failure.sh" \
    "${repo_root}/build/expected-failure"
}

case "${target}" in
  versions) show_versions ;;
  lint) lint_pipeline ;;
  contract) test_pipeline_contract ;;
  sandbox) test_sandbox ;;
  negative) test_expected_failure ;;
  all)
    show_versions
    lint_pipeline
    test_pipeline_contract
    test_sandbox
    test_expected_failure
    ;;
  *)
    printf 'Usage: %s [versions|lint|contract|sandbox|negative|all]\n' "$0" >&2
    exit 2
    ;;
esac
