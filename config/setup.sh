#!/bin/sh
conda create -p ./conda-env -c conda-forge -c bioconda -y snakemake mamba coincbc python apptainer snakemake-executor-plugin-slurm
