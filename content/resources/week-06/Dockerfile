FROM condaforge/miniforge3:25.3.0-3

COPY environment.yml /tmp/environment.yml
RUN conda env create -f /tmp/environment.yml && conda clean --all --yes

ENV PATH="/opt/conda/envs/ont-isoforms/bin:${PATH}"
WORKDIR /work

RUN minimap2 --version && samtools --version | head -1 && isoquant --version && sqanti3_qc.py --version
