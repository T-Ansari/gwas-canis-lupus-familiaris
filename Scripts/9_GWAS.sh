#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64g
#SBATCH --time=01:00:00
#SBATCH --job-name=ld_prune
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

# Defining Output locations
PRUNEDIR=../prune
GWASDIR=../gwas
mkdir -p $PRUNEDIR
mkdir -p $GWASDIR

# Perform initial PLINK GWAS
plink --bfile ../plink/canis_qc \
 --allow-extra-chr \
 --allow-no-sex \
 --pheno canis_phenotypes.txt \
 --linear \
 --out $GWASDIR/gwas_canis_uncorrected

# Perform PLINK Prune for LD pruning
plink --bfile ../plink/canis_qc \
 --allow-extra-chr \
 --indep-pairwise 50 5 0.2 \
 --out $PRUNEDIR/prune

# Perform PLINK PCA to get top 20 PCs
plink --bfile ../plink/canis_qc \
 --allow-extra-chr \
 --extract $PRUNEDIR/prune.prune.in \
 --pca 20 \
 --out $PRUNEDIR/pca20

# Perform GWAS Again with PCA covariates
# Remove --linear if measuring qualitative traits and add --logistic
plink --bfile ../plink/canis_qc \
 --allow-extra-chr \
 --allow-no-sex \
 --pheno canis_phenotypes.txt \
 --covar $PRUNEDIR/pca20.eigenvec \
 --covar-number 1-3 \
 --linear \
 --out $GWASDIR/gwas_canis_pca3

# Deactivate conda environment
conda deactivate