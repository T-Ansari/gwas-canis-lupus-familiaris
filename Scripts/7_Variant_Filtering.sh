#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=64g
#SBATCH --time=01:00:00
#SBATCH --job-name=variant_filter
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err

set -euo pipefail

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

# Setting location of input and output files
CONCATVCF=../vcf/canis.vcf.gz
LOGFILE=../vcf/variant_filtering.log
echo "-- Variant Filtering Log --" > "$LOGFILE"

# Validate input
if [[ ! -f "$CONCATVCF" ]]; then
    echo "Error: $CONCATVCF not found. Run previous steps first." >&2
    exit 1
fi
echo "Filtering VCF file: $CONCATVCF" >> "$LOGFILE"

#Create txt of number of vcfs after filtering
RAW_COUNT=$(bcftools view -H "$CONCATVCF" --threads "$SLURM_CPUS_PER_TASK" | wc -l)

#Filter the vcf files to Qual>30 and DP>10, then filter to biallelic SNPs
bcftools filter -e 'QUAL<30 || INFO/DP<10' "$CONCATVCF" --threads "$SLURM_CPUS_PER_TASK" \
  | bcftools view -m2 -M2 -v snps --threads "$SLURM_CPUS_PER_TASK" -Oz -o ../vcf/canis_raw_filtered.vcf.gz
echo "Filtering for Quality, Depth and biallelic sites complete" >> "$LOGFILE"

#Index filtered vcf
bcftools index ../vcf/canis_raw_filtered.vcf.gz --threads "$SLURM_CPUS_PER_TASK"
echo "Indexing of filtered VCF complete" >> "$LOGFILE"

#Create txt of number of SNPs after filtering
FINAL_COUNT=$(bcftools view -H ../vcf/canis_raw_filtered.vcf.gz --threads "$SLURM_CPUS_PER_TASK" | wc -l)

# Creating Statitics in Log file
echo "" >> "$LOGFILE"
echo "--- Statistics ---" >> "$LOGFILE"
echo "Initial number of variants: $RAW_COUNT" >> "$LOGFILE"
echo "Variants after raw filtering: $FINAL_COUNT" >> "$LOGFILE"
echo >> "$LOGFILE"

# Deactivate conda environment
conda deactivate