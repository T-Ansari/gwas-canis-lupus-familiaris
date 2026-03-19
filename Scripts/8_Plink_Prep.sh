#!/bin/bash
#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64g
#SBATCH --time=01:00:00
#SBATCH --job-name=plink_prep
#SBATCH --output=Logs/plink_prep.out
#SBATCH --error=Logs/plink_prep.err

# Load Conda Environment
#source $HOME/.bash_profile
#conda activate CanisGWAS
module load plink-uoneasy/2.00a3.7-foss-2023a

# Defining Output location
OUTDIR=../plink
mkdir -p $OUTDIR

# Convert VCF to PLINK bed,bim, fam format 
plink --vcf ../vcf/dog_raw_filtered.vcf.gz \
 --double-id \
 --allow-extra-chr \
 --make-bed \
 --out "$OUTDIR/dog_raw" \

# Check for missing data
plink --bfile "$OUTDIR/dog_raw" \
 --missing \
 --allow-extra-chr \
 --out "$OUTDIR/dog_missing"
