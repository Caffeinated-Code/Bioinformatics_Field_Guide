process ALIGNMENT_QC {
  tag "${meta.id}"
  label 'process_low'

  publishDir "${params.outdir}/alignment_qc", mode: 'copy'

  container 'biofield/ont-isoforms:2026.10'
  conda 'bioconda::samtools=1.21'

  input:
  tuple val(meta), path(bam), path(bai)

  output:
  tuple val(meta), path("${meta.id}.flagstat.txt"), path("${meta.id}.idxstats.txt"), emit: qc

  script:
  """
  samtools flagstat ${bam} > ${meta.id}.flagstat.txt
  samtools idxstats ${bam} > ${meta.id}.idxstats.txt
  """
}
