#!/usr/bin/env bash
# Fail immediately when a command, variable, or pipeline fails unexpectedly.
set -euo pipefail

# Locate Week 7 and the repository root independently of the current directory.
resource_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_root="$(cd "${resource_dir}/../../.." && pwd)"
week06="${repo_root}/content/resources/week-06"
report_dir="${repo_root}/build/test-results"

# Allow CI to provide a downloaded nf-test binary at a custom path.
nf_test_bin="${NF_TEST_BIN:-nf-test}"

# No argument means "all" fast, pull-request-safe checks.
target="${1:-all}"

require_command() {
  command -v "$1" >/dev/null || {
    printf '%s is required but was not found on PATH.\n' "$1" >&2
    exit 127
  }
}

require_week06() {
  if [[ ! -f "${week06}/main.nf" ]]; then
    printf '%s\n' \
      'Week 6 is required for lint and contract tests but was not found.' \
      'Clone the complete Bioinformatics_Field_Guide repository so these paths are siblings:' \
      '  content/resources/week-06' \
      '  content/resources/week-07' >&2
    exit 2
  fi
}

# Print the exact runtimes first; version drift often explains CI-only failures.
show_versions() {
  require_command nextflow
  require_command python3
  require_command "${nf_test_bin}"
  nextflow -version
  "${nf_test_bin}" version
  python3 --version
}

# Static analysis only: parse Week 6 Nextflow code without running its tools.
lint_pipeline() {
  require_week06
  nextflow lint "${week06}"
}

# Run the five-process Week 6 dataflow with lightweight stubs through nf-test.
test_pipeline_contract() {
  require_week06
  mkdir -p "${report_dir}"
  (
    cd "${week06}"
    "${nf_test_bin}" test tests/pipeline.nf.test \
      --ci \
      --junitxml "${report_dir}/nf-test.xml"
  )
}

# Run the real two-process Week 7 sandbox plus file and Python content checks.
test_sandbox() {
  bash "${resource_dir}/scripts/run_sandbox.sh" "${repo_root}/build/sandbox"
}

# Verify that the same sandbox rejects the neighboring four-read threshold.
test_expected_failure() {
  bash "${resource_dir}/scripts/test_expected_failure.sh" \
    "${repo_root}/build/expected-failure"
}

# Named targets make one layer easy to rerun while developing. The default
# "all" target is the complete fast suite used by GitHub Actions and Jenkins.
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
