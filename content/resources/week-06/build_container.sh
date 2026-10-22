#!/usr/bin/env bash
set -euo pipefail
resource_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_BUILDKIT=1 docker build --platform linux/amd64 \
  --tag biofield/ont-isoforms:2026.10 \
  "${resource_dir}"
