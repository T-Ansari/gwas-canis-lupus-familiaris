#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64g
#SBATCH --time=01:00:00
#SBATCH --job-name=ld_prune
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err

set -euo pipefail

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

# Defining File locations
QCFILE="../plink/canis_qc"
PRUNEDIR=../prune
GWASDIR=../gwas
mkdir -p "$PRUNEDIR" "$GWASDIR"

# Ensure phenotype file exists
if [[ ! -f "canis_phenotypes.txt" ]]; then
    echo "Error: canis_phenotypes.txt not found. Please create a file as outlined in the README." >&2
    exit 1
fi

# Check Plink files exist
for ext in .bed .bim .fam; do
    if [[ ! -f "${QCFILE}${ext}" ]]; then
        echo "Error: ${QCFILE}${ext} not found. Run QC step before proceeding." >&2
        exit 1
    fi
done

# Perform initial PLINK GWAS
plink --bfile "$QCFILE" \
 --allow-extra-chr \
 --allow-no-sex \
 --pheno canis_phenotypes.txt \
 --linear \
 --out $GWASDIR/gwas_canis_uncorrected

# Perform PLINK Prune for LD pruning
plink --bfile "$QCFILE" \
 --allow-extra-chr \
 --indep-pairwise 50 5 0.2 \
 --out $PRUNEDIR/prune

# Perform PLINK PCA to get top 20 PCs
plink --bfile "$QCFILE" \
 --allow-extra-chr \
 --extract $PRUNEDIR/prune.prune.in \
 --pca 20 \
 --out $PRUNEDIR/pca20

# Perform GWAS Again with PCA covariates
# Remove --linear if measuring qualitative traits and add --logistic
plink --bfile "$QCFILE" \
 --allow-extra-chr \
 --allow-no-sex \
 --pheno canis_phenotypes.txt \
 --covar $PRUNEDIR/pca20.eigenvec \
 --covar-number 1-3 \
 --linear \
 --out $GWASDIR/gwas_canis_pca3

# Deactivate conda environment
conda deactivate