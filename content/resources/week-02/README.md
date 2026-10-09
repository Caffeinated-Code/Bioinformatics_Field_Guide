# Week 2 Resources: Programming Languages For Bioinformatics

These files support the Week 2 guide: "What Programming Languages Should a Bioinformatician Know?"

## Notebooks

| Tutorial | End goal | File |
|---|---|---|
| Bash | Build a tiny sequence and sample QC snapshot | `notebooks/01_bash_file_inspection.ipynb` |
| Python | Clean sample metadata and make a quick study-summary plot | `notebooks/02_python_metadata_cleanup.ipynb` |
| R | Make a simple expression plot for marker genes | `notebooks/03_r_expression_plot.ipynb` |
| SQL | Audit sample metadata and join gene annotations | `notebooks/04_sql_metadata_checks.ipynb` |

## Open In The Browser

| Tutorial | Browser link |
|---|---|
| Bash | https://colab.research.google.com/github/Caffeinated-Code/Bioinformatics_Field_Guide/blob/4c540efc6fdf3595849f4e84788099186f724dc4/content/resources/week-02/notebooks/01_bash_file_inspection.ipynb |
| Python | https://colab.research.google.com/github/Caffeinated-Code/Bioinformatics_Field_Guide/blob/main/content/resources/week-02/notebooks/02_python_metadata_cleanup.ipynb |
| R | https://colab.research.google.com/github/Caffeinated-Code/Bioinformatics_Field_Guide/blob/4c540efc6fdf3595849f4e84788099186f724dc4/content/resources/week-02/notebooks/03_r_expression_plot.ipynb |
| SQL | https://colab.research.google.com/github/Caffeinated-Code/Bioinformatics_Field_Guide/blob/main/content/resources/week-02/notebooks/04_sql_metadata_checks.ipynb |

The R notebook uses an R kernel. If a hosted notebook service does not start the R runtime cleanly, open it in Posit Cloud or in the local JupyterLab environment from Week 1.

## Data

| File | Purpose |
|---|---|
| `data/samples.tsv` | Small sample metadata table |
| `data/mini_transcripts.fasta` | Tiny FASTA file for Bash practice |
| `data/gene_counts.tsv` | Small gene count matrix |
| `data/gene_annotations.tsv` | Gene symbols and pathway labels |

Run these from JupyterLab using the Week 1 `bioinfo-starter` environment.
