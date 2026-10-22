#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

params.reads = null
params.min_reads = 3
params.outdir = 'results'

process SUMMARIZE_READS {
  tag reads.simpleName

  publishDir params.outdir, mode: 'copy', overwrite: true

  input:
  path reads

  output:
  path 'read_qc.tsv', emit: metrics

  script:
  """
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
  path metrics

  output:
  path 'quality_gate.tsv', emit: decision

  script:
  """
  observed=\$(awk -F '\t' '\$1 == "reads" { print \$2 }' ${metrics})

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
  if (!params.reads) {
    error 'Provide --reads with a FASTQ file.'
  }

  reads_ch = channel.fromPath(params.reads, checkIfExists: true)
  SUMMARIZE_READS(reads_ch)
  QUALITY_GATE(SUMMARIZE_READS.out.metrics)
}
