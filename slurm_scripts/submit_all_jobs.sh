#!/bin/bash

# Helper script to submit qsub jobs equivalent to the Snakemake workflow
# This mirrors the batch ranges defined in the Snakemake rule all:
# - create_small_files: batch=range(1,11) -> batches 1-10
# - create_large_file: large_batch=range(1,2) -> batch 1

echo "Submitting qsub jobs equivalent to Snakemake workflow..."
echo "=========================================="

# Submit create_small_files jobs for batches 1-10
echo "Submitting create_small_files jobs (batches 1-10):"
for batch in $(seq 1 10); do
    job_id=$(sbatch slurm_scripts/create_small_files.qsub $batch | awk '{print $4}')
    echo "  Batch $batch: Job ID $job_id"
done

echo ""

# Submit create_large_file job for batch 1
echo "Submitting create_large_file job (batch 1):"
job_id=$(sbatch slurm_scripts/create_large_file.qsub 1 | awk '{print $4}')
echo "  Batch 1: Job ID $job_id"

echo ""
echo "All jobs submitted!"
echo "Monitor with: squeue -u $USER"
echo "Check results in: results/"