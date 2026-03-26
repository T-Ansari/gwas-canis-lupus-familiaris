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

plink --bfile fish_raw \
 --allow-extra-chr \
 --geno 0.3 \
 --mind 0.6 \
 --maf 0.5 \
 --make-bed \
 --out $OUTDIR/fish_qc

# Deactivate conda environment
conda deactivate