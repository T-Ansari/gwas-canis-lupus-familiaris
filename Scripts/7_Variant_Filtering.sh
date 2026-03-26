#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=64g
#SBATCH --time=01:00:00
#SBATCH --job-name=variant_filter
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

CONCATVCF=../vcf/canis.vcf.gz
LOGFILE=../vcf/variant_filtering.log
echo "-- Variant Filtering Log --" > "$LOGFILE"
echo "Filtering VCF file: $CONCATVCF" >> "$LOGFILE"

#Create txt of number of vcfs after filtering
RAW_COUNT=$(bcftools view -H "$CONCATVCF" --threads "$SLURM_CPUS_PER_TASK" | wc -l)

#Filter the vcf files to Qual>30 and DP>10
bcftools filter -e 'QUAL<30 || INFO/DP<10' "$CONCATVCF" -Oz -o ../vcf/canis_filtered_1.vcf.gz --threads "$SLURM_CPUS_PER_TASK"
echo "Filtering for Quality and Depth complete" >> "$LOGFILE"

#Filters to only biallelic SNPs and only variant SNPs
bcftools view -m2 -M2 -v snps ../vcf/canis_filtered_1.vcf.gz -Oz -o ../vcf/canis_raw_filtered.vcf.gz --threads "$SLURM_CPUS_PER_TASK"
echo "Filtering for biallelic sites complete" >> "$LOGFILE"

#Index filtered vcf
bcftools index ../vcf/canis_raw_filtered.vcf.gz --threads "$SLURM_CPUS_PER_TASK"
echo "Indexing of filtered VCF complete" >> "$LOGFILE"

#Create txt of number of SNPs after filtering
FINAL_COUNT=$(bcftools view -H  ../vcf/canis_raw_filtered.vcf.gz --threads "$SLURM_CPUS_PER_TASK" | wc -l)

# Removing extra files
rm ../vcf/canis_filtered_1.vcf.gz
echo "Temporary filtered VCF removed" >> "$LOGFILE"

# Creating Statitics in Log file
echo "" >> "$LOGFILE"
echo "--- Statistics ---" >> "$LOGFILE"
echo "Initial number of variants: $RAW_COUNT" >> "$LOGFILE"
echo "Variants after raw filtering: $FINAL_COUNT" >> "$LOGFILE"
echo >> "$LOGFILE"

# Deactivate conda environment
conda deactivate