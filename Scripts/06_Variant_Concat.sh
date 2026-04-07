#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=32g
#SBATCH --time=01:00:00
#SBATCH --job-name=variant_concat
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err

set -euo pipefail

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

# Check if vcf.list.txt exists
if [[ ! -f vcf.list.txt ]]; then
    echo "vcf.list.txt not found. Please create it with: ls ../vcf/*.vcf.gz > vcf.list.txt" &>2
    exit 1
fi

# Running Concat
bcftools concat --file-list vcf.list.txt -Oz --output ../vcf/canis.vcf.gz --threads "$SLURM_CPUS_PER_TASK"
bcftools index ../vcf/canis.vcf.gz --threads "$SLURM_CPUS_PER_TASK"

# Deactivate conda environment
conda deactivate