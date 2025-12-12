#!/bin/sh

#script to create the required files and directories for a snakemake version 9.3.5 project


#config files
mkdir -p ./config

#the setup.sh script
echo "#!/bin/sh
conda create -p ./conda-env -c conda-forge -c bioconda -y snakemake=9.13.7 mamba python apptainer snakemake-executor-plugin-slurm snakemake-executor-plugin-generic" > config/setup.sh

#the config.yaml file
echo "sample: one" > config/config.yaml


#the results directory
mkdir -p ./results


#the slurm directory
mkdir -p ./slurm
mkdir -p ./slurm/logs

#slurm config.yaml
echo "executor: slurm
jobs: 10
use-conda: True

default-resources:
  mem_mb: 20000
  runtime: 120
  slurm_partition: "PARTITION"
  slurm_account: "PROJECT"
  ntasks: 1

# Additional settings to control SLURM log behavior
slurm-logdir: "slurm/logs/"
slurm-keep-successful-logs: True
" > slurm/config.yaml

#the generic cluster profile
mkdir -p ./generic
mkdir -p ./generic/logs
#generic config.yaml
echo '# Executor: switch from slurm plugin to cluster-generic
executor: cluster-generic

# Concurrency (same as before)
jobs: 10

# Software environments (Snakemake 8 prefers software-deployment-method)
# Equivalent to old "use-conda: True"
software-deployment-method: conda

# Default resources (carried over from your SLURM profile)
default-resources:
  mem_mb: 20000                # memory for the whole job
  runtime: 120                 # minutes or HH:MM:SS depending on your cluster
  slurm_partition: PARITION     # keep the same resource key name
  slurm_account: ACCOUNT
  ntasks: 1

# Submit/status/cancel commands required by cluster-generic
# We pass your resources to sbatch and make output/err files similar to your log layout.
cluster-generic-submit-cmd: >-
  sbatch
  --account={resources.slurm_account}
  --partition={resources.slurm_partition}
  --time={resources.runtime}
  --cpus-per-task={threads}
  --mem={resources.mem_mb}
  --ntasks={resources.ntasks}
  --parsable
  --output=generic/logs/%j.out
  --error=generic/logs/%j.err

# Provide a status command (script shown below). If you prefer, you can
# point this to any script/binary that accepts a single jobid argument.
cluster-generic-status-cmd: "generic/status.py"

# Cancel is simply scancel in SLURM
cluster-generic-cancel-cmd: "scancel"

# Retries / reruns (unchanged)
restart-times: 3' > generic/config.yaml



#the workflow
mkdir -p workflow/envs
mkdir -p workflow/rules

#workflow/snakemake file
echo '###############################################################################
#About:
#
#
###############################################################################

configfile: "../config/config.yaml"

rule all:
    input: expand("../results/01_mapped_reads/A.sam")

rule bwa:
    input:
        "../example/genome.fasta",
	"../example/A.fastq"
    output:
        "../results/01_mapped_reads/A.sam"
    threads:
        4
    resources:
        mem_mb = 1024*100,
	runtime = 10
    shell:
        """
	    bwa mem -t {threads} {input[0]} {input{1}} > {output}
	"""
' > workflow/rules/01_snakemake.smk


#.gitignore
echo "conda-env > .gitignore"
echo ".snakemake >> .gitignore"
echo "./slurm/logs/* >> .gitignore"
