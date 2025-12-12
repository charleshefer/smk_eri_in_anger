# Snakemake eRI  Testing Workflow

## Issue

I am having a hard time getting Snakemake to reliably run jobs on the eRI. Sometimes jobs just never finish, and I cannot determine why. This repository contains a minimal Snakemake workflow to try and reproduce the issue. In short, the workflow creates multiple small files (10 directories with 10 files each) and a few large files (5 files of 1Gb in size each, using `dd`), to see if the cluster can handle the load without jobs hanging until they time out.

Update: I just discovered that specifying the interactive partition, the jobs just complete with no issues.

## Overview

This repository contains a Snakemake workflow designed to test the eRI. The workflow creates two types of computational jobs to evaluate cluster performance:

1. **Small File Creation Jobs**: Create multiple small text files (10 files)
2. **Large File Creation Jobs**: Generate 1GB files using `dd` (5 files)

## Repository Structure

```
smk_eri_in_anger/
├── workflow/
│   ├── rules/
│   │   └── 01_snakemake.smk      # Main Snakemake rules
│   └── bin/
│       └── count_logfiles.py     # Log analysis tool
├── config/
│   └── config.yaml               # Workflow configuration
├── slurm/
│   ├── config.yaml               # SLURM profile configuration
│   └── logs/                     # SLURM job logs (auto-generated)
├── generic/
│   ├── config.yaml               # SLURM profile configuration, for the generic slurm job executioner
│   └── logs/                     # SLURM job logs (auto-generated)
|   └── status.py                 # Custom script to check job status
├── slurm_scripts/                # Alternative qsub scripts
│   ├── create_small_files.qsub
│   ├── create_large_file.qsub
│   └── submit_all_jobs.sh
├── results/                      # Output files (auto-generated)
└── README.md                     # This file
```

## Choice of cluster-job-executioner

On 11/12/2025 the slurm applience was moved to a new hypervisor. Since this, the slurm job executioner that I have used for the past 2 years stopped working. I replaced this with the generic cluster executioner, and
added a custom script to check for job completion (generic/status.py). Now you have the options to use either of the two job executioners.

## Install

1. Clone the repository:

   ```bash
   git clone https://github.com/charleshefer/smk_eri_in_anger.git
   cd smk_eri_in_anger
   ```

2. Create the conda environment for snakemake to run in:

   ```bash
   sh config/setup.sh
   ```

3. Activate the conda environment:

   ```bash
   conda activate ./conda-env
   ```

4. Run snakemake using local rules only (will execute on the login node):

   ```bash
   snakemake -s workflow/rules/01_snakemake.smk --jobs 10
   ```

This will only run on the login node, for testing purposes. The jobs will finish in a couple of seconds, and the output files will be created in the `results/` directory. No errors should occur here. This will show that there are no syntax or logical errors in the workflow.

Remove the results directory before proceeding to the next step:

   ```bash
   rm -rf results/
   ```

5. Run snakemake using the SLURM profile to submit jobs to the cluster:

### Note, as of 11/12/2025 this is not working, see step 6. below.

The job will be submitted to the SLURM queue without an account specification, which means it will use your default account.

   ```bash
   snakemake -s workflow/rules/01_snakemake.smk --jobs 10 --profile slurm 
   ```

This will submit the jobs to the queue for execution on the cluster, submitting 10 jobs at a time. While this is running (it may complete quickly, or it may display the bug where one or more jobs just never finishes).

If a job fails, snakemake will retry it at least 2 more times.

You can monitor the log files in the `slurm/logs/` directory to see the status of each job.

An easy way to do this is to run:

   ```bash
   python workflow/bin/count_logfiles.py
   ```
6. Run snakemake using the generic profile to the cluster:

After unforeseen changes to the system, the method in 5. above does not work anymore. You need to run the pipeline using the generic slurm job executioner. Here is the code:

```bash
snakemake -s workflow/rules/01_snakemake.smk --jobs 10 --profile generic
```

You can continue with counting the logfiles as shown above in 5. 

This summarizes the number of log files present, gives some detail about what jobs (their jobids) were run more than once.

6. Rerun the analysis

To verify that it appears to be a random issue, where a random job just never finishes, you can rerun the snakemake command multiple times, but only after removing the results directory, and the slurm/logs directory.

   ```bash
   rm -rf results/ slurm/logs
   snakemake -s workflow/rules/01_snakemake.smk --jobs 10 --profile slurm 
   ```


7. My test results

I have ran this test multiple times, and I have observed that in some runs, all jobs complete successfully, while in others, one or more jobs hang indefinitely until they time out. This inconsistency makes it challenging to identify the root cause of the issue.

I have stored some of my test results in the `test_results/` directory, with timestamps indicating when each test was run. You can refer to these logs to see examples of both successful and failed runs.

Note: I made ample use of copilot to generate this README.md file, as well as add some debugging code to the rules in the Snakemake workflow.

