#!/usr/bin/env bash
set -euo pipefail
base_url="https://raw.githubusercontent.com/ablab/IsoQuant/v4.0.0/isoquant_lib/test_data"
data_dir="${1:-data/isoquant_toy}"
mkdir -p "${data_dir}"
for name in chr9.4M.ont.sim.fq.gz chr9.4M.fa.gz chr9.4M.gtf.gz; do
  curl --fail --location --retry 3 "${base_url}/${name}" --output "${data_dir}/${name}"
  gzip -t "${data_dir}/${name}"
done
cat > "${data_dir}/samplesheet.csv" <<EOF
sample,fastq,protocol,condition
ISOQUANT_TOY,${data_dir}/chr9.4M.ont.sim.fq.gz,directcDNA,toy
EOF
printf 'Prepared public IsoQuant ONT test data in %s\n' "${data_dir}"
printf 'FASTQ reads: %s\n' "$(gzip -dc "${data_dir}/chr9.4M.ont.sim.fq.gz" | awk 'END {print NR/4}')"
