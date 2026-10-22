process FASTQ_QC {
  tag "${meta.id}"
  label 'process_low'

  publishDir "${params.outdir}/fastq_qc", mode: 'copy'

  container 'biofield/ont-isoforms:2026.10'
  conda 'bioconda::nanoplot=1.48.0'

  input:
  tuple val(meta), path(fastq)

  output:
  tuple val(meta), path("${meta.id}_nanoplot"), emit: report

  script:
  """
  NanoPlot \
    --fastq ${fastq} \
    --outdir ${meta.id}_nanoplot \
    --prefix ${meta.id}_
  """
}
