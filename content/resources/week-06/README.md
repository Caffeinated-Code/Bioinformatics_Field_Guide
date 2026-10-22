# Week 6: Reproducible ONT Isoform Pipeline

This is a complete DSL2 workflow from ONT FASTQ through read QC, splice-aware alignment, BAM QC, IsoQuant transcript discovery, and SQANTI3 structural classification.

## Pipeline Contract

| Process | Input | Output |
|---|---|---|
| `FASTQ_QC` | FASTQ | NanoPlot report directory |
| `ALIGN_MINIMAP2` | FASTQ + FASTA | coordinate-sorted BAM + BAI |
| `ALIGNMENT_QC` | BAM + BAI | flagstat + idxstats |
| `ISOQUANT_DISCOVERY` | BAM + FASTA + GTF | transcript-model GTF + complete IsoQuant directory |
| `SQANTI3_ANNOTATION` | model GTF + FASTA + GTF | SQANTI3 classification/QC directory |

The SQANTI3 process accepts plain or gzip-compressed reference inputs and creates task-local uncompressed copies when needed. It also uses a space-free temporary path to avoid SQANTI3 6.0.2's unquoted internal `gffread` path.

Pinned tools: minimap2 2.28, samtools 1.21, IsoQuant 4.0.0, SQANTI3 6.0.2, and NanoPlot 1.48.0.

## One-Command Test Data

```bash
bash content/resources/week-06/prepare_toy_test.sh
```

This downloads the public simulated ONT dataset distributed with IsoQuant v4.0.0 and checks every gzip file.

## Fast CI Test

Every process includes a lightweight `stub` that creates the same output names as the real tool. The stub test checks the complete five-process dataflow without downloading containers or running bioinformatics software.

```bash
# Run from this directory after installing Nextflow, Java 17, and nf-test 0.9.3.
mkdir -p .test-results
nf-test test tests/pipeline.nf.test \
  --ci \
  --junitxml .test-results/nf-test.xml
```

A passing stub test proves that channels, metadata, process dependencies, and output contracts still connect. It does not validate alignments or transcript discovery. Use the public IsoQuant dataset below for real integration and scientific checks.

## Run

```bash
# Build the pinned analysis image once.
bash content/resources/week-06/build_container.sh

nextflow run content/resources/week-06/main.nf \
  --input data/isoquant_toy/samplesheet.csv \
  --reference data/isoquant_toy/chr9.4M.fa.gz \
  --annotation data/isoquant_toy/chr9.4M.gtf.gz \
  --outdir results/week06-toy \
  -profile docker \
  -resume
```

On Apple Silicon, use Docker Desktop or start Colima with `colima start --cpu 4 --memory 8`. IsoQuant 4.0.0's Bioconda dependencies do not currently solve natively on `osx-arm64`; the Conda profile is intended for compatible Linux/x86 systems.

The tested image is 3.16 GB. Keep at least 10 GB free inside the Docker VM while building and unpacking it. Check with `docker system df` and `colima list`. If an existing Colima disk is too small, increase it with `colima stop` followed by `colima start --cpu 4 --memory 8 --disk 40`.

## Success Criteria

Do not judge success from exit code alone. Confirm:

```bash
test -s results/week06-toy/alignments/ISOQUANT_TOY.sorted.bam
test -s results/week06-toy/alignments/ISOQUANT_TOY.sorted.bam.bai
find results/week06-toy/isoquant -name '*.transcript_models.gtf' -size +0
find results/week06-toy/sqanti3 -name '*classification.txt' -size +0
```

The verified public toy run produced 439 primary alignments, 30 IsoQuant transcript models, and 30 SQANTI3 classification rows. Its 100% mapping rate reflects simulated data, not typical biological ONT performance.

## Production Notes

- Replace the toy files with a samplesheet, FASTA, and GTF from the same assembly release.
- Direct RNA is handled as forward stranded; verify this assumption for your basecalling and library workflow.
- This tutorial discovers models per sample. For cross-sample inference, construct a validated shared catalog and quantify every sample against it; do not treat independently discovered GTFs as automatically comparable.
- Add external junction, CAGE, poly(A), and ORF evidence before strong novelty claims.
- Benchmark discovery settings on truth sets or well-characterized controls before production use.
