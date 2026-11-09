#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Command-line parameters. The wrapper supplies all three explicitly.
params.reads = null
params.min_reads = 3
params.outdir = 'results'

process SUMMARIZE_READS {
  // Show a useful sample name in the Nextflow execution log.
  tag reads.simpleName

  // Nextflow keeps task files in work/. This copies the declared result to
  // the reader-facing output directory after the task succeeds.
  publishDir params.outdir, mode: 'copy', overwrite: true

  input:
  // Stage the FASTQ path emitted by reads_ch into this task's work directory.
  path reads

  output:
  // The process is successful only if this file exists. Name its output
  // channel "metrics" so downstream code can refer to it clearly.
  path 'read_qc.tsv', emit: metrics

  script:
  """
  # FASTQ sequence lines are records 2, 6, 10, ... (NR modulo 4 equals 2).
  awk '
    BEGIN { reads = 0; bases = 0; min = 0; max = 0 }
    NR % 4 == 2 {
      length_now = length(\$0)
      reads += 1
      bases += length_now
      if (min == 0 || length_now < min) min = length_now
      if (length_now > max) max = length_now
    }
    END {
      if (reads == 0) exit 2
      printf "metric\\tvalue\\n"
      printf "reads\\t%d\\n", reads
      printf "bases\\t%d\\n", bases
      printf "mean_length\\t%.1f\\n", bases / reads
      printf "min_length\\t%d\\n", min
      printf "max_length\\t%d\\n", max
    }
  ' ${reads} > read_qc.tsv
  """
}

process QUALITY_GATE {
  publishDir params.outdir, mode: 'copy', overwrite: true

  input:
  // Receive read_qc.tsv from SUMMARIZE_READS.out.metrics.
  path metrics

  output:
  // Expose the gate decision on a named channel for future downstream work.
  path 'quality_gate.tsv', emit: decision

  script:
  """
  # Read the value whose first column is "reads" from the metrics TSV.
  observed=\$(awk -F '\t' '\$1 == "reads" { print \$2 }' ${metrics})

  # A failed QC rule must return a non-zero status so Nextflow stops.
  if [ "\${observed}" -lt "${params.min_reads}" ]; then
    printf 'QC failed: expected at least %s reads, observed %s.\n' \
      '${params.min_reads}' "\${observed}" >&2
    exit 1
  fi

  printf 'metric\tvalue\nstatus\tPASS\nreads\t%s\nminimum_reads\t%s\n' \
    "\${observed}" '${params.min_reads}' > quality_gate.tsv
  """
}

workflow {
  // Fail before scheduling work when the required --reads parameter is absent.
  if (!params.reads) {
    error 'Provide --reads with a FASTQ file.'
  }

  // A channel is a data stream. This one emits the matching FASTQ path once.
  reads_ch = channel.fromPath(params.reads, checkIfExists: true)

  // Feed the FASTQ path to the producer, then feed its named metrics output
  // to the quality gate. The file dependency determines execution order.
  SUMMARIZE_READS(reads_ch)
  QUALITY_GATE(SUMMARIZE_READS.out.metrics)
}
