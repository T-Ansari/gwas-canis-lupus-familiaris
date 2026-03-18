#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=64g
#SBATCH --time=01:00:00
#SBATCH --job-name=variant_filter
#SBATCH --output=variant_filter.out
#SBATCH --error=variant_filter.err

# Load Conda Environment
#source $HOME/.bash_profile
#conda activate CanisGWAS
module load bcftools-uoneasy/1.18-GCC-13.2.0

CONCATVCF=../vcf/dog.vcf.gz

bcftools view -H "$CONCATVCF" --threads "$SLURM_CPUS_PER_TASK" | wc -l > ../vcf/merged.vcf.stats.txt

bcftools filter -e 'QUAL<30 || DP<10' "$CONCATVCF" -Oz -o ../vcf/dog_filtered.vcf.gz --threads "$SLURM_CPUS_PER_TASK"

bcftools view -H  ../vcf/dog_filtered.vcf.gz --threads "$SLURM_CPUS_PER_TASK" | wc -l > ../vcf/filtered.vcf.stats.txt

bcftools view -m2 -M2 -v snps ../vcf/dog_filtered.vcf.gz -Oz -o dog_clean.vcf.gz --threads "$SLURM_CPUS_PER_TASK"

