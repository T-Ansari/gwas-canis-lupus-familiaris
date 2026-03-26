#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=32g
#SBATCH --time=01:00:00
#SBATCH --job-name=variant_concat
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

bcftools concat --file-list vcf.list.txt -Oz --output ../vcf/canis.vcf.gz --threads "$SLURM_CPUS_PER_TASK"
bcftools index ../vcf/canis.vcf.gz --threads "$SLURM_CPUS_PER_TASK"

# Deactivate conda environment
conda deactivate