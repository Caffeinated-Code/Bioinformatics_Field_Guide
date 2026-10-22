#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { FASTQ_QC } from './modules/local/fastq_qc'
include { ALIGN_MINIMAP2 } from './modules/local/align_minimap2'
include { ALIGNMENT_QC } from './modules/local/alignment_qc'
include { ISOQUANT_DISCOVERY } from './modules/local/isoquant_discovery'
include { SQANTI3_ANNOTATION } from './modules/local/sqanti3_annotation'

workflow {
  if (params.help) {
    log.info """
    Reproducible ONT isoform-discovery pipeline

    Required:
      --input       CSV with columns: sample,fastq,protocol,condition
      --reference   genome FASTA for minimap2

    Optional:
      --annotation  matching GTF annotation
      --outdir      output directory

    Protocol values: directRNA, directcDNA, pcr-cDNA

    Example:
      nextflow run main.nf -profile docker -params-file params.local.yml -resume
    """
    return
  }

  if (!params.input || !params.reference || !params.annotation) {
    error "Provide --input, --reference, and --annotation. FASTA and GTF must use the same genome build."
  }

  def samplesheet = file(params.input, checkIfExists: true)
  def samplesheet_dir = samplesheet.parent

  Channel
    .fromPath(samplesheet)
    .splitCsv(header: true)
    .map { row ->
      if (!(row.protocol in ['directRNA', 'directcDNA', 'pcr-cDNA'])) {
        error "Unsupported protocol '${row.protocol}' for sample '${row.sample}'."
      }

      def fastq = file(row.fastq)
      if (!fastq.exists()) {
        fastq = samplesheet_dir.resolve(row.fastq)
      }

      tuple(
        [ id: row.sample, protocol: row.protocol, condition: row.condition ],
        file(fastq, checkIfExists: true)
      )
    }
    .set { ch_reads }

  ch_reference = Channel.value(file(params.reference, checkIfExists: true))
  ch_annotation = Channel.value(file(params.annotation, checkIfExists: true))

  FASTQ_QC(ch_reads)

  ALIGN_MINIMAP2(ch_reads, ch_reference)
  ALIGNMENT_QC(ALIGN_MINIMAP2.out.bam)
  ISOQUANT_DISCOVERY(ALIGN_MINIMAP2.out.bam, ch_reference, ch_annotation)
  SQANTI3_ANNOTATION(ISOQUANT_DISCOVERY.out.models, ch_annotation, ch_reference)
}
