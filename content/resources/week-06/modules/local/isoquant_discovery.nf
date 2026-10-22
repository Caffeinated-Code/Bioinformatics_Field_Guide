process ISOQUANT_DISCOVERY {
  // Show the sample ID beside this task in the Nextflow log.
  tag "${meta.id}"

  // Apply the high-resource CPU, memory, and time settings from nextflow.config.
  label 'process_high'

  // Copy final deliverables from Nextflow's work directory into the results folder.
  publishDir "${params.outdir}/isoquant", mode: 'copy'

  // Use the container with Docker/Singularity profiles or Conda with the Conda profile.
  container 'biofield/ont-isoforms:2026.10'
  conda 'bioconda::isoquant=4.0.0'

  // Declare every file and metadata object required by one task.
  input:
  tuple val(meta), path(bam), path(bai)
  path reference
  path annotation

  // Name the transcript-model GTF for SQANTI3 and retain the complete IsoQuant folder.
  output:
  tuple val(meta), path("${meta.id}.transcript_models.gtf"), emit: models
  tuple val(meta), path("${meta.id}.isoquant"), emit: results

  script:
  """
  # Stop on an error, an unset variable, or a failed command inside a pipe.
  set -euo pipefail

  # Reconstruct and quantify ONT transcript models against the supplied annotation.
  isoquant --data_type nanopore --bam ${bam} --reference ${reference} \
    --genedb ${annotation} --complete_genedb \
    --threads ${task.cpus} --prefix ${meta.id} --output ${meta.id}.isoquant

  # Find the model GTF produced inside IsoQuant's version-specific output tree.
  model_gtf=\$(find ${meta.id}.isoquant -type f -name '*transcript_models.gtf' -print -quit)

  # Fail the task if IsoQuant completed without creating the expected GTF.
  test -n "\${model_gtf}"

  # Give the GTF a stable name for the next Nextflow process.
  cp "\${model_gtf}" ${meta.id}.transcript_models.gtf
  """
}
