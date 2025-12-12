#!/bin/sh
conda create -p ./conda-env -c conda-forge -c bioconda -y snakemake=9.13.7 mamba coincbc python apptainer snakemake-executor-plugin-slurm snakemake-executor-plugin-cluster-generic
