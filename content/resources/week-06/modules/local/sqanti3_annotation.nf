process SQANTI3_ANNOTATION {
  tag "${meta.id}"
  label 'process_high'

  publishDir "${params.outdir}/sqanti3", mode: 'copy'

  container 'biofield/ont-isoforms:2026.10'
  conda 'bioconda::sqanti3=6.0.2'

  input:
  tuple val(meta), path(isoforms_gtf)
  path annotation_gtf
  path genome_fasta

  output:
  tuple val(meta), path("${meta.id}.sqanti3"), emit: results

  script:
  def prepare_gtf = annotation_gtf.name.endsWith('.gz') \
    ? "gzip -dc ${annotation_gtf} > sqanti_reference.gtf" \
    : "cp ${annotation_gtf} sqanti_reference.gtf"
  def prepare_fasta = genome_fasta.name.endsWith('.gz') \
    ? "gzip -dc ${genome_fasta} > sqanti_reference.fa" \
    : "cp ${genome_fasta} sqanti_reference.fa"
  """
  set -euo pipefail
  scratch=/tmp/sqanti3_${meta.id}
  rm -rf "\${scratch}"
  mkdir -p "\${scratch}"
  cp ${isoforms_gtf} "\${scratch}/isoforms.gtf"
  ${prepare_gtf.replace('sqanti_reference.gtf', '"${scratch}/reference.gtf"')}
  ${prepare_fasta.replace('sqanti_reference.fa', '"${scratch}/reference.fa"')}
  cd "\${scratch}"
  sqanti3_qc.py \
    --isoforms isoforms.gtf \
    --refGTF reference.gtf \
    --refFasta reference.fa \
    --dir output \
    --output ${meta.id} \
    --chunks ${task.cpus}
  cp -R output "\${OLDPWD}/${meta.id}.sqanti3"
  """

  stub:
  """
  mkdir -p ${meta.id}.sqanti3
  printf 'isoform\tstructural_category\nTX1\tfull-splice_match\n' > ${meta.id}.sqanti3/${meta.id}_classification.txt
  """
}
