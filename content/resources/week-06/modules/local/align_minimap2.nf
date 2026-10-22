process ALIGN_MINIMAP2 {
  tag "${meta.id}"
  label 'process_high'

  publishDir "${params.outdir}/alignments", mode: 'copy'

  container 'biofield/ont-isoforms:2026.10'
  conda 'bioconda::minimap2=2.28 bioconda::samtools=1.21'

  input:
  tuple val(meta), path(fastq)
  path reference

  output:
  tuple val(meta), path("${meta.id}.sorted.bam"), path("${meta.id}.sorted.bam.bai"), emit: bam

  script:
  def extra = meta.protocol == 'directRNA' ? '-uf -k14' : ''
  """
  set -euo pipefail
  minimap2 -ax splice ${extra} -t ${task.cpus} ${reference} ${fastq} \
    | samtools sort -@ ${task.cpus} -o ${meta.id}.sorted.bam -
  samtools index -@ ${task.cpus} ${meta.id}.sorted.bam
  """
}
