#!/usr/bin/env bash
# Extract three reviewed metrics from a completed Week 6 public-data run.
set -euo pipefail

if [[ "$#" -ne 3 ]]; then
  printf 'Usage: %s ALIGNMENTS.bam TRANSCRIPT_MODELS.gtf SQANTI_CLASSIFICATION.txt\n' "$0" >&2
  exit 2
fi

bam="$1"
models_gtf="$2"
classification="$3"

command -v samtools >/dev/null || {
  printf 'samtools is required but was not found on PATH.\n' >&2
  exit 127
}

for input_file in "${bam}" "${models_gtf}" "${classification}"; do
  if [[ ! -s "${input_file}" ]]; then
    printf 'Metric collection failed: %s is missing or empty.\n' "${input_file}" >&2
    exit 1
  fi
done

# Exclude unmapped (4), secondary (256), and supplementary (2048) records.
primary_alignments="$(samtools view -c -F 2308 "${bam}")"

# Count transcript feature rows in the discovered transcript-model GTF.
transcript_models="$(awk '$3 == "transcript" { count += 1 } END { print count + 0 }' "${models_gtf}")"

# SQANTI3 classification tables have one header row followed by one row/model.
classification_rows="$(awk 'NR > 1 { count += 1 } END { print count + 0 }' "${classification}")"

printf 'metric\tobserved\n'
printf 'primary_alignments\t%s\n' "${primary_alignments}"
printf 'transcript_models\t%s\n' "${transcript_models}"
printf 'sqanti_classification_rows\t%s\n' "${classification_rows}"
