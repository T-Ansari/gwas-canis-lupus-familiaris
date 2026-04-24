#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64g
#SBATCH --time=10:00:00
#SBATCH --job-name=vcf_call
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err


####################################################################
#                                                                  #
#        Script: Variant Calling Script                            #
#                                                                  #
#        Author: Tahir Ansari                                      #
#        Date:  25 March 2026                                      #
#                                                                  #
#        Description: Calls variants per chromosome using          #
#              bcftools mpileup and bcftools call                  #
#                                                                  #
####################################################################

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS
set -euo pipefail

# Setting file locations
REF=../reference/canis_reference.fna
VCFDIR=../vcf
BAMLIST=filtered_bams.txt

mkdir -p "$VCFDIR"

# Validate input files
if [[ ! -f "$REF" ]]; then
    echo "Error: $REF not found. Run previous steps first or ensure it exists." >&2
    exit 1
fi

if [[ ! -f "$BAMLIST" ]]; then
    echo "Error: $BAMLIST not found. Generate it with: ls ../filtered_bam/*.bam > filtered_bams.txt" >&2
    exit 1
fi

# Load Chromosome names into an array if exists
if [[ -f canis_chr_names.txt ]]; then
    mapfile -t CHRS < canis_chr_names.txt
else
    echo "canis_chr_names.txt not found. Please create a list of chromosome names." &>2
    exit 1
fi
CHR=${CHRS[$SLURM_ARRAY_TASK_ID]}

# Output file
OUTFILE="$VCFDIR/canis.${CHR}.vcf.gz"

# Running mpileup and variant calling
# --min-MQ 30 and --min-BQ 30 as standard thresholds.
bcftools mpileup \
 --threads "$SLURM_CPUS_PER_TASK" \
 -Ou \
 -f "$REF" \
 --min-MQ 30 \
 --min-BQ 30 \
 --annotate FORMAT/DP,FORMAT/AD \
 --bam-list "$BAMLIST" \
 -r "$CHR" | \
bcftools call \
 --threads "$SLURM_CPUS_PER_TASK" \
 -m \
 -v \
 -Oz \
 -o "$OUTFILE"

# Index VCF
bcftools index "$OUTFILE"

echo "Finished Variant Calling for $CHR"

# Deactivate conda environment
conda deactivate