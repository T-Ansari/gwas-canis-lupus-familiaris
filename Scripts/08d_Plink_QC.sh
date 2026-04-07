#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64g
#SBATCH --time=01:00:00
#SBATCH --job-name=plink_qc
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err

set -euo pipefail

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

# Defining file locations
IMPFILE=../plink/canis_imputed
OUTDIR=../plink
mkdir -p "$OUTDIR"

# Check Plink files exist
for ext in .bed .bim .fam; do
    if [[ ! -f "${IMPFILE}${ext}" ]]; then
        echo "Error: ${IMPFILE}${ext} not found. Run imputation step first or if imputation was skipped, change IMPFILE to point to your PLINK files." >&2
        exit 1
    fi
done

# Perform PLINK QC filtering
# Removes variants with >30% missing data, individuals with >60% missing data
# Removes variants with MAF <0.05
plink --bfile "$IMPFILE" \
 --allow-extra-chr \
 --geno 0.3 \
 --mind 0.6 \
 --maf 0.05 \
 --make-bed \
 --out $OUTDIR/canis_qc

# Deactivate conda environment
conda deactivate