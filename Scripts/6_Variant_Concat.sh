#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=32g
#SBATCH --time=01:00:00
#SBATCH --job-name=variant_concat
#SBATCH --output=index_ref.out
#SBATCH --error=index_ref.err

# Load Conda Environment
#source $HOME/.bash_profile
#conda activate CanisGWAS
module load bcftools-uoneasy/1.18-GCC-13.2.0

bcftools concat --file-list vcf.list.txt -Oz --output ../vcf/dog.vcf.gz --threads "$SLURM_CPUS_PER_TASK"
bcftools index ../vcf/dog.vcf.gz --threads "$SLURM_CPUS_PER_TASK"
