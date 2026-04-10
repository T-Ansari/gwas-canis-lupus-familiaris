#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64g
#SBATCH --time=01:00:00
#SBATCH --job-name=plink_prep
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err

set -euo pipefail

####################################################################
#                                                                  #
#        Script: PLINK Preparation Script                          #
#                                                                  #
#        Author: Tahir Ansari                                      #
#        Date:  25 March 2026                                      #
#                                                                  #
#        Description: Converts filtered VCF to PLINK binary        #
#              format (.bed/.bim/.fam) and generates               #
#              missingness statistics for QC thresholds.           #
#                                                                  #
####################################################################

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

# Defining file locations
VCF=../vcf/canis_raw_filtered.vcf.gz
OUTDIR=../plink
mkdir -p "$OUTDIR"

# Check if input VCF exists
if [[ ! -f "$VCF" ]]; then
    echo "Error: $VCF not found. Run previous steps first." >&2
    exit 1
fi

# Convert VCF to PLINK bed,bim, fam format
plink --vcf "$VCF" \
 --double-id \
 --allow-extra-chr \
 --make-bed \
 --out "$OUTDIR/canis_raw" \

# Check for missing data
plink --bfile "$OUTDIR/canis_raw" \
 --missing \
 --allow-extra-chr \
 --out "$OUTDIR/canis_missing"

# Deactivate conda environment
conda deactivate