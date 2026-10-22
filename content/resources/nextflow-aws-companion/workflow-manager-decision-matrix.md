# Workflow Manager Decision Matrix

| Situation | Usually start with | Why |
|---|---|---|
| learning one command | Bash | fastest path to understand the tool itself |
| many samples, Python-friendly lab | Snakemake | file-based rules and Python syntax feel natural |
| nf-core pipeline exists | Nextflow | use the community-tested pipeline first |
| one workflow must run local, HPC, and cloud | Nextflow | profiles and executors separate logic from infrastructure |
| Broad/GATK/Terra environment | WDL + Cromwell | ecosystem alignment matters |
| standards-first portability | CWL | open workflow specification across engines |

Rule of thumb: choose the workflow manager your collaborators can maintain after the exciting first demo is over.
