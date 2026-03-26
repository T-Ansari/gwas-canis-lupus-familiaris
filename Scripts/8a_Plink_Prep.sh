#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64g
#SBATCH --time=01:00:00
#SBATCH --job-name=plink_prep
#SBATCH --output=Logs/slurm-%x-%j.out
#SBATCH --error=Logs/slurm-%x-%j.err

# Load Conda Environment
source $HOME/.bash_profile
conda activate CanisGWAS

# Defining Output location
OUTDIR=../plink
mkdir -p $OUTDIR

# Convert VCF to PLINK bed,bim, fam format 
plink --vcf ../vcf/canis_raw_filtered.vcf.gz \
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