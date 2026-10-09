#!/usr/bin/env bash
set -euo pipefail

# Lightweight public ONT RNA demo using one SG-NEx public FASTQ.
# The script streams a prefix of the public FASTQ and writes a small local subset.
# Increase READS only after checking disk space and runtime.

READS="${1:-10000}"
OUTDIR="${2:-data/sgnex_demo}"
MANIFEST="${3:-content/resources/week-06/sgnex_ont_demo_samples.tsv}"

mkdir -p "${OUTDIR}"

FASTQ_URL="$(awk 'NR == 2 { print $5 }' "${MANIFEST}")"
SAMPLE="$(awk 'NR == 2 { print $1 }' "${MANIFEST}")"
OUT_FASTQ="${OUTDIR}/${SAMPLE}.${READS}_reads.fastq.gz"

echo "Sample: ${SAMPLE}"
echo "Reads: ${READS}"
echo "Source: ${FASTQ_URL}"
echo "Output: ${OUT_FASTQ}"

# FASTQ records are four lines each, so READS * 4 lines are kept.
# Python avoids noisy broken-pipe messages when stopping early in a remote gzip stream.
python3 - "${FASTQ_URL}" "${OUT_FASTQ}" "${READS}" <<'PY'
import gzip
import sys
import urllib.request

url, out_fastq, reads = sys.argv[1], sys.argv[2], int(sys.argv[3])
max_lines = reads * 4

request = urllib.request.Request(url, headers={"User-Agent": "Bioinformatics_Field_Guide-Week6"})
with urllib.request.urlopen(request) as response:
    with gzip.GzipFile(fileobj=response) as source:
        with gzip.open(out_fastq, "wt") as out:
            for i, line in enumerate(source, start=1):
                if i > max_lines:
                    break
                out.write(line.decode("utf-8"))
PY

echo
echo "Basic file checks"
ls -lh "${OUT_FASTQ}"
gzip -t "${OUT_FASTQ}"
gzip -dc "${OUT_FASTQ}" | awk 'END { print "FASTQ lines:", NR, "reads:", NR / 4 }'

echo
echo "Optional NanoPlot command, if NanoPlot is installed:"
echo "NanoPlot --fastq ${OUT_FASTQ} --outdir ${OUTDIR}/nanoplot --prefix ${SAMPLE}_"
